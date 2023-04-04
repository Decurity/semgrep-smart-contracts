pragma solidity 0.8.15;


//ruleid: non-payable-constructor
contract Test1{
    constructor(){}
}

//ok: non-payable-constructor
contract Test2{
    constructor() payable{}
}

//ok: non-payable-constructor
abstract contract Test3{
    constructor(){}
}