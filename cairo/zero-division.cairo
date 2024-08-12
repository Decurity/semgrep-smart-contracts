use starknet::ContractAddress;

#[starknet::contract]
mod TestContract {
    fn test1(x: uint256) -> uint256 {
        // ruleid: zero-division 
        let y = 123 / x;
    }

    fn test2(x: uint256) -> uint256 {
        assert(x > 0);
        // ok: zero-division 
        let y = 123 / x
    }
    
    fn test3(x: uint256) -> uint256 {
        assert(x != 0);
        // ok: zero-division 
        let y = 123 / x
    }    
    
    fn test4(x: uint256) -> uint256 {
        if (x > 0){
            0
        }
        // ok: zero-division 
        let y = 123 / x
    }

    fn test5(x: uint258) -> uint256 {
        if (x != 0) {
            0
        }
        // ok: zero-division 
        let y = 123 / x
    }

    fn test6(x: uint256) -> uint256 {
        // ruleid: zero-division 
        123 / x;
    }

    fn test7(x: uint256) -> uint256 {
        if (x > 100){
            0
        }
        // ruleid: zero-division 
        let y = 123 / x
    }
}