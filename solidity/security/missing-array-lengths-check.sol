pragma solidity ^0.8.0;

contract ArrayLength {

    function completeQueuedWithdrawals(
        //ok: missing-array-lengths-check
        QueuedWithdrawal[] calldata queuedWithdrawals,
        //ok: missing-array-lengths-check
        uint256[] calldata middlewareTimesIndexes,
        //ok: missing-array-lengths-check
        bytes32[] calldata validatorFields
    ) external
    {
        for(uint256 i = 0; i < queuedWithdrawals.length; i++) {
            _completeQueuedWithdrawal(queuedWithdrawals[i], tokens[i], middlewareTimesIndexes[i], receiveAsTokens[i]);
        }

        require(queuedWithdrawals.length == middlewareTimesIndexes.length, "different lengths");
        require(middlewareTimesIndexes.length == queuedWithdrawals.length, "different lengths");
        

    }


    function verifyAndProcessWithdrawal(
        BeaconChainProofs.WithdrawalProofs calldata withdrawalProofs, 
        bytes calldata validatorFieldsProof,
        //ruleid: missing-array-lengths-check
        bytes32[] calldata validatorFields,
        //ruleid: missing-array-lengths-check
        bytes32[] calldata withdrawalFields,
        //ruleid: missing-array-lengths-check
        uint256[] beaconChainETHStrategyIndex,
        uint64 oracleBlockNumber
    )
        external
    {

        uint40 validatorIndex = uint40(Endian.fromLittleEndianUint64(withdrawalFields[BeaconChainProofs.WITHDRAWAL_VALIDATOR_INDEX_INDEX]));
        
        require(validatorStatus[validatorIndex] != VALIDATOR_STATUS.INACTIVE,
            "EigenPod.verifyOvercommittedStake: Validator never proven to have withdrawal credentials pointed to this contract");

        bytes32 beaconStateRoot = eigenPodManager.getBeaconChainStateRoot(oracleBlockNumber);

        BeaconChainProofs.verifyWithdrawalProofs(beaconStateRoot, withdrawalProofs, withdrawalFields);
        BeaconChainProofs.verifyValidatorFields(validatorIndex, beaconStateRoot, validatorFieldsProof, validatorFields);

        uint64 withdrawalAmountGwei = Endian.fromLittleEndianUint64(withdrawalFields[BeaconChainProofs.WITHDRAWAL_VALIDATOR_AMOUNT_INDEX]);

        //check if the withdrawal occured after mostRecentWithdrawalBlockNumber
        uint64 slot = Endian.fromLittleEndianUint64(withdrawalProofs.slotRoot);

        (validatorFields[BeaconChainProofs.VALIDATOR_WITHDRAWABLE_EPOCH_INDEX]);
        if (Endian.fromLittleEndianUint64(validatorFields[BeaconChainProofs.VALIDATOR_WITHDRAWABLE_EPOCH_INDEX]) <= slot/BeaconChainProofs.SLOTS_PER_EPOCH) {
            _processFullWithdrawal(withdrawalAmountGwei, validatorIndex, beaconChainETHStrategyIndex, podOwner, validatorStatus[validatorIndex]);
        } else {
            _processPartialWithdrawal(slot, withdrawalAmountGwei, validatorIndex, podOwner);
        }
    }

    function addChainlinkOracles(
        //ok: missing-array-lengths-check
        address[] memory tokens,
        //ok: missing-array-lengths-check
        address[] memory oracles,
        //ok: missing-array-lengths-check
        uint48[] memory heartbeats
    ) external {
        if (tokens.length != oracles.length || oracles.length != heartbeats.length) {
            revert InvalidLength();
        }
        // ...
    }

}