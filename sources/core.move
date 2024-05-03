module move_castle::core {
    use sui::dynamic_field;
    use sui::math;
    use sui::clock::{Self, Clock};
    use move_castle::utils;


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

    /// Initial soldiers
    const INITIAL_SOLDIERS : u64 = 10;
    /// Soldier economic power
    const SOLDIER_ECONOMIC_POWER : u64 = 1;

    /// Max soldier count per castle - small castle
    const MAX_SOLDIERS_SMALL_CASTLE : u64 = 500;
    /// Max soldier count per castle - middle castle
    const MAX_SOLDIERS_MIDDLE_CASTLE : u64 = 1000;
    /// Max soldier count per castle - big castle
    const MAX_SOLDIERS_BIG_CASTLE : u64 = 2000;
    /// Each soldier's price
    const SOLDIER_PRICE : u64 = 100;



    /// Capability to modify game settings
    public struct AdminCap has key {
        id: UID
    }

    /// Holding game info
   public struct GameStore has key, store {
        id: UID,
        small_castle_count: u64, // for small castle amount limit
        middle_castle_count: u64, // for middle castle amount limit
        big_castle_count: u64, // for big castle amount limit
        castle_ids: vector<ID>, // holding all castle object ids
    }

    public struct CastleData has store {
        id: ID,
        size: u64,
        race: u64,
        level: u64,
        experience_pool: u64,
        economy: Economy, 
        millitary: Millitary, 

    }

    public struct Millitary has store {
        attack_power: u64,
        defense_power: u64,
        total_attack_power: u64,
        total_defense_power: u64,
        soldiers: u64,
        battle_cooldown: u64,
    }
    

    public struct Economy has store {
        treasury: u64,
        base_power: u64,
        settle_time: u64,
        soldier_buff: EconomicBuff,
        battle_buff: vector<EconomicBuff>,
    }

    public struct EconomicBuff has copy, store, drop {
        debuff: bool,
        power: u64,
        start: u64,
        end: u64,
    }

    

        /// Module initializer create the only one AdminCap and send it to the publisher
    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap{id: object::new(ctx)}, tx_context::sender(ctx));
        transfer::share_object(
        GameStore{
            id: object::new(ctx),
            small_castle_count: 0,
            middle_castle_count: 0,
            big_castle_count: 0,
            castle_ids: vector::empty<ID>()
            }
        );
    }
    

    /// initialize the castle data
    public fun init_castle_data(id: ID,
                                size: u64,
                                race: u64,
                                current_timestamp: u64,
                                game_store: &mut GameStore) {
        // 1. get initial power and init castle data
        let (attack_power, defense_power) = get_initial_attack_defense_power(race);
        let (soldiers_attack_power, soldiers_defense_power) = get_initial_soldiers_attack_defense_power(race, INITIAL_SOLDIERS);
        let castle_data = CastleData {
            id: id,
            size: size,
            race: race,
            level: 1,
            experience_pool: 0,
            economy: Economy {
                treasury: 0,
                base_power: get_initial_economic_power(size),
                settle_time: current_timestamp,
                soldier_buff: EconomicBuff {
                    debuff: false,
                    power: SOLDIER_ECONOMIC_POWER * INITIAL_SOLDIERS,
                    start: current_timestamp,
                    end: 0
                },
                battle_buff: vector::empty()
            },
            millitary: Millitary {
                attack_power: attack_power,
                defense_power: defense_power,
                total_attack_power: attack_power + soldiers_attack_power,
                total_defense_power: defense_power + soldiers_defense_power,
                soldiers: INITIAL_SOLDIERS,
                battle_cooldown: current_timestamp
            }
        };

        // 2. store the castle data
        dynamic_field::add(&mut game_store.id, id, castle_data);

        // 3. update castle ids and castle count
        vector::push_back(&mut game_store.castle_ids, id);
        if (size == CASTLE_SIZE_SMALL) {
            game_store.small_castle_count = game_store.small_castle_count + 1;
        } else if (size == CASTLE_SIZE_MIDDLE) {
            game_store.middle_castle_count = game_store.middle_castle_count + 1;
        } else if (size == CASTLE_SIZE_BIG) {
            game_store.big_castle_count = game_store.big_castle_count + 1;
        } else {
            abort 0
        };

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

        /// Get initial soldiers attack power and defense power by race and soldier amount
    fun get_initial_soldiers_attack_defense_power(race: u64, soldiers: u64): (u64, u64) {
        let (attack, defense) = get_castle_soldier_attack_defense_power(race);
        (attack * soldiers, defense * soldiers)
    }

    /// Calculate economic benefits based on power and time period (1 minute).
    fun calculate_economic_benefits(start: u64, end: u64, power: u64): u64 {
        math::divide_and_round_up((end - start) * power, 60u64 * 1000u64)
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

    /// Settle castle's economy, including victory rewards and defeat penalties
    public fun settle_castle_economy(id: ID, clock: &Clock, game_store: &mut GameStore) {
        settle_castle_economy_inner(clock, dynamic_field::borrow_mut<ID, CastleData>(&mut game_store.id, id));
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

    /// Castle uses treasury to recruit soldiers
    public fun recruit_soldiers (id: ID, count: u64, clock: &Clock, game_store: &mut GameStore) {
        // 1. borrow the castle data
        let castle_data = dynamic_field::borrow_mut<ID, CastleData>(&mut game_store.id, id);

        // 2. check count limit
        let final_soldiers = castle_data.millitary.soldiers + count;
        assert!(final_soldiers <= get_castle_soldier_limit(castle_data.size), 0);

        // 3. check treasury sufficiency
        let total_soldier_price = SOLDIER_PRICE * count;
        assert!(castle_data.economy.treasury >= total_soldier_price, 0);

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

    // Random a target castle id
    public fun random_battle_target(from_castle: ID, game_store: &GameStore, ctx: &mut TxContext): ID {
        let total_length = vector::length<ID>(&game_store.castle_ids);
        assert!(total_length > 1, 0);

        let mut random_index = utils::random_in_range(total_length, ctx);
        let mut target = vector::borrow<ID>(&game_store.castle_ids, random_index);

        while (object::id_to_address(&from_castle) == object::id_to_address(target)) {
            // redo random until not equals
            random_index = utils::random_in_range(total_length, ctx);
            target = vector::borrow<ID>(&game_store.castle_ids, random_index);
        };

        object::id_from_address(object::id_to_address(target))
    }

    public fun fetch_castle_data(id1: ID, id2: ID, game_store: &mut GameStore): (CastleData, CastleData) {
        let castle_data1 = dynamic_field::remove<ID, CastleData>(&mut game_store.id, id1);
        let castle_data2 = dynamic_field::remove<ID, CastleData>(&mut game_store.id, id2);
        (castle_data1, castle_data2)
    }

    public fun get_castle_battle_cooldown(castle_data: &CastleData): u64 {
        castle_data.millitary.battle_cooldown
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
        
}