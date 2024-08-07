use starknet::ContractAddress;

#[contract]
mod TestContract {
    // ruleid: zero-division 
    fn test1(x: uint256) -> uint256 {
        let y = 123 / x;
    }

    // ok: zero-division 
    fn test2(x: uint256) -> uint256 {
        assert(x > 0);
        let y = 123 / x
    }
    
    // ok: zero-division 
    fn test3(x: uint256) -> uint256 {
        assert(x != 0);
        let y = 123 / x
    }    
    
    // ok: zero-division 
    fn test4(x: uint256) -> uint256 {
        if (x > 0){
            0
        }
        let y = 123 / x
    }

    // ok: zero-division 
    fn test5(x: uint258) -> uint256 {
        if (x != 0) {
            0
        }
        let y = 123 / x
    }

    // ruleid: zero-division 
    fn test6(x: uint256) -> uint256 {
        123 / x;
    }

    // ruleid: zero-division 
    fn test7(x: uint256) -> uint256 {
        if (x > 100){
            0
        }
        let y = 123 / x
    }
}