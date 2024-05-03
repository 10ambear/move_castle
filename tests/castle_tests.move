#[test_only]
module move_castle::castle_tests {

    #[test]
    fun sample_test() {
        let result = 1 + 2;
        assert!(result == 3, 0);
    }

    #[test]
    fun integer_test() {
        // define variables and set their types
        let a: u8 = 8;
        let b: u16 = 18;
        let c: u32 = 188;
        let d: u64 = 1888;
        // assign variable with defined value type
        let g = 100u64;

        // same integer type can be compared
        assert!(d > g, 0);

        // different types comparison would cause compilation error
        assert!(a < (b as u8), 0); // Compile error!

        // math operation between different types is also not allowed
        assert!(a + (b as u8) > 0, 0); // Compile error!

        // or you can compare to a direct value with out a type
        assert!(c < 200, 0);
    }

     #[test] 
    fun boolean_test() {
       let a: bool = true;
       let b = false;
       assert!(a != b, 0);
    }
}