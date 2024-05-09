module move_castle::core { // this represents the package and the module <package>::<module>
    use sui::dynamic_field; // this package adds functionality to add fields after an object has been constructed
    use sui::math; // basic math functions 
    use sui::clock::{Self, Clock}; //adds the clock module and struct for time based functionality
    use move_castle::utils; // adds our utils package

    // anything abbreviated with E<name> is an error
    // anything in all CAPS is a constant

    /// Soldier count exceed limit
    const ESoldierCountLimit: u64 = 0; // soldier limit

    /// Insufficient treasury for recruiting soldiers
    const EInsufficientTreasury: u64 = 1; // not enough funds m'lord 

    /// Not enough castles to battle
    const ENotEnoughCastles: u64 = 2; // you need friends to play this game

    /// Castle race - human
    const CASTLE_RACE_HUMAN : u64 = 0;
    /// Castle race - elf
    const CASTLE_RACE_ELF : u64 = 1;
    /// Castle race - orcs
    const CASTLE_RACE_ORCS : u64 = 2;
    /// Castle race - goblin
    const CASTLE_RACE_GOBLIN : u64 = 3;
    /// Castle race - undead
    const CASTLE_RACE_UNDEAD : u64 = 4;

    /// Initial attack power - human castle
    const INITIAL_ATTCK_POWER_HUMAN : u64 = 1000;
    /// Initial attack power - elf castle
    const INITIAL_ATTCK_POWER_ELF : u64 = 500;
    /// Initial attack power - orcs castle
    const INITIAL_ATTCK_POWER_ORCS : u64 = 1500;
    /// Initial attack power - goblin castle
    const INITIAL_ATTCK_POWER_GOBLIN : u64 = 1200;
    /// Initial attack power - undead castle
    const INITIAL_ATTCK_POWER_UNDEAD : u64 = 800;

    /// Initial defense power - human castle
    const INITIAL_DEFENSE_POWER_HUMAN : u64 = 1000;
    /// Initial defense power - elf castle
    const INITIAL_DEFENSE_POWER_ELF : u64 = 1500;
    /// Initial defense power - orcs castle
    const INITIAL_DEFENSE_POWER_ORCS : u64 = 500;
    /// Initial defense power - goblin castle
    const INITIAL_DEFENSE_POWER_GOBLIN : u64 = 800;
    /// Initial defense power - undead castle
    const INITIAL_DEFENSE_POWER_UNDEAD : u64 = 1200;

    /// Castle size - small
    const CASTLE_SIZE_SMALL : u64 = 1;
    /// Castle size - middle
    const CASTLE_SIZE_MIDDLE : u64 = 2;
    /// Castle size - big
    const CASTLE_SIZE_BIG : u64 = 3;

    /// Initial economic power - small castle
    const INITIAL_ECONOMIC_POWER_SMALL_CASTLE : u64 = 100;
    /// Initial economic power - middle castle
    const INITIAL_ECONOMIC_POWER_MIDDLE_CASTLE : u64 = 150;
    /// Initial economic power - big castle
    const INITIAL_ECONOMIC_POWER_BIG_CASTLE : u64 = 250;

    /// Initial soldiers
    const INITIAL_SOLDIERS : u64 = 10;
    /// Soldier economic power
    const SOLDIER_ECONOMIC_POWER : u64 = 1;
    /// Each soldier's price
    const SOLDIER_PRICE : u64 = 100;

    /// Max soldier count per castle - small castle
    const MAX_SOLDIERS_SMALL_CASTLE : u64 = 500;
    /// Max soldier count per castle - middle castle
    const MAX_SOLDIERS_MIDDLE_CASTLE : u64 = 1000;
    /// Max soldier count per castle - big castle
    const MAX_SOLDIERS_BIG_CASTLE : u64 = 2000;

    /// Soldier attack power - human
    const SOLDIER_ATTACK_POWER_HUMAN : u64 = 100;
    /// Soldier defense power - human
    const SOLDIER_DEFENSE_POWER_HUMAN : u64 = 100;
    /// Soldier attack power - elf
    const SOLDIER_ATTACK_POWER_ELF : u64 = 50;
    /// Soldier defense power - elf
    const SOLDIER_DEFENSE_POWER_ELF : u64 = 150;
    /// Soldier attack power - orcs
    const SOLDIER_ATTACK_POWER_ORCS : u64 = 150;
    /// Soldier defense power - orcs
    const SOLDIER_DEFENSE_POWER_ORCS : u64 = 50;
    /// Soldier attack power - goblin
    const SOLDIER_ATTACK_POWER_GOBLIN : u64 = 120;
    /// Soldier defense power - goblin
    const SOLDIER_DEFENSE_POWER_GOBLIN : u64 = 80;
    /// Soldier attack power - undead
    const SOLDIER_ATTACK_POWER_UNDEAD : u64 = 120;
    /// Soldier defense power - undead
    const SOLDIER_DEFENSE_POWER_UNDEAD : u64 = 80;

    /// Experience points the winner gain in a battle based on winner's level 1 - 10
    const BATTLE_EXP_GAIN_LEVELS : vector<u64> = vector[25, 30, 40, 55, 75, 100, 130, 165, 205, 250];
    /// Experience points required for castle level 2 - 10
    const REQUIRED_EXP_LEVELS : vector<u64> = vector[100, 150, 225, 338, 507, 760, 1140, 1709, 2563];

    /// Max castle level
    const MAX_CASTLE_LEVEL : u64 = 10;

    /// Castle size factor - small
    const CASTLE_SIZE_FACTOR_SMALL : u64 = 2;
    /// Castle size factor - middle
    const CASTLE_SIZE_FACTOR_MIDDLE : u64 = 3;
    /// Castle size factor - big
    const CASTLE_SIZE_FACTOR_BIG : u64 = 5;

    /// Castle amount limit - small
    const CASTLE_AMOUNT_LIMIT_SMALL : u64 = 500;
    /// Castle amount limit - middle
    const CASTLE_AMOUNT_LIMIT_MIDDLE : u64 = 300;
    /// Castle amount limit - big
    const CASTLE_AMOUNT_LIMIT_BIG : u64 = 200;

    /// Holding game info
    public struct GameStore has key, store { // think of the game store as the global castle counter
        id: UID, // this is a reference to a globally unique ID.
        small_castle_count: u64, // for small castle amount limit
        middle_castle_count: u64, // for middle castle amount limit
        big_castle_count: u64, // for big castle amount limit
        castle_ids: vector<ID>, // holding all castle object ids
    }

    public struct CastleData has store { // castleData is the metadata for castles we generate values for this object when we build new castles
        id: ID, // this is a reference to a globally unique ID.
        size: u64, // the size of the castle
        race: u64, // teh race of the castle
        level: u64, // the level of the castle
        experience_pool: u64, // the xp tracker
        economy: Economy, // the castle economy (as an object not an asset)
        millitary: Millitary, // the castle military (as an object not an asset)
    }

    public struct Economy has store { // represents the castle economy
        treasury: u64, // how much $$$ in the castle's treasury
        base_power: u64, // base econ power
        settle_time: u64, // when last the economy was settled
        soldier_buff: EconomicBuff, // economic buff (if any) as an object
        battle_buff: vector<EconomicBuff>, // represents the list of buffs casles can accumulate by winning battles
    }

    public struct EconomicBuff has copy, store, drop {  //represents the buffs casles can accumulate by winning battles
        debuff: bool, // boolean to track if it's a buff or debuff
        power: u64, // the power value of the buff
        start: u64, // when the buff starts
        end: u64, // when the buff ends
    }

    public struct Millitary has store { // represents the castle's military
        attack_power: u64, // the castle attack power
        defense_power: u64,// the castle defense power
        total_attack_power: u64, // the castle's total attack power
        total_defense_power: u64, // the castle's total defense power
        soldiers: u64, // the amount of soldiers in the castle
        battle_cooldown: u64, // the battle cooldown (when this castle can't battle)
    }

    /// Capability to modify game settings
    public struct AdminCap has key { // this is a struct to represent admin functionality
        id: UID // this is a reference to a globally unique ID.
        // @todo explain capability design pattern
    }

    /// Settle castle's economy, including victory rewards and defeat penalties
    public fun settle_castle_economy(id: ID, clock: &Clock, game_store: &mut GameStore) { // method alias function to call the inner function 
        // the castle data is stored as a dynamic field, the `dynamic_field::borrow_mut` borrows a mutable dynamic field
        // of the CastleData to pass to the inner function since the inner function looks like this `public fun settle_castle_economy_inner(clock: &Clock, castle_data: &mut CastleData) {`
        settle_castle_economy_inner(clock, dynamic_field::borrow_mut<ID, CastleData>(&mut game_store.id, id));
    }   

    /// Module initializer create the only one AdminCap and send it to the publisher
	fun init(ctx: &mut TxContext) { // the init function takes a mutable reference of the TxContext
		transfer::transfer(AdminCap{id: object::new(ctx)}, tx_context::sender(ctx)); // creates a new AdminCap object and sends it to the sender (the user who instantiates the module)

        transfer::share_object( // this function creates a new GameStore object and makes it sharable
            GameStore{ // new gamestore object
                id: object::new(ctx), // creates a new id for the object
                small_castle_count: 0, // sets small castle count to zero 
                middle_castle_count: 0, // sets middle castle count to zero
                big_castle_count: 0, // sets big castle count to zero
                castle_ids: vector::empty<ID>() // creates a new empty vector of castle_ids
            }
        );
	}


    // This function gets called as part of the build_castle function in castle. It generates the castle data
    // i.e. it populates the CastleData struct and stores is as a dynamic field
    public fun init_castle_data(id: ID, // this is going to be the castle id 
                                size: u64, // the size of the castle
                                race: u64, // the castle race
                                current_timestamp: u64, // the timestamp the castle was created (so now)
                                game_store: &mut GameStore) { // a mutable reference to the game store
        // 1. get initial power and init castle data
        let (attack_power, defense_power) = get_initial_attack_defense_power(race); // this gets the attack power for the race
        let (soldiers_attack_power, soldiers_defense_power) = get_initial_soldiers_attack_defense_power(race, INITIAL_SOLDIERS); // sets the initial soldier attack+defense power for the race + init soldier constant
        let castle_data = CastleData { // this is where the code starts creating the object
            id: id, // sets the parameter id to the struct id
            size: size, // sets the parameter size to the struct size
            race: race, // sets the parameter race to the struct race
            level: 1, // sets the level to 1 (starting level)
            experience_pool: 0, // sets the experience to zero, starting xp
            economy: Economy { // create a new Economy object
                treasury: 0, // set the treasury to zero
                base_power: get_initial_economic_power(size), // get the initial econ power based on size
                settle_time: current_timestamp, // econ settle time (this would be now)
                soldier_buff: EconomicBuff { // create econbuff object
                    debuff: false, // debuff should be false since this is a new castle
                    power: SOLDIER_ECONOMIC_POWER * INITIAL_SOLDIERS, // set initial buff power
                    start: current_timestamp, // set the start of the buff (now)
                    end: 0 // set the end of the buff @todo I think this is zero because it's the initial buff that we'll always keep
                },
                battle_buff: vector::empty<EconomicBuff>() // create an empty battle buff since the castle is new and we haven't done any battles
            },
            millitary: Millitary { // create a military object
                attack_power: attack_power, // set an initial attack power (based on the castle race)
                defense_power: defense_power, // set an initial defense power (based on the castle race)
                total_attack_power: attack_power + soldiers_attack_power, // set total attack power (race attack power + soldiers)
                total_defense_power: defense_power + soldiers_defense_power, // set total defense power (race attack power + soldiers)
                soldiers: INITIAL_SOLDIERS, // set soldier amount
                battle_cooldown: current_timestamp // set battle cooldown to now (so no cooldown really)
            }
        };
    
        // 2. store the castle data
        dynamic_field::add(&mut game_store.id, id, castle_data);
        /*
            We store the castle data in a dynamic field in stead of its own asset. 
            This is quite unique and the reasons for this are explained here https://docs.sui.io/concepts/dynamic-fields

            The TLDR is it's a way of attaching objects to other objects kind of like a map. This is 
            linking the castle_data to the gameStore object using the castle id as the as the key
        */
        // 3. update castle ids and castle count
        vector::push_back(&mut game_store.castle_ids, id); // adds the new castle id to the end of the vector 
        if (size == CASTLE_SIZE_SMALL) { // if the castle is small
            game_store.small_castle_count = game_store.small_castle_count + 1; // if the castle is small increase the small counter in the game store by one
        } else if (size == CASTLE_SIZE_MIDDLE) { // if the castle is middle
            game_store.middle_castle_count = game_store.middle_castle_count + 1; // if the castle is "middle" increase the "middle" counter in the game store by one
        } else if (size == CASTLE_SIZE_BIG) { // if the castle is big
            game_store.big_castle_count = game_store.big_castle_count + 1; // if the castle is big increase the big counter in the game store by one
        } else {
            abort 0 // this abort will terminate the execution of the entire transaction. That being said, we shouldn't be able to run this
        };
    }

    /// Settle castle's economy, inner method
    public fun settle_castle_economy_inner(clock: &Clock, castle_data: &mut CastleData) {
        let current_timestamp = clock::timestamp_ms(clock);

        // 1. calculate base power benefits
        let base_benefits = calculate_economic_benefits(castle_data.economy.settle_time, current_timestamp, castle_data.economy.base_power);
        castle_data.economy.treasury = castle_data.economy.treasury + base_benefits;
        castle_data.economy.settle_time = current_timestamp;

        // 2. calculate soldier buff
        let soldier_benefits = calculate_economic_benefits(castle_data.economy.soldier_buff.start, current_timestamp, castle_data.economy.soldier_buff.power);
        castle_data.economy.treasury = castle_data.economy.treasury + soldier_benefits;
        castle_data.economy.soldier_buff.start = current_timestamp;

        // 3. calculate battle buff
        if (!vector::is_empty(&castle_data.economy.battle_buff)) {
            let length = vector::length(&castle_data.economy.battle_buff);
            let mut expired_buffs = vector::empty<u64>();
            let mut i = 0;
            while (i < length) {
                let buff = vector::borrow_mut(&mut castle_data.economy.battle_buff, i);
                let mut battle_benefit;
                if (buff.end <= current_timestamp) {
                    vector::push_back(&mut expired_buffs, i);
                    battle_benefit = calculate_economic_benefits(buff.start, buff.end, buff.power);
                } else {
                    battle_benefit = calculate_economic_benefits(buff.start, current_timestamp, buff.power);
                    buff.start = current_timestamp;
                };

                if (buff.debuff) {
                    castle_data.economy.treasury = castle_data.economy.treasury - battle_benefit;
                } else {
                    castle_data.economy.treasury = castle_data.economy.treasury + battle_benefit;
                };
                i = i + 1;
            };

            // remove expired buffs
            while(!vector::is_empty(&expired_buffs)) {
                let expired_buff_index = vector::remove(&mut expired_buffs, 0);
                vector::remove(&mut castle_data.economy.battle_buff, expired_buff_index);
            };
            vector::destroy_empty<u64>(expired_buffs);
        }
    } 
    
    /// Castle uses treasury to recruit soldiers
    public fun recruit_soldiers (id: ID, count: u64, clock: &Clock, game_store: &mut GameStore) {
        // 1. borrow the castle data
        let castle_data = dynamic_field::borrow_mut<ID, CastleData>(&mut game_store.id, id);

        // 2. check count limit
        let final_soldiers = castle_data.millitary.soldiers + count;
        assert!(final_soldiers <= get_castle_soldier_limit(castle_data.size), ESoldierCountLimit);

        // 3. check treasury sufficiency
        let total_soldier_price = SOLDIER_PRICE * count;
        assert!(castle_data.economy.treasury >= total_soldier_price, EInsufficientTreasury);

        // 4. settle economy
        settle_castle_economy_inner(clock, castle_data);

        // 5. update treasury and soldiers
        castle_data.economy.treasury = castle_data.economy.treasury - total_soldier_price;
        castle_data.millitary.soldiers = final_soldiers;

        // 6. update soldier economic power buff
        castle_data.economy.soldier_buff.power = SOLDIER_ECONOMIC_POWER * final_soldiers;
        castle_data.economy.soldier_buff.start = clock::timestamp_ms(clock);
    
        // 7. update total attack/defense power
        castle_data.millitary.total_attack_power = get_castle_total_attack_power(freeze(castle_data));
        castle_data.millitary.total_defense_power = get_castle_total_defense_power(freeze(castle_data));
    }

    /// Settle battle
    public fun battle_settlement_save_castle_data(game_store: &mut GameStore, mut castle_data: CastleData, win: bool, cooldown: u64, economic_base_power: u64, current_timestamp: u64, economy_buff_end: u64, soldiers_left: u64, exp_gain: u64) {
        // 1. battle cooldown
        castle_data.millitary.battle_cooldown = cooldown;
        // 2. soldier left
        castle_data.millitary.soldiers = soldiers_left;
        castle_data.economy.soldier_buff.power = calculate_soldiers_economic_power(soldiers_left);
        castle_data.economy.soldier_buff.start = current_timestamp;
        // 3. soldiers caused total attack/defense power
        castle_data.millitary.total_attack_power = get_castle_total_attack_power(&castle_data);
        castle_data.millitary.total_defense_power = get_castle_total_defense_power(&castle_data);
        // 4. exp gain
        castle_data.experience_pool = castle_data.experience_pool + exp_gain;
        // 5. economy buff
        vector::push_back(&mut castle_data.economy.battle_buff, EconomicBuff {
            debuff: !win,
            power: economic_base_power,
            start: current_timestamp,
            end: economy_buff_end,
        });
        // 6. put back to table
        dynamic_field::add(&mut game_store.id, castle_data.id, castle_data);
    }


    // === Public-View Functions ===

    /// Consume experience points from the experience pool to upgrade the castle
    public fun upgrade_castle(id: ID, game_store: &mut GameStore) {
        // 1. fetch castle data
        let castle_data = dynamic_field::borrow_mut<ID, CastleData>(&mut game_store.id, id);

        // 2. continually upgrade if exp is enough
        let initial_level = castle_data.level;
        while (castle_data.level < MAX_CASTLE_LEVEL) {
            let exp_required_at_current_level = *vector::borrow(&REQUIRED_EXP_LEVELS, castle_data.level - 1);
            if(castle_data.experience_pool < exp_required_at_current_level) {
                break
            };

            castle_data.experience_pool = castle_data.experience_pool - exp_required_at_current_level;
            castle_data.level = castle_data.level + 1;
        };

        // 3. update powers if upgraded
        if (castle_data.level > initial_level) {
            let base_economic_power = calculate_castle_base_economic_power(freeze(castle_data));
            castle_data.economy.base_power = base_economic_power;

            let (attack_power, defense_power) = calculate_castle_base_attack_defense_power(freeze(castle_data));
            castle_data.millitary.attack_power = attack_power;
            castle_data.millitary.defense_power = defense_power;
        }
    }


    /// Get initial attack power and defense power by race
    fun get_initial_attack_defense_power(race: u64): (u64, u64) {
        let (attack, defense);

        if (race == CASTLE_RACE_HUMAN) {
            (attack, defense) = (INITIAL_ATTCK_POWER_HUMAN, INITIAL_DEFENSE_POWER_HUMAN);
        } else if (race == CASTLE_RACE_ELF) {
            (attack, defense) = (INITIAL_ATTCK_POWER_ELF, INITIAL_DEFENSE_POWER_ELF);
        } else if (race == CASTLE_RACE_ORCS) {
            (attack, defense) = (INITIAL_ATTCK_POWER_ORCS, INITIAL_DEFENSE_POWER_ORCS);
        } else if (race == CASTLE_RACE_GOBLIN) {
            (attack, defense) = (INITIAL_ATTCK_POWER_GOBLIN, INITIAL_DEFENSE_POWER_GOBLIN);
        } else if (race == CASTLE_RACE_UNDEAD) {
            (attack, defense) = (INITIAL_ATTCK_POWER_UNDEAD, INITIAL_DEFENSE_POWER_UNDEAD);
        } else {
            abort 0
        };

        (attack, defense)
    }

    fun get_initial_soldiers_attack_defense_power(race: u64, soldiers: u64): (u64, u64) {
        let (attack, defense) = get_castle_soldier_attack_defense_power(race);
        (attack * soldiers, defense * soldiers)
    }

    // Get initial economic power by castle size
    fun get_initial_economic_power(size: u64): u64 {
        let power;
        if (size == CASTLE_SIZE_SMALL) {
            power = INITIAL_ECONOMIC_POWER_SMALL_CASTLE;
        } else if (size == CASTLE_SIZE_MIDDLE) {
            power = INITIAL_ECONOMIC_POWER_MIDDLE_CASTLE;
        } else if (size == CASTLE_SIZE_BIG) {
            power = INITIAL_ECONOMIC_POWER_BIG_CASTLE;
        } else {
            abort 0
        };
        power
    }

    /// Calculate economic benefits based on power and time period (1 minute).
    fun calculate_economic_benefits(start: u64, end: u64, power: u64): u64 {
        math::divide_and_round_up((end - start) * power, 60u64 * 1000u64)
    }

    public fun get_castle_battle_cooldown(castle_data: &CastleData): u64 {
        castle_data.millitary.battle_cooldown
    }

    public fun fetch_castle_data(id1: ID, id2: ID, game_store: &mut GameStore): (CastleData, CastleData) {
        let castle_data1 = dynamic_field::remove<ID, CastleData>(&mut game_store.id, id1);
        let castle_data2 = dynamic_field::remove<ID, CastleData>(&mut game_store.id, id2);
        (castle_data1, castle_data2)
    }

    /// Get castle soldier limit by castle size
    fun get_castle_soldier_limit(size: u64) : u64 {
        let soldier_limit;
        if (size == CASTLE_SIZE_SMALL) {
            soldier_limit = MAX_SOLDIERS_SMALL_CASTLE;
        } else if (size == CASTLE_SIZE_MIDDLE) {
            soldier_limit = MAX_SOLDIERS_MIDDLE_CASTLE;
        } else if (size == CASTLE_SIZE_BIG) {
            soldier_limit = MAX_SOLDIERS_BIG_CASTLE;
        } else {
            abort 0
        };
        soldier_limit
    }

    // Random a target castle id
    public fun random_battle_target(from_castle: ID, game_store: &GameStore, ctx: &mut TxContext): ID {
        let total_length = vector::length<ID>(&game_store.castle_ids);
        assert!(total_length > 1, ENotEnoughCastles);

        let mut random_index = utils::random_in_range(total_length, ctx);
        let mut target = vector::borrow<ID>(&game_store.castle_ids, random_index);

        while (object::id_to_address(&from_castle) == object::id_to_address(target)) {
            // redo random until not equals
            random_index = utils::random_in_range(total_length, ctx);
            target = vector::borrow<ID>(&game_store.castle_ids, random_index);
        };

        object::id_from_address(object::id_to_address(target))
    }

    /// Castle's single soldier's attack power and defense power
    public fun get_castle_soldier_attack_defense_power(race: u64): (u64, u64) {
        let soldier_attack_power;
        let soldier_defense_power;
        if (race == CASTLE_RACE_HUMAN) {
            soldier_attack_power = SOLDIER_ATTACK_POWER_HUMAN;
            soldier_defense_power = SOLDIER_DEFENSE_POWER_HUMAN;
        } else if (race == CASTLE_RACE_ELF) {
            soldier_attack_power = SOLDIER_ATTACK_POWER_ELF;
            soldier_defense_power = SOLDIER_DEFENSE_POWER_ELF;
        } else if (race == CASTLE_RACE_ORCS) {
            soldier_attack_power = SOLDIER_ATTACK_POWER_ORCS;
            soldier_defense_power = SOLDIER_DEFENSE_POWER_ORCS;
        } else if (race == CASTLE_RACE_GOBLIN) {
            soldier_attack_power = SOLDIER_ATTACK_POWER_GOBLIN;
            soldier_defense_power = SOLDIER_DEFENSE_POWER_GOBLIN;
        } else if (race == CASTLE_RACE_UNDEAD) {
            soldier_attack_power = SOLDIER_ATTACK_POWER_UNDEAD;
            soldier_defense_power = SOLDIER_DEFENSE_POWER_UNDEAD;
        } else {
            abort 0
        };

        (soldier_attack_power, soldier_defense_power)
    }

        public fun get_castle_race(castle_data: &CastleData): u64 {
        castle_data.race
    }

    /// Castle's total soldiers attack power
    public fun get_castle_total_soldiers_attack_power(castle_data: &CastleData): u64 {
        let (soldier_attack_power, _) = get_castle_soldier_attack_defense_power(castle_data.race);
        castle_data.millitary.soldiers * soldier_attack_power
    }

    /// Castle's total soldiers defense power
    public fun get_castle_total_soldiers_defense_power(castle_data: &CastleData): u64 {
        let (_, soldier_defense_power) = get_castle_soldier_attack_defense_power(castle_data.race);
        castle_data.millitary.soldiers * soldier_defense_power
    }

    /// Castle's total attack power (base + soldiers)
    public fun get_castle_total_attack_power(castle_data: &CastleData): u64 {
        castle_data.millitary.attack_power + get_castle_total_soldiers_attack_power(castle_data)
    }

    /// Castle's total defense power (base + soldiers)
    public fun get_castle_total_defense_power(castle_data: &CastleData): u64 {
        castle_data.millitary.defense_power + get_castle_total_soldiers_defense_power(castle_data)
    }
    
    // If has race advantage
    public fun has_race_advantage(castle_data1: &CastleData, castle_data2: &CastleData): bool {
        let c1_race = castle_data1.race;
        let c2_race = castle_data2.race;

        let has;
        if (c1_race == c2_race) {
            has = false;
        } else if (c1_race < c2_race) {
            has = (c2_race - c1_race) == 1;
        } else {
            has = (c1_race - c2_race) == 4;
        };

        has
    }

    public fun get_castle_id(castle_data: &CastleData): ID {
        castle_data.id
    }

    public fun get_castle_soldiers(castle_data: &CastleData): u64 {
        castle_data.millitary.soldiers
    }

    public fun battle_winner_exp(castle_data: &CastleData): u64 { 
        *vector::borrow<u64>(&BATTLE_EXP_GAIN_LEVELS, castle_data.level)
    }

    public fun get_castle_economic_base_power(castle_data: &CastleData): u64 { // retuns the base econ base power for the castle using a reference to CastleData
        castle_data.economy.base_power // return base power from object
    }

    // Calculate soldiers economic power
    public fun calculate_soldiers_economic_power(count: u64): u64 { // calculates the econ power for the amount of soldiers
        SOLDIER_ECONOMIC_POWER * count // econ power constant for a single soldier * amount of soldiers you want to calculate the power for
    }

    /// Calculate castle's base economic power
    fun calculate_castle_base_economic_power(castle_data: &CastleData): u64 { // calculates the initial castle base econ power referencing CastleData
        let initial_base_power = get_initial_economic_power(castle_data.size); // get initial power from size
        let level = castle_data.level; // get castle level
        math::divide_and_round_up(initial_base_power * 12 * math::pow(10, ((level - 1) as u8)), 10) // see the `calculate_castle_base_attack_defense_power` it works on the same principle 
    }

    /// Get castle size factor
    fun get_castle_size_factor(castle_size: u64): u64 { // gets the castle factor by size. The factor is used to calculate the castle base attack and defense power
        let factor; // create variable
        if (castle_size == CASTLE_SIZE_SMALL) { // if the castle is small
            factor = CASTLE_SIZE_FACTOR_SMALL; // get the small factor
        } else if (castle_size == CASTLE_SIZE_MIDDLE) { // if the castle is medium
            factor = CASTLE_SIZE_FACTOR_MIDDLE; // get the medium factor
        } else if (castle_size == CASTLE_SIZE_BIG) { // if the castle is big
            factor = CASTLE_SIZE_FACTOR_BIG; // get the big factor
        } else {
            abort 0 // terminate the transaction
        };
        factor // return the factor
    }

    /// Calculate castle's base attack power and base defense power based on level
    /// base attack power = (castle_size_factor * initial_attack_power * (1.2 ^ (level - 1)))
    /// base defense power = (castle_size_factor * initial_defense_power * (1.2 ^ (level - 1)))
    fun calculate_castle_base_attack_defense_power(castle_data: &CastleData): (u64, u64) { // parameter is a reference to castleData (not mutable, thus not state changing)
        let castle_size_factor = get_castle_size_factor(castle_data.size); // get the castle size factor based on the size
        let (initial_attack, initial_defense) = get_initial_attack_defense_power(castle_data.race); // get the initial attack & defense power based on the race
        let attack_power = math::divide_and_round_up(castle_size_factor * initial_attack * 12 * math::pow(10, ((castle_data.level - 1) as u8)), 10); 
        let defense_power = math::divide_and_round_up(castle_size_factor * initial_defense * 12 * math::pow(10, ((castle_data.level - 1) as u8)), 10);

        /* 
            ok so there are 2 functions from the math module here `divide_and_round_up` and `pow` let's figure out what they do first

            divide_and_round_up: this function divides two variables x & y, BUT if there is a remainder it'll round up 
            so if 10/5 = 2
            but 10/4 = 3

            pow: takes a base value and raises it to a power
            so if base x = 2
            power y = 2
            result = 4 

            since `divide_and_round_up` is the outer function:
            x = castle_size_factor * initial_attack * 12 * math::pow(10, ((castle_data.level - 1) as u8))
            y = 10

            let's break x into pieces: 
            piece a -> castle_size_factor * initial_attack * 12
            *
            piece b -> math::pow(10, ((castle_data.level - 1) as u8))

            piece a * piece b = piece c

            then finally:
            attack_power = divide_and_round_up(piece c, 10)
            defense_power = divide_and_round_up(piece c, 10)


            With numbers for a middle castle, race elf:
            castle_size_factor = 3 
            initial_attack = 500
            initial_defense = 1500
            level = 1 

            attack_power = divide_and_round_up(x:(3 * 500 * 12 * (10^0)), y: 10)
            attack_power = divide_and_round_up(18000/10)
            attack_power = 1800

            defense_power = divide_and_round_up(x:(3 * 1500 * 12 * (10^0)), y:10)
            defense_power = divide_and_round_up(54000/10)
            defense_power = 5400

         */

        (attack_power, defense_power) // return attack and defense power
    }

    public fun allow_new_castle(size: u64, game_store: &GameStore): bool { 
        // this is a view function to check if a new castle is allowed to be created based on the castle limits
        let allow; // sets a new variable
        if (size == CASTLE_SIZE_SMALL) { // check if the size is small
            allow = game_store.small_castle_count < CASTLE_AMOUNT_LIMIT_SMALL; // allow will be true if the count is less than the limit (false if not)
        } else if (size == CASTLE_SIZE_MIDDLE) { // check if the size is middle
            allow = game_store.middle_castle_count < CASTLE_AMOUNT_LIMIT_MIDDLE; // allow will be true if the count is less than the limit (false if not)
        } else if (size == CASTLE_SIZE_BIG) { // check if the size is big
            allow = game_store.big_castle_count < CASTLE_AMOUNT_LIMIT_BIG; // allow will be true if the count is less than the limit (false if not)
        } else {
            abort 0 // this will terminate the transaction
        };
        allow // return allow
    }

}