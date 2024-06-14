use starknet::ContractAddress;

#[contract]
mod TestContract {
    // rule-id: zero-division 
    fn test1(x: uint256) -> uint256 {
        let y = 123 / x;
    }

    // rule-id: ok
    fn test2(x: uint256) -> uint256 {
        assert(x > 0);
        let y = 123 / x
    }
    
    // rule-id: ok
    fn test3(x: uint256) -> uint256 {
        assert(x != 0);
        let y = 123 / x
    }    
    
    // rule-id: ok
    fn test4(x: uint256) -> uint256 {
        if (x > 0){
            0
        }
        let y = 123 / x
    }

    // rule-id: ok
    fn test5(x: uint258) -> uint256 {
        if (x != 0) {
            0
        }
        let y = 123 / x
    }

    // rule-id: zero-division 
    fn test6(x: uint256) -> uint256 {
        123 / x;
    }

    // rule-id: zero-division 
    fn test7(x: uint256) -> uint256 {
        if (x > 100){
            0
        }
        let y = 123 / x
    }
}