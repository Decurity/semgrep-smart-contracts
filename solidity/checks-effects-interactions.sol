contract Sample {
    mapping(address => uint) balances;

    function deposit() public payable {
        balances[msg.sender] = msg.value;
    }

    // ok: checks-effects-interactions
    function withdrawSafe(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }

    // ruleid: checks-effects-interactions
    function withdrawUnsafe(uint amount) public {
        require(balances[msg.sender] >= amount);
        msg.sender.transfer(amount);
        balances[msg.sender] -= amount;
    }

    // ruleid: checks-effects-interactions-heuristic
    function withdrawUnsafe2(uint amount) public {
        require(balances[msg.sender] >= amount);
        msg.sender.transfer(amount);
        decreaseBalance(msg.sender, amount);
    }

    function decreaseBalance(address who, uint amount) private {
        balances[who] -= amount;
    }
}