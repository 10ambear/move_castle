module move_castle::utils { // this represents the package and the module <package>::<module>
    use std::string::{Self, String}; // adds the String module, the utf8 function and the String struct. We'll be using this to easily `deal` with strings
    use std::hash; // a module that gives us the power to has stuff


    /// Generating the castle's serial number.
    public fun generate_castle_serial_number(size: u64, id: &mut UID): u64 {
         // This function generates the serial number used by the protocol to create castle attributes 

        let mut hash = hash::sha2_256(object::uid_to_bytes(id)); // takes the object id as bytes and hashes it. This hash is a vector<u8>; 
        // We have to do this conversion because `uid_to_bytes` takes a vector<u8> as a parameter

        let mut result_num: u64 = 0; // instantiates a mutable result_num variable

        while (vector::length(&hash) > 0) { // loops through the hash vector<u8>;
            let element = vector::remove(&mut hash, 0); // takes an 'i' element out of the hash, we start with 0 (the first element)
            result_num = ((result_num << 8) | (element as u64));
            /*
            so there are 3 parts to this

            result_num << 8:
            this adds bits to the end of a result_num
            so if result_num is 10111 it'll be 0000000010111

            element as u64:
            casts the element as a u64 so that we can use the bitwise OR

            bitwise OR represented as |
            an example would be:
                 a -> 10110001
                 b -> 00001111
            result -> 10111111

            The point? To create an `unique` integer from a sequence of bytes
            */

        };

        result_num = result_num % 100000u64; // only get the last 5 digits
        // 12345 % 10 = 1234.5 = 5 
        // 12345 % 100= 123.45 = 45 
        // up to 100000 ...  

       
        size * 100000u64 + result_num 
        /* 
            essentially adds the size to the result_num since the size was known before
            we generated the rest of the serial 
            
            size = 3
            result num = 12345
            result = 312345
        */
    }

    public fun serial_number_to_image_id(serial_number: u64): String { // takes a u64 serial number and returns a string. We use this to generate the images
        let id = serial_number / 10 % 10000u64;
        /* 
            this line works in 2 parts. Let's say the serial is 123456

            123456 / 10 = 12345.6 but since it's a uint it'll truncate to 12345
            now we take 12345 % 10000u64 = 2345 

            We do this because the middle part of the serial number is used to generate the image

        */
        u64_to_string(id, 4) // cast the id to a string
    }

    public fun abs_minus(a: u64, b: u64): u64 { // takes in 2 uints, returns a uint. This function returns the difference between two u64's 
        let result; // instantiate a variable 
        if (a > b) { // if a is bigger 
            result = a - b; // make the result the difference 
        } else { // if b is bigger
            result = b - a;// make the result the difference 
        };
        result // return the result
    }

    public fun random_in_range(range: u64, ctx: &mut TxContext):u64 { // takes a range as uint and a TxContext. This function is very similar to `generate_castle_serial_number` but you can choose the range/size
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


            The point? To create an `unique` integer from a sequence of bytes
            */
        };
        result_num = result_num % range; // takes the integer we just created and gets a result based on the range
        // 12345 % 10 = 1234.5 = 5 
        // 12345 % 100= 123.45 = 45 
        // and so on ...  

        result_num // returns a piece if the integer based on the range
    }
    
    /// convert u64 to string, if length < fixed length, prepend "0"
    public fun u64_to_string(mut n: u64, fixed_length: u64): String { // takes a mutable uint + uint to represent length
        let mut result: vector<u8> = vector::empty<u8>(); // instantiate an emprty vector array
        if (n == 0) { // if n is zero 
            vector::push_back(&mut result, 48); // push the ascii value of 0 to the end of the vector
        } else {
            while (n > 0) { // if n is more than 0 loop through the numner (we start at the last digit)
                let digit = ((n % 10) as u8) + 48; // this converts a single digit number into ASCII
                /*
                Here's a breakdown of what each part does:

                - n % 10: This operation finds the remainder of n divided by 10. 
                This effectively isolates the last digit of n. For example, if n is 123, n % 10 would be 3.

                - as u8: This part casts the result of n % 10 to an unsigned 8-bit integer (u8). 
                This is necessary because the ASCII values of digits are represented as u8 in the Move language.

                - + 48: This adds 48 to the result of the previous step. 
                The ASCII value of the digit '0' is 48, so adding 48 to the ASCII value of a digit converts it 
                into its ASCII representation. For example, the ASCII value of '0' is 48, '1' is 49, '2' is 50, and so on.

                - let digit = ...: This assigns the result of the operations to a variable named digit. 
                The variable digit now holds the ASCII representation of the last digit of n.
                
                */


                vector::push_back(&mut result, digit); // add the digit to the last position of the result vector
                n = n / 10; // this removes the last digit from the number so 123 / 10 = 12 (truncate)
            };

            // add "0" at the string front util fixed length.
            while (vector::length(&result) < fixed_length) { // if the result vector is smaller than the fixed length add zeros 
                vector::push_back(&mut result, 48); // add the zero to the end 123 -> 123000
            };

            vector::reverse<u8>(&mut result); // reverse the order of the elements 123000 -> 000321
        };
        string::utf8(result) // creates a string from a sequence of bytes
    }

}