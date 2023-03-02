contract Foobar {
    function doit1(address ext) {
        // ruleid: exact-balance-check
        require(
        	1==1 &&
        	(IERC20(ext).balanceOf(address(this)) == 1337) ||
        	1==2,
        	"Wrong balance!"
        );
        // do smth
    }
    
    function doit2(address ext) {
        require(
            1==1 &&
            (address(ext).balance == 1337) ||
            1==2,
            "Wrong balance!"
        );
        // do smth
    }

    function doit_safe(address ext) {
        // ok: exact-balance-check
        require(
            1==1 &&
            (IERC20(ext).balanceOf(address(this)) >= 1337) ||
            1==2,
            "Wrong balance!"
        );
        // do smth
    }

    function doit2_safe(address ext) {
        require(
            1==1 &&
            (address(ext).balance <= 1337) ||
            1==2,
            "Wrong balance!"
        );
        // do smth
    }
}
