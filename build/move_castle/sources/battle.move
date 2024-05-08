module move_castle::battle {

    use sui::clock::{Self, Clock}; // adds the clock module and struct for time based functionality
    use sui::math; // adds the math module 
    use sui::event;  // adds the event module 
    use move_castle::castle::Castle; // adds the castle module
    use move_castle::core::{Self, GameStore}; // adds the GameStore
    
    /// One or both sides of the battle are in battle cooldown
    const EBattleCooldown: u64 = 0; // error to represent the battle cooldown has been breached

    const BATTLE_WINNER_COOLDOWN_MS : u64 = 30 * 1000; // 30 sec // constant that represents the battle cooldown for the winner
    const BATTLE_LOSER_ECONOMIC_PENALTY_TIME : u64 = 2 * 60 * 1000; // 2 min // constant that represents the loser's econ penalty
    const BATTLE_LOSER_COOLDOWN_MS : u64 = 2 * 60 * 1000; // 2 min // constant that represents the loser cooldown

    /// Battle event
    public struct CastleBattleLog has store, copy, drop { // event to log the result of the battle
        attacker: ID, // id of the attacker castle
        winner: ID, // id of the winner castle
        loser: ID, // id of the losing castle
        winner_soldiers_lost: u64, // amount of soldiers lost (winner)
        loser_soldiers_lost: u64, // amount of soldiers lost (loser)
        reparation_economic_power: u64,  // this tells us what value of economic buff and debuff will be applied
        battle_time: u64, // time the battle took place
        reparation_end_time: u64  // time the buff/debuff will expire
    }

    entry fun battle(castle: &mut Castle, clock: &Clock, game_store: &mut GameStore, ctx: &mut TxContext) {

        /*
        This function simulates a castle battle. It's way too long

        castle: &mut Castle ->  a mutable reference to the Castle object
        clock: &Clock ->  reference to the Sui clock object
        game_store: &mut GameStore ->  mutable reference to the GameStore
        ctx: &mut TxContext -> a mutable reference to the TxContext object
         
        */

        // 1. random out a target
        let attacker_id = object::id(castle); // gets the ID of the attacker castle object
        let target_id = core::random_battle_target(attacker_id, game_store, ctx); 
        /*
            random_battle_target uses the attacker_id and the game_store to get a random
            castle object to battle. It returns a target_id. This function makes sure the 
            attacker cannot attack themselves
        */

        // 2. castle data
        let (attacker, defender) = core::fetch_castle_data(attacker_id, target_id, game_store); // gets castle data for attacker and defender

        // 3. check battle cooldown
        let current_timestamp = clock::timestamp_ms(clock); // gets current timestamp
        assert!(core::get_castle_battle_cooldown(&attacker) < current_timestamp, EBattleCooldown); // Checks that the attacker isn't on a battle cooldown
        assert!(core::get_castle_battle_cooldown(&defender) < current_timestamp, EBattleCooldown); // Checks that the defender isn't on a battle cooldown

        // 4. battle
        // 4.1 calculate total attack power and defense power
        let mut attack_power = core::get_castle_total_attack_power(&attacker); // gets the total attack power
        let mut defense_power = core::get_castle_total_defense_power(&defender); // gets the total defense power
        if (core::has_race_advantage(&attacker, &defender)) { // checks if the attacker has an advantage
            attack_power = math::divide_and_round_up(attack_power * 15, 10) // adds 50% to the attack power if there is a race advantage
        } else if (core::has_race_advantage(&defender, &attacker)) { // checks if the defender has an advantage
            defense_power = math::divide_and_round_up(defense_power * 15, 10) // adds 50% to the attack power if there is a race advantage
        };

        // 4.2 determine win lose
        let (mut winner, mut loser); // creates mutable variables
        if (attack_power > defense_power) { // sets the winner as the attacker (and defender as the loser) of the attackpower > defensepower
            winner = attacker;
            loser = defender;
        } else {
            winner = defender; // sets the winner as the defender (and attacker as the loser) of the attackpower > defensepower
            loser = attacker;
        };
        let winner_id = core::get_castle_id(&winner); // gets the castleId of the winner and sets it to winner_id
        let loser_id = core::get_castle_id(&loser); // gets the castleId of the loser and sets it to loser_id

        // 5. battle settlement   
        // 5.1 setting winner
        core::settle_castle_economy_inner(clock, &mut winner); // this function settles the castle ecomony of the winner
        /*
            I'm not sure the design choices below makes complete sense to me. 


            - winner_solders_total_defense_power = amount of soldiers * the defense power of a soldier
            - same thing for the loser

            Now this part doesn't make sense, why compare the winner's defense power with the loser's attack power, why not the other way around
            since that's how we determine a winner? It's almost that the attacker attacks with its defenders

            so if the winner defense power is more than the loser's attack power:
            - gets a single soldier defense power for the winner
            - calculates the soldiers left by = (total defense power of the winner - total attack power of a loser) / a single winning soldier's defense power

            if this is false "so if the winner defense power is more than the loser's attack power"
            - the winner has no soldiers left

            weeeeeeeird
        */


        let winner_solders_total_defense_power = core::get_castle_total_soldiers_defense_power(&winner); // defense power of the winner
        let loser_solders_total_attack_power = core::get_castle_total_soldiers_defense_power(&loser); // defense power of the loser
        let winner_soldiers_left; // creates an empty variable 
        if (winner_solders_total_defense_power > loser_solders_total_attack_power) { 
            let (_, winner_soldier_defense_power) = core::get_castle_soldier_attack_defense_power(core::get_castle_race(&winner)); // takes the winner's race and gets how much the defense power is of a single soldier
            winner_soldiers_left = math::divide_and_round_up(winner_solders_total_defense_power - loser_solders_total_attack_power, winner_soldier_defense_power);
        } else {
            winner_soldiers_left = 0;
        };
        let winner_soldiers_lost = core::get_castle_soldiers(&winner) - winner_soldiers_left;
        let winner_exp_gain = core::battle_winner_exp(&winner); // get exp for the win
        let reparation_economic_power = core::get_castle_economic_base_power(&loser); // get the loser's econ power to add a buff to the winner
        core::battle_settlement_save_castle_data(
            game_store, // game store state for the dynamic field update
            winner, // winner castle id
            true, // true means it's a win
            current_timestamp + BATTLE_WINNER_COOLDOWN_MS, // updates the cooldown
            reparation_economic_power, // updates the new econ power
            current_timestamp, // time battle took place
            current_timestamp + BATTLE_LOSER_ECONOMIC_PENALTY_TIME, // battle time + econ buff
            winner_soldiers_left, // updates winner soldiers left
            winner_exp_gain // xp gain for the win
        );

        // 5.2 settling loser
        core::settle_castle_economy_inner(clock, &mut loser); // settles the loser economy
        let loser_soldiers_left = 0; // sets soldiers left to zero 
        let loser_soldiers_lost = core::get_castle_soldiers(&loser) - loser_soldiers_left; // no reson to add loser_soldiers_left here since it'll always be zero
        core::battle_settlement_save_castle_data( // updates the data for the castle
            game_store, // game store state for the dynamic field update
            loser, // loser castle id
            false, // false means it's not a win
            current_timestamp + BATTLE_LOSER_COOLDOWN_MS, // updates the cooldown
            reparation_economic_power, // updates the new econ power
            current_timestamp, // time battle took place
            current_timestamp + BATTLE_LOSER_ECONOMIC_PENALTY_TIME, // battle time + time penalty
            loser_soldiers_left, // will always be zero becuase of the loss
            0 // no xp gain
        );

        // 6. emit event
        event::emit(CastleBattleLog { // log the battle
            attacker: attacker_id, // attacker id
            winner: winner_id, // winner id
            loser: loser_id,// loser id
            winner_soldiers_lost: winner_soldiers_lost, // how many soldiers did the winner lose? 
            loser_soldiers_lost: loser_soldiers_lost, // how many soldiers did the loser lose?
            reparation_economic_power: reparation_economic_power, // this tells us what value of economic buff and debuff will be applied
            battle_time: current_timestamp, // time the battle happened
            reparation_end_time: current_timestamp + BATTLE_LOSER_ECONOMIC_PENALTY_TIME // end time for negative or positive affect
        });
    }


}