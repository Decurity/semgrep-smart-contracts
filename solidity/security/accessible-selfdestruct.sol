pragma solidity 0.8.19;

contract Test{
    function func1(address to) external{
        //ruleid: accessible-selfdestruct
        selfdestruct(to);
    }

    function func2(address tmp, address to) public{
        //ruleid: accessible-selfdestruct
        selfdestruct(to);
    }

    function func3(address tmp, address tmp1, address to) public{
        //ruleid: accessible-selfdestruct
        selfdestruct(to);
    }

    function func4(address tmp, address tmp1, address tmp3, address to) external{
        //ruleid: accessible-selfdestruct
        selfdestruct(to);
    }

    function func5(address to) public{
        address payable addr = payable(to);
        //ruleid: accessible-selfdestruct
        selfdestruct(addr);
    }

    function func6(address to) public onlyOwner {
        address payable addr = payable(to);
        //ok: accessible-selfdestruct
        selfdestruct(to);
    }

    function func7(address to) external onlyOwner {
        address payable addr = payable(to);
        //ok: accessible-selfdestruct
        selfdestruct(to);
    }
}