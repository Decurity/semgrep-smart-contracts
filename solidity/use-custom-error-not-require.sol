// SPDX-License-Identifier: UNLICENSED
// ruleid: use-custom-error-not-require
pragma solidity ^0.8.5;

contract TestRequiere {
    function test(uint256 a) public {
        require(a>10, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"); // "a"*33
    }
}