contract Vuln {
    function f() isBridge {
        msg.sender.call.value(5 ether)("");
    }
    function f(address a) onlyOwner {
        a.call.value(5 ether)("");
    }
    function fn() private {
        msg.sender.call.value(5 ether)("");
    }
    function fbb() {
        address a = msg.sender;
        a.call{value:5}("ff");
    }
    function fcc() nonReentrant {
        msg.sender.call{value: msg.value}("");
    }
}
