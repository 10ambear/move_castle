module move_castle::utils { // this represents the package and the module <package>::<module>
    use std::string::{Self, String}; // adds the String module, the utf8 function and the String struct
    use std::hash; // a module that hashes stuff 


    /// Generating the castle's serial number.
    public fun generate_castle_serial_number(size: u64, id: &mut UID): u64 {
         // This function generates the serial number used by the protocol to create castle attributes 

        let mut hash = hash::sha2_256(object::uid_to_bytes(id)); // takes the object id as bytes and hashes it. This hash is a vector<u8>; 

        let mut result_num: u64 = 0; // instantiates a mutable result_num variable

        while (vector::length(&hash) > 0) { // loops through the vector<u8>;
            let element = vector::remove(&mut hash, 0); // takes an element out of the vector
            result_num = ((result_num << 8) | (element as u64));
            /*
            so there are 3 parts to this

            result_num << 8:
            this adds bits to the end of a result_num
            so if resultnum is 10111 it'll be 0000000010111

            element as u64:
            casts the element as a u64 so that we can use the bitwise OR

            bitwise OR represented as |
            an example would be:
                 a -> 10110001
                 b -> 00001111
            result -> 10111111


            The point? To create an integer from a sequence of bytes yay
            */

        };

        result_num = result_num % 100000u64; // only get the last 5 digits

       
        size * 100000u64 + result_num 
        // essentially adds the size to the result_num since the size was known before
        // we generated the rest of the serial
    }

    public fun serial_number_to_image_id(serial_number: u64): String { // takes a u64 serial number and returns a string
        let id = serial_number / 10 % 10000u64;
        /* 
            this line works in 2 parts. Let's say the serial is 123456

            123456 / 10 = 12345.6 but since it's a uint it'll truncate to 12345
            now we take 12345 % 10000u64 = 2345 

            We do this because the middle part of the serial number is used to generate the image

        */
        u64_to_string(id, 4) // cast the id to a string
    }

    public fun abs_minus(a: u64, b: u64): u64 { // takes in 2 uints, returns a uint
        let result; // instantiate a variable 
        if (a > b) { // if a is bigger 
            result = a - b; // make the result the difference 
        } else { // if b is bigger
            result = b - a;// make the result the difference 
        };
        result // return the result
    }

    public fun random_in_range(range: u64, ctx: &mut TxContext):u64 { // takes a range as uint and a TxContext
        let uid = object::new(ctx); // creates a new object and returns the uid 
        let mut hash = hash::sha2_256(object::uid_to_bytes(&uid)); // gets a sha256 hash of the object, this returns a vector<u8>;
        object::delete(uid); // deletes the object via it's uid

        let mut result_num: u64 = 0; // instantiate a variable
        while (vector::length(&hash) > 0) { // loops through each element of the hash
            let element = vector::remove(&mut hash, 0); // takes an element out of the vector
            result_num = (result_num << 8) | (element as u64);
            /*
            so there are 3 parts to this

            result_num << 8:
            this adds bits to the end of a result_num
            so if resultnum is 10111 it'll be 0000000010111

            element as u64:
            casts the element as a u64 so that we can use the bitwise OR

            bitwise OR represented as |
            an example would be:
                 a -> 10110001
                 b -> 00001111
            result -> 10111111


            The point? To create an integer from a sequence of bytes yay
            */
        };
        result_num = result_num % range; // takes the integer we just created and gets a result based on the range

        result_num // returns a piece if the integer based on the range
    }
    
    /// convert u64 to string, if length < fixed length, prepend "0"
    public fun u64_to_string(mut n: u64, fixed_length: u64): String {
        let mut result: vector<u8> = vector::empty<u8>();
        if (n == 0) {
            vector::push_back(&mut result, 48);
        } else {
            while (n > 0) {
                let digit = ((n % 10) as u8) + 48;
                vector::push_back(&mut result, digit);
                n = n / 10;
            };

            // add "0" at the string front util fixed length.
            while (vector::length(&result) < fixed_length) {
                vector::push_back(&mut result, 48);
            };

            vector::reverse<u8>(&mut result);
        };
        string::utf8(result)
    }










}