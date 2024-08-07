use starknet::ContractAddress;

#[contract]
mod TestContract {
    // ok: lack-of-error-message
    fn test1() {
        let a = 1;
        assert(a == 1, 'message');
    }

    // ruleid: lack-of-error-message 
    fn test2() {
        let a = 1;
        assert(a == 1);
    }

    // ok: lack-of-error-message
    fn test3() {
        assert('msg1' != 'msg2', 'message');
    }

    // ruleid: lack-of-error-message 
    fn test4() {
        assert('msg1' != 'msg2');
    }
}