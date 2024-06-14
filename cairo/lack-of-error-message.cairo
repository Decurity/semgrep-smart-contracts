use starknet::ContractAddress;

#[contract]
mod TestContract {
    // rule-id: ok
    fn test1() {
        let a = 1;
        assert(a == 1, 'message');
    }

    // rule-id: lack-of-error-message 
    fn test2() {
        let a = 1;
        assert(a == 1);
    }

    // rule-id: ok
    fn test3() {
        assert('msg1' != 'msg2', 'message');
    }

    // rule-id: lack-of-error-message 
    fn test4() {
        assert('msg1' != 'msg2');
    }
}