pragma solidity >=0.7.4;



contract T1{
    //ruleid: state-variable-can-be-set-to-immutable
    uint v1 = 1;

    function test() public{
        return true;
    }
}

contract T2{
    //ok: state-variable-can-be-set-to-immutable
    uint v1 = 1;

    function test() public{
        v1 = v1 + 1;
    }
}

contract T3{
    //ok: state-variable-can-be-set-to-immutable
    uint v1 = 1;

    function test() public{
        v1 += 1;
    }
}

contract T4{
    //ok: state-variable-can-be-set-to-immutable
    uint v1 = 1;

    function test() public{
        v1 -= 1;
    }
}

contract T5{
    //ok: state-variable-can-be-set-to-immutable
    uint v1 = 1;

    function test() public{
        v1 /= 1;
    }
}

contract T6{
    //ok: state-variable-can-be-set-to-immutable
    uint v1 = 1;

    function test() public{
        v1 *= 1;
    }
}

contract T7{
    //ok: state-variable-can-be-set-to-immutable
    uint v1 = 1;

    function test() public{
        v1++;
    }
}

contract T8{
    //ok: state-variable-can-be-set-to-immutable
    uint v1 = 1;

    function test() public{
        v1--;
    }
}

contract T9{
    //ok: state-variable-can-be-set-to-immutable
    uint v1 = 1;

    constructor(){
        v1--;
    }
}


contract T10{
    //ok: state-variable-can-be-set-to-immutable
    uint public immutable v1 = 1;
}

contract T11{
    //ok: state-variable-can-be-set-to-immutable
    uint immutable v1 = 1;
}

contract T12{
    //ok: state-variable-can-be-set-to-immutable
    uint constant v1 = 1;
}



// semgrep can't catch it correctly now


// contract T13{
//     //ok: state-variable-can-be-set-to-immutable
//     uint v1 = 1;
// }

// contract T13Child is T12{
//     function test() public{
//         v1 = 2;
//     }
// }



contract T14{
    //ok: state-variable-can-be-set-to-immutable
    uint v1 = 5;
    function kek() {
        v1%=10;
    }
}