pragma solidity >=0.7.4;

uint constant X = 32**22 + 8;

//ruleid: non-immutable-state-variable
contract T1{
    uint v1 = 1;

    function test() public{
        return true;
    }
}

//ok: non-immutable-state-variable
contract T2{
    uint v1 = 1;

    function test() public{
        v1 = v1 + 1;
    }
}

//ok: non-immutable-state-variable
contract T3{
    uint v1 = 1;

    function test() public{
        v1 += 1;
    }
}

//ok: non-immutable-state-variable
contract T4{
    uint v1 = 1;

    function test() public{
        v1 -= 1;
    }
}

//ok: non-immutable-state-variable
contract T5{
    uint v1 = 1;

    function test() public{
        v1 /= 1;
    }
}

//ok: non-immutable-state-variable
contract T6{
    uint v1 = 1;

    function test() public{
        v1 *= 1;
    }
}

//ok: non-immutable-state-variable
contract T7{
    uint v1 = 1;

    function test() public{
        v1++;
    }
}

//ok: non-immutable-state-variable
contract T8{
    uint v1 = 1;

    function test() public{
        v1--;
    }
}

//ok: non-immutable-state-variable
contract T9{
    uint v1 = 1;

    constructor(){
        v1--;
    }
}

//ok: non-immutable-state-variable
contract T10{
    uint public immutable v1 = 1;
}

//ok: non-immutable-state-variable
contract T11{
    uint immutable v1 = 1;
}

//ok: non-immutable-state-variable
contract T12{
    uint constant v1 = 1;
}


// semgrep can't catch it correctly now

//ok: non-immutable-state-variable
// contract T13{
//     uint v1 = 1;
// }

// contract T13Child is T12{
//     function test() public{
//         v1 = 2;
//     }
// }





