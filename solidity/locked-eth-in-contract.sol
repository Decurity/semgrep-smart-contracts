pragma solidity 0.8.13;

// ruleid: locked-eth-in-contract
contract Test1 {
    receive() external payable {}
}

// ruleid: locked-eth-in-contract
contract Test2 {
    bool flag;
    function get(bool payed) external payable {
        if (msg.value > 0){
            flag = true;
        }
    }
}

// ok: locked-eth-in-contract
contract Test3 {
    receive() external payable {}

    function skim(address payable to) external{
        to.send(this(address).balance);
    }
}

// ok: locked-eth-in-contract
contract Test4 {
    receive() external payable {}

    function skim(address payable to) external{
        to.transfer(this(address).balance);
    }
}

// ok: locked-eth-in-contract
contract Test5 {
    receive() external payable {}

    function destruct(address payable to) external{
        selfdestruct(to);
    }
}

// ruleid: locked-eth-in-contract
contract Test6 {
    receive() external payable {}

    function skim(address payable to) external{
        to.call(...);
    }
}

// ok: locked-eth-in-contract
contract Test7 {
    receive() external payable {}

    function skim(address payable to) external{
        (bool sent, bytes memory data) = to.call{value: msg.value}("");
    }
}