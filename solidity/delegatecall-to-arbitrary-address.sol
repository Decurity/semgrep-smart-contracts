pragma solidity 0.8.0;


contract Test{
    function func1(address _contract, uint256 _num) external{
        //ruleid: delegatecall-to-arbitrary-address
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }

    function func2(address payable _contract, uint256 _num) public{
        //ruleid: delegatecall-to-arbitrary-address
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }

    function func3(uint256 useless, address  _contract, uint256 _num) external{
        //ruleid: delegatecall-to-arbitrary-address
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}