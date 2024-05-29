contract Foobar {
    function doit1(address ext) {
        uint256 bal = IERC20(ext).balanceOf(address(this));
        // ok: exact-balance-check
        bal == 1338;
        require(
        	1==1 &&
            // ruleid: exact-balance-check
        	(bal == 1337) ||
        	1==2,
        	"Wrong balance!"
        );
        // do smth
    }

    function doit2(address ext) {
        require(
            1==1 &&
            // ruleid: exact-balance-check
            (address(ext).balance == 1337) ||
            1==2,
            "Wrong balance!"
        );
        // do smth
    }

    function doit3(address ext) {
        require(
            1==1 &&
            // ruleid: exact-balance-check
            (1337 == address(ext).balance) ||
            1==2,
            "Wrong balance!"
        );
        // do smth
    }

    function doit4(address ext) {
        // ruleid: exact-balance-check
        if (address(ext).balance == 1337 && 1 == 1) {
            // do smth
            uint a = 123;
        };
        // do smth
    }

    function doit5(address ext) {
        // ok: exact-balance-check
        if (1==1) {
            // ruleid: exact-balance-check
            bool b = address(ext).balance == 1337;
            if(b) {}
        };
        // do smth
    }

    function doit_safe(address ext) {
        require(
            1==1 &&
            // ok: exact-balance-check
            (IERC20(ext).balanceOf(address(this)) >= 1337) ||
            1==2,
            "Wrong balance!"
        );
        // do smth
    }

    function doit2_safe(address ext) {
        require(
            1==1 &&
            // ok: exact-balance-check
            (address(ext).balance <= 1337) ||
            1==2,
            "Wrong balance!"
        );
        // do smth
    }

}