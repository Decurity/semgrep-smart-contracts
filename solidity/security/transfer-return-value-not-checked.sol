pragma solidity >=0.7.4;

contract Test{
    function payment() public {
        //ok: transfer-return-value-not-checked
        bool kek = IERC20(token0).transfer(msg.sender, refund);
    }

    function payment2() public {
        //ok: transfer-return-value-not-checked
        require(IERC20(token0).transfer(msg.sender, refund), "error");
    }

    function payment3() public {
        //ruleid: transfer-return-value-not-checked
        IERC20(token0).transfer(msg.sender, refund);
    }


    function payment4() public {
        //ok: transfer-return-value-not-checked
        if(IERC20(token0).transfer(msg.sender, refund)) {
            //proccess
        } else {
            revert("error");
        }
    }
}


contract Test5 {
    IWETH9 weth = address(0);
    function sendWETHT(address to, uint256 amount) private {
        //ok: transfer-return-value-not-checked
        IWETH9(weth).transfer(to, amount);
    }
}