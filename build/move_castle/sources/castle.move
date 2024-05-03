// castle.move

module move_castle::castle {

    use std::string::{Self, String, utf8};
    use sui::package;
    use move_castle::utils;
    use sui::display;
    use sui::clock::{Self, Clock};
    use move_castle::core::{Self, GameStore};


    fun init(otw: CASTLE, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"link"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"{name}"),
            utf8(b"https://movecastle.info/castles/{serial_number}"),
            utf8(b"https://images.movecastle.info/static/media/castles/{image_id}.png"),
            utf8(b"{description}"),
            utf8(b"https://movecastle.info"),
            utf8(b"Castle Builder"),
        ];

        let publisher = package::claim(otw, ctx);
        let mut display = display::new_with_fields<Castle>(&publisher, keys, values, ctx);

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }
    
    /// The castle struct
    public struct Castle has key, store{
        id: UID,
        name: String,
        description: String,
        serial_number: u64,
        image_id: String,
    }   

    /// One-Time-Witness for the module, it has to be the first struct in the module, and
    /// its name should be same as the module name but all uppercase.
     public struct CASTLE has drop {}

    /// Transfer castle
    entry fun transfer_castle(castle: Castle, to: address) {
        transfer::transfer(castle, to);
    }
        
    /// Build a castle.
    entry fun build_castle(size: u64, name_bytes: vector<u8>, desc_bytes: vector<u8>,clock: &Clock, game_store: &mut GameStore, ctx: &mut TxContext) {

        // castle object UID.
        let mut obj_id = object::new(ctx);
        
        // generate serial number and image id
        let serial_number = utils::generate_castle_serial_number(size, &mut obj_id);
        let image_id = utils::serial_number_to_image_id(serial_number);
        
        // new castle object.
        let castle = Castle {
            id: obj_id,
            name: string::utf8(name_bytes),
            description: string::utf8(desc_bytes),
            serial_number: serial_number,
            image_id: image_id,
        };

        // new castle game data
        let id = object::uid_to_inner(&castle.id);
        let race = get_castle_race(serial_number);
        core::init_castle_data(
            id, 
            size,
            race,
            clock::timestamp_ms(clock),
            game_store
        );
        
        // transfer castle object to the owner.
        transfer::public_transfer(castle, tx_context::sender(ctx));
    }

    /// Get castle race
    public fun get_castle_race(serial_number: u64): u64 {
        let mut race_number = serial_number % 10;
        if (race_number >= 5) {
            race_number = race_number - 5;
        };
        race_number
    }
}