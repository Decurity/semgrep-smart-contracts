// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Example_1 {
    function setUint() public returns(uint256) {
        // ruleid: init-counter-in-loop-with-default-value
        for (uint256 i=0; i<5;++i) {
            // ...
        }
    }
}

contract Example_2 {
    function setUint() public returns(uint256) {
        // ok: init-counter-in-loop-with-default-value
        for (uint256 i; i<5;++i) {
            // ...
        }
    }
}

contract Example_3 {
    function setUint() public returns(uint256) {
        // ok: init-counter-in-loop-with-default-value
        for (uint256 i = 1; i<5;) {
            // ...
            ++i;
        }
    }
}

contract Example_4 {
    function setUint() public returns(uint256) {
        // ruleid: init-counter-in-loop-with-default-value
        for (uint256 i = 0; i<5;) {
            // ...
            ++i;
        }
    }
}

