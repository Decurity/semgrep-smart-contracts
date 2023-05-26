pragma solidity 0.8.19;

contract Test {
    function func() external {
        //ruleid: PRNG-based-on-block-variables
        uint256 rand1 = uint256(
            keccak256(abi.encode(blockhash(block.number - 1), block.timestamp))
        );

        //ruleid: PRNG-based-on-block-variables
        uint256 rand2 = uint256(
            keccak256(abi.encode(blockhash(block.number)))
        );

        //ruleid: PRNG-based-on-block-variables
        uint256 rand3 = block.number % 31337;

        //ruleid: PRNG-based-on-block-variables
        uint256 rand4 = uint256(
            keccak256(abi.encode(block.difficulty))
        );

        //ruleid: PRNG-based-on-block-variables
        uint256 rand5 = uint256(
            keccak256(abi.encode(block.gaslimit))
        );

        bytes memory randomBytes = abi.encodePacked(block.number, msg.sender);
        uint randomNumber = uint(keccak256(randomBytes));
        //ruleid: PRNG-based-on-block-variables
        uint rand6 = randomNumber % 31337;
    }
}
