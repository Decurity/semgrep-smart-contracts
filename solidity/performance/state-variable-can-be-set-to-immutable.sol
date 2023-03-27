pragma solidity >=0.7.4;


//ruleid: state-variable-can-be-set-to-immutable
contract T1{
    uint v1 = 1;

    function test() public{
        return true;
    }
}

//ok: state-variable-can-be-set-to-immutable
contract T2{
    uint v1 = 1;

    function test() public{
        v1 = v1 + 1;
    }
}

//ok: state-variable-can-be-set-to-immutable
contract T3{
    uint v1 = 1;

    function test() public{
        v1 += 1;
    }
}

//ok: state-variable-can-be-set-to-immutable
contract T4{
    uint v1 = 1;

    function test() public{
        v1 -= 1;
    }
}

//ok: state-variable-can-be-set-to-immutable
contract T5{
    uint v1 = 1;

    function test() public{
        v1 /= 1;
    }
}

//ok: state-variable-can-be-set-to-immutable
contract T6{
    uint v1 = 1;

    function test() public{
        v1 *= 1;
    }
}

//ok: state-variable-can-be-set-to-immutable
contract T7{
    uint v1 = 1;

    function test() public{
        v1++;
    }
}

//ok: state-variable-can-be-set-to-immutable
contract T8{
    uint v1 = 1;

    function test() public{
        v1--;
    }
}

//ok: state-variable-can-be-set-to-immutable
contract T9{
    uint v1 = 1;

    constructor(){
        v1--;
    }
}

//ok: state-variable-can-be-set-to-immutable
contract T10{
    uint public immutable v1 = 1;
}

//ok: state-variable-can-be-set-to-immutable
contract T11{
    uint immutable v1 = 1;
}

//ok: state-variable-can-be-set-to-immutable
contract T12{
    uint constant v1 = 1;
}


// semgrep can't catch it correctly now

//ok: state-variable-can-be-set-to-immutable
// contract T13{
//     uint v1 = 1;
// }

// contract T13Child is T12{
//     function test() public{
//         v1 = 2;
//     }
// }





