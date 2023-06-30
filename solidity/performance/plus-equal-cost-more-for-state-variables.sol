// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

contract A {
    uint256[10] public a;
    uint256 public b;
    function one() public {
        a[0] = 4;
        b = 5;
        // ruleid: plus-equal-cost-more-for-state-variables
        a[0] += b;
    }
}


contract B {
    uint256 public a;
    uint256 public b;
    function one() public {
        a = 4;
        b = 5;
        // ok: plus-equal-cost-more-for-state-variables
        a = a + b;
    }
}

contract C {
    uint256 public a = 4;
    uint256 public b;
    function one() public {
        b = 5;
        // ruleid: plus-equal-cost-more-for-state-variables
        a += b;
    }
}

contract D {
    function one() public {
        a = 4;
        b = 5;
        // ok: plus-equal-cost-more-for-state-variables
        a += b;
    }
}

contract E {
    mapping (address => uint) public a;
    function one() public {
        // ok: plus-equal-cost-more-for-state-variables
        a[msg.sender] += 4;
    }
}