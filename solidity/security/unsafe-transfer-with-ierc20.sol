pragma solidity >=0.7.4;

contract Test {
    function payment() public {
        //ruleid: unsafe-transfer-with-ierc20
        IERC20(token0).transfer(msg.sender, refund);
    }

    function payment2() public {
        //ruleid: unsafe-transfer-with-ierc20
        require(IERC20(token0).transfer(msg.sender, refund),"error");
    }

    function payment3() public {
        //ruleid: unsafe-transfer-with-ierc20
        bool success = IERC20(token0).transfer(msg.sender, refund);
    }
}

contract Test2 { 
    IERC20 token0 = address(0);
    function payment() public {
        //ruleid: unsafe-transfer-with-ierc20
        token0.transfer(msg.sender, refund);
    }
}

contract Test3 { 
    IERC20 token0;
    constructor() {
        token0 = address(0);
    }
    function payment() public {
        //ruleid: unsafe-transfer-with-ierc20
        token0.transfer(msg.sender, refund);
    }
}