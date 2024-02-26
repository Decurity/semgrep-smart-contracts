contract Test {
	// ok: missing-assignment
    struct Kek {
    	// ok: missing-assignment
        mapping(uint256 => uint256) lol;
    }

    // ok: missing-assignment
    function smth(uint256 _id) {
    	// ok: missing-assignment
        Kek puk;
        // ruleid: missing-assignment
        puk.lol[_id];
        // ok: missing-assignment
        uint256 haha = 123;
        // ok: missing-assignment
        haha = 321;
        // ruleid: missing-assignment
        haha;
        // ruleid: missing-assignment
        haha == 123;
        // ok: missing-assignment
        haha += 1;
        // ok: missing-assignment
        haha -= 1;
        // ok: missing-assignment
        haha++;
        // ok: missing-assignment
        haha--;
        // ok: missing-assignment
        --haha;
        // ok: missing-assignment
        ++haha;
        // ok: missing-assignment
        return haha;
    }

    // ok: missing-assignment
    function doit(uint256 a) {}

    function heh(uint256 _id) {
    	// ok: missing-assignment
        Kek puk;
        // ok: missing-assignment
        doit(puk.lol[_id]);
        // ok: missing-assignment
        doit(puk.lol[_id]);
        // ruleid: missing-assignment
        "heh";
        // ok: missing-assignment
        return;
    }    
}