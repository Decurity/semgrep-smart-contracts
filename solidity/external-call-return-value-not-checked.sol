pragma solidity ^0.8.17;

contract Test {
    function setVars(address _contract, uint _num) public payable {
        
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
        (bool success3, bytes memory data) = _contract.staticcall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        if (success3 != 0) revert();

        // ok: external-call-return-value-not-checked
        (bool success4, bytes memory data) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        if (success4){
            revert;
        }
        // ok: external-call-return-value-not-checked
        bool success5 = _contract.send(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        if (success5 == 0) revert();

        
    }

    function setVars2(address _contract, uint _num) public payable {
        // ruleid: external-call-return-value-not-checked
         _contract.delegetecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        // ruleid: external-call-return-value-not-checked
        (bool success, bytes memory data) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        
        // ruleid: external-call-return-value-not-checked
        bool success = _contract.send(1 ether);
    }
}
