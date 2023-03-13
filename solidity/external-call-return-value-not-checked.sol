pragma solidity ^0.8.17;

contract Test {
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

        // // ok: external-call-return-value-not-checked
        // (bool success3, bytes memory data) = _contract.staticcall(
        //     abi.encodeWithSignature("setVars(uint256)", _num)
        // );
        // if (success3 != 0) revert();

        // ok: external-call-return-value-not-checked
        (bool success4, bytes memory data) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        if (success4){
            revert();
        }
        // // ok: external-call-return-value-not-checked
        // bool success5 = _contract.send(_num);
        // if (success5 == 0) revert();

        // ok: external-call-return-value-not-checked
        (bool success6, ) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        require(success6 && 1 == 1, "Error");

        // ok: external-call-return-value-not-checked
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));

        // ok: external-call-return-value-not-checked    
        (bool sendBackSuccess, ) = payable(msg.sender).call{value: address(this).balance}('');
        require(sendBackSuccess, 'Could not send remaining funds to the payer');
    }

    // function setVars2(address payable _contract, uint _num) public payable {
    //     // ruleid: external-call-return-value-not-checked
    //      _contract.call(abi.encodeWithSignature("setVars(uint256)", _num));
    // }

    function setVars3(address payable _contract, uint _num) public payable {
        // ruleid: external-call-return-value-not-checked
        (bool success1, bytes memory data) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }

    // function setVars4(address payable _contract, uint _num) public payable {
    //     // ruleid: external-call-return-value-not-checked
    //     bool success2 = _contract.send(1 ether);

    // }
    
    function setVars5() public payable{
        // ok: external-call-return-value-not-checked 
        (bool success1, bytes memory data) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        return success1 && 1 == 1;
    }
    
    function withdrawTaxBalance_() external nonReentrant onlyOwner {
        (bool temp1, ) = payable(solidityDevWallet).call{
            value: (taxBalance * solidityDevShare) / SHAREDIVISOR
        }("");
        (bool temp2, ) = payable(frontendDevWallet).call{
            value: (taxBalance * frontendDevShare) / SHAREDIVISOR
        }("");
        (bool temp3, ) = payable(projectLeadWallet).call{
            value: (taxBalance * projectLeadShare) / SHAREDIVISOR
        }("");
        (bool temp4, ) = payable(apeHarambeWallet).call{
            value: (taxBalance * apeHarambeShare) / SHAREDIVISOR
        }("");

        // ok: external-call-return-value-not-checked 
        (bool temp5, ) = payable(treasuryWallet).call{
            value: (taxBalance * treasuryShare) / SHAREDIVISOR
        }("");
        assert(temp1 && temp2 && temp3 && temp4 && temp5);
        taxBalance = 0;
    }
}
