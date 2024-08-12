use starknet::ContractAddress;

#[starknet::contract]
mod TestContract {
    fn test1() {
        let a = 1;
        // ok: lack-of-error-message
        assert(a == 1, 'message');
    }

    fn test2() {
        let a = 1;
        // ruleid: lack-of-error-message 
        assert(a == 1);
    }

    fn test3() {
        // ok: lack-of-error-message
        assert('msg1' != 'msg2', 'message');
    }

    fn test4() {
        // ruleid: lack-of-error-message 
        assert('msg1' != 'msg2');
    }
}