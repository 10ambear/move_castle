module move_castle::battle {
    use sui::object::{Self, ID};
    use sui::tx_context::TxContext;
    use sui::clock::{Self, Clock};
    use move_castle::castle::Castle;
    use move_castle::core::{Self, GameStore};

    entry fun battle(castle: &mut Castle, clock: &Clock, game_store: &mut GameStore, ctx: &mut TxContext) {
        // 1. random out a target
        let attacker_id = object::id(castle);
        let target_id = core::random_battle_target(attacker_id, game_store, ctx);

        // 2. castle data
        let (attacker, defender) = core::fetch_castle_data(attacker_id, target_id, game_store);

        // 3. check battle cooldown
        let current_timestamp = clock::timestamp_ms(clock);
        assert!(core::get_castle_battle_cooldown(&attacker) < current_timestamp, 0);
        assert!(core::get_castle_battle_cooldown(&defender) < current_timestamp, 0);
    }


}