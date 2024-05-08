module move_castle::castle { // this represents the package and the module <package>::<module>

    use std::string::{Self, utf8, String}; // adds the String module, the utf8 function and the String struct
    use sui::package; // adds the package module. We're using the claim function in order to claim a publisher
    use sui::display; // adds the display module. We're using this to add a dsiplay object to the Castle
    use sui::clock::{Self, Clock}; // adds the clock module and struct for time based functionality
    use sui::event; // adds the event module to emit events for creating castles
    use move_castle::utils; // adds our utils module from the move_castle package
    use move_castle::core::{Self, GameStore}; // adds the core module and GameStore struct from the move_castle package

    const ECastleAmountLimit: u64 = 0; // this is used for error handlings
    
    /// One-Time-Witness for the module
    public struct CASTLE has drop {} // this is a struct that only has the drop ability for the OTW design pattern
    /* 
    This object is designed to be consumed by the init function as part of the publisher
    workflow explained below. It gets dropped as part of the init function and can never be called
    again https://docs.sui.io/concepts/sui-move-concepts/one-time-witness
    */

    /// The castle struct
    public struct Castle has key, store{ // this is the castle object. It has the key and store abilities which makes it an asset
    	id: UID, // this is a reference to a globally unique ID.
        name: String, // the name of the object
        description: String, // a description of the object
        serial_number: u64, // a u64 serial number that's used to tracck the castle attributes
        image_id: String, // the image id for the castle 
    }

    /// Event - castle built
    public struct CastleBuilt has copy, drop { // this struct is used as an event
        id: ID, //the id of the castle being built
        owner: address, // represents a SUI address
    }

    fun init(otw: CASTLE, ctx: &mut TxContext) { 
    /* This is an init function (only run once when the module is published). Init functions are used
    to setup modules, similar to a constructor in other languages.

    otw: CASTLE -> we have to parse a OTW oject for the publisher function below. 
    ctx: &mut TxContext -> a mutable reference to the TxContext object. This gives additional info about the transaction (such as the sender address)
    */ 

        // the keys and values are for the display object
        let keys = vector[ // creating a new vector (collection) called keys of strings 
            utf8(b"name"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
            utf8(b"link"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
            utf8(b"image_url"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
            utf8(b"description"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
            utf8(b"project_url"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
            utf8(b"creator"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
        ];

        let values = vector[ // creating a new vector (collection) called values of strings 
            utf8(b"{name}"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
            utf8(b"https://movecastle.info/castles/{serial_number}"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
            utf8(b"https://images.movecastle.info/static/media/castles/{image_id}.png"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
            utf8(b"{description}"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
            utf8(b"https://movecastle.info"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
            utf8(b"Castle Builder"), // utf8 creates a new string from bytes `utf8(bytes: vector<u8>): String`. The b tells the move compiler we're dealing with bytes
        ];

        let publisher = package::claim(otw, ctx); 
        /* 
        The publisher object is explained here https://move-book.com/programmability/publisher.html
        It's used to prove authority. In this case the publisher is the sender i.e. the person
        who initiates the module. We're using the publisher for the display object below.

        Note this is the reason why we're using the OTW
        */

        let mut display = display::new_with_fields<Castle>(&publisher, keys, values, ctx);
        /* https://move-book.com/programmability/display.html

            The  display object exists to extend the object metadata for display purposes. It makes sense if you think about the fact
            that objects are owned by users, but the object display can be owned by the publisher. This means that the publisher can add
            metadata for objects on a global level
        */

        display::update_version(&mut display); // updates the version of the newly created object

        transfer::public_transfer(publisher, tx_context::sender(ctx)); // transfers the publisher object to the sender
        transfer::public_transfer(display, tx_context::sender(ctx)); // transfers the display object to the sender
    }

    /// Build a castle.
    entry fun build_castle(size: u64, name_bytes: vector<u8>, desc_bytes: vector<u8>, clock: &Clock, game_store: &mut GameStore, ctx: &mut TxContext) {
        /* 
        This function is used to build our caslte object. Note the word `entry` means that the function can be called
        from a transaction, but not other modules

        size: u64 -> the size of the castle represented as a u64
        name_bytes: vector<u8> -> the name of the castle as a string (strings are vectors)
        desc_bytes: vector<u8> -> the description of the castle as a string (strings are vectors)
        clock: &Clock, -> a reference to the SUI clock module used to access time related functions 
        game_store: &mut GameStore -> a mutable reference to the Gamestore object
        ctx: &mut TxContext - a mutable reference to the TxContext object. This gives additional info about the transaction (such as the sender address)
        
        */
        
        // castle amount check
	    assert!(core::allow_new_castle(size, game_store), ECastleAmountLimit);
        /* 
        There are limits to castle sizes (only X amount of y size castles allowed). This
        assert checks if the user is under that limit. It Calls the allow_new_castle function
        in the core module

        allow_new_castle:
        size -> the size of castle the user wants
        game_store -> the game_store object keeps track of all the castles. It contains a 
        count of all the castle sizes
        return -> boolean to represent if a new castle of this size is allowed

        assert -> true -> pass
        assert -> false -> ECastleAmountLimit
        */

		// castle object UID.
		let mut obj_id = object::new(ctx); // creates a new object and returns the global UID that must be stored in that object
		
		// generate serial number.
		let serial_number = utils::generate_castle_serial_number(size, &mut obj_id); // generates a castle serial niumber that determines what it looks like. Returns a u 64
        let image_id = utils::serial_number_to_image_id(serial_number); // turns this serial number into an image. Returns a string
		
		// new castle object.
		let castle = Castle { // creates a new Castle object
            id: obj_id, // assign the newly created global UID to the castle object
            name: string::utf8(name_bytes), // assigns the name variable vector to the object as a string 
            description: string::utf8(desc_bytes), // assigns the description variable vector to the object as a string 
            serial_number: serial_number, // assigns the serial number to the object as a string 
            image_id: image_id, // assigns the image id to the object as a string 
        };

        // new castle game data
        let id = object::uid_to_inner(&castle.id);
        /*
        interestingly the difference between UID and ID is that UID's are globally unique in SUI's storage, but
        ID is not. ID is a reference to SUI objects, but is not guaranteed to be globally unique. Anyone can 
        create an ID from a UID or object and they can be copied or dropped. Knowing that:

        uid_to_inner takes a castle &UID and gives us an ID which we store in the id field. Remember ID can be copied. 
        It's very handy for making references to objects. You'll see below that we're adding this id field to the castle data,
        which is how we know what castle data object belongs to what castle object
        */

        let race = get_castle_race(serial_number); // derives the castle race from the serial number
        core::init_castle_data( // this is how we create the castle data object
            id, // the castle id
            size, // size of the castle
            race, // the castle's race
            clock::timestamp_ms(clock), // this returns the current timestamp im ms. This is used to record when the object was created
            game_store // the gamestore object. We have to parse it because it serves as a certral repo
        );
        
        
        let owner = tx_context::sender(ctx); // get the owner address from the TxContext
		transfer::public_transfer(castle, owner); // transfer newly create castle object to the owner
        event::emit(CastleBuilt{id: id, owner: owner}); // emit an event with the object id and owner address
	}

    /// Transfer castle
    entry fun transfer_castle(castle: Castle, to: address) { 
        /*
        Transfers the Castle object to an address

        castle: Castle -> the actual castle object, not a reference
        to: address -> the address that we want to transfer to

        Note that a user has to own the object in order to transfer it
        */
        transfer::transfer(castle, to); // the transfer module where the actual transfer happens
    }
    
    /// Settle castle's economy
    entry fun settle_castle_economy(castle: &mut Castle, clock: &Clock, game_store: &mut GameStore) {
        /*
        Calls the core module to settle the castle economy

        castle: &mut Castle -> mutable reference to the castle object
        clock: &Clock -> reference to the clock module
        game_store: &mut GameStore -> mutable reference to the GameStore
        */
        core::settle_castle_economy(object::id(castle), clock, game_store);
    }
    
    /// Castle uses treasury to recruit soldiers
    entry fun recruit_soldiers (castle: &mut Castle, count: u64, clock: &Clock, game_store: &mut GameStore) {
        /*
        Calls the core module to recruit soldiers for the castle

        castle: &mut Castle -> mutable reference to the castle object
        count: u64 -> number of soldiers a user wants to recruit
        clock: &Clock -> reference to the clock module
        game_store: &mut GameStore -> mutable reference to the GameStore
        */
        core::recruit_soldiers(object::id(castle), count, clock, game_store);
        // object::id(castle) -> gets the underlying ID of the castle
    }

    /// Upgrade castle
    entry fun upgrade_castle(castle: &mut Castle, game_store: &mut GameStore) {
        /*
        Calls the core module to upgrade the castle

        castle: &mut Castle -> mutable reference to the castle object
        game_store: &mut GameStore -> mutable reference to the GameStore
        */
        core::upgrade_castle(object::id(castle), game_store);
        // object::id(castle) -> gets the underlying ID of the castle
    }

    /// Get castle race
    public fun get_castle_race(serial_number: u64): u64 {
        /*
        helper function to derive the reace of a castle from a serial number  

        The last digit of the serial number represents the race
        so for 123453 the race would be 3. If we take the 
        serial number % 10 we move the comma to the left and 
        get the last number as a remainder  so 123453 would be
        12345,3 thus 3 is our remainder

        The if exists because there are only 5 races represented as 0...4, thus 
        we need to account for numbers inlcuding 5...9 
        */

        let mut race_number = serial_number % 10;
        if (race_number >= 5) { 
            race_number = race_number - 5;
        };
        race_number
    }

}