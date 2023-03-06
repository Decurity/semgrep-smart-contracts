pragma solidity ^0.8.17;

contract Test {
    bool flag;
    function setVars(address payable _contract, uint _num) public payable {

        // ok: external-call-return-value-not-checked
        (bool success, ) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        require(success, "Error");

        // ok: external-call-return-value-not-checked
        (bool success2, ) = _contract.staticcall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        if (!success2) revert();

        // ok: external-call-return-value-not-checked
        (bool success3, bytes memory data) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        if (success3){
            ok();
        }

        // ok: external-call-return-value-not-checked
        (bool success4, ) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        if (success4 && 1 == 1){
            ok();
        }

        // ok: external-call-return-value-not-checked
        (bool success5, ) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        if (!success5 || 0 == 0){
            revert();
        }


    }

    function setVars2(address payable _contract, uint _num) public payable {
        // ruleid: external-call-return-value-not-checked
         _contract.call{value: 1337}(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        // ruleid: external-call-return-value-not-checked
         _contract.call{gas: 1337}(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        // ruleid: external-call-return-value-not-checked
        _contract.call{value: msg.value, gas: 5000}(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        // ruleid: external-call-return-value-not-checked
        _contract.call{gas: 5000, value: msg.value}(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        // ruleid: external-call-return-value-not-checked
        (bool success1, bytes memory data) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        

        // ruleid: external-call-return-value-not-checked
        bool success2 = _contract.send(1 ether);
    }

    function ok() public{
        flag = true;
    }
}