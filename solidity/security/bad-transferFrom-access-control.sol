contract Test {
    function func1(address from, address to) public {
        // ruleid: bad-transferFrom-access-control
        usdc.transferFrom(from, to, amount);
    }

    function func2(address from, address to) public {
        // ok: bad-transferFrom-access-control
        usdc.transferFrom(owner, random, amount);
    }

    function func3(address from, address to) public {
        // ok: bad-transferFrom-access-control
        usdc.transferFrom(pool, to, amount);
    }

    function func4(address from, uint256 amount, address random) public {
        // ok: bad-transferFrom-access-control
        usdc.transferFrom(pool, owner, amount);
    }

    function func5(address from, address to) external {
        // ruleid: bad-transferFrom-access-control
        usdc.transferFrom(from, to, amount);
    }

    function func6(address from, address to) external {
        // ok: bad-transferFrom-access-control
        usdc.transferFrom(owner, random, amount);
    }

    function func7(address from, address to) external {
        // ok: bad-transferFrom-access-control
        usdc.transferFrom(pool, to, amount);
    }

    function func8(address from, uint256 amount, address random) external {
        // ok: bad-transferFrom-access-control
        usdc.transferFrom(pool, owner, amount);
    }

    function transferFee(uint256 amount, uint256 feeBps, address token, address from, address to)
        public
        returns (uint256)
    {
        uint256 fee = calculateFee(amount, feeBps);
        if (fee > 0) {
            if (token != NATIVE_TOKEN) {
                // ERC20 token
                if (from == address(this)) {
                    TransferHelper.safeTransfer(token, to, fee);
                } else {
                    // safeTransferFrom requires approval
                    // ruleid: bad-transferFrom-access-control
                    TransferHelper.transferFrom(token, from, to, fee);
                }
            } else {
                require(from == address(this), "can only transfer eth from the router address");

                // Native ether
                (bool success,) = to.call{value: fee}("");
                require(success, "transfer failed in transferFee");
            }
            return fee;
        } else {
            return 0;
        }
    }

    function func9(address from, address to) external {
        _func10(from, to, amount);
    }

    function _func10(address from, address to) internal {
        // ruleid: bad-transferFrom-access-control
        usdc.transferFrom(from, to, amount);
    }


    // SAFE TRANSFER TESTS

    function func11(address from, address to) public {
        // ruleid: bad-transferFrom-access-control
        usdc.safeTransferFrom(from, to, amount);
    }

    function func12(address from, address to) public {
        // ok: bad-transferFrom-access-control
        usdc.safeTransferFrom(owner, random, amount);
    }

    function func13(address from, address to) public {
        // ok: bad-transferFrom-access-control
        usdc.safeTransferFrom(pool, to, amount);
    }

    function func14(address from, uint256 amount, address random) public {
        // ok: bad-transferFrom-access-control
        usdc.safeTransferFrom(pool, owner, amount);
    }

    function func15(address from, address to) external {
        // ruleid: bad-transferFrom-access-control
        usdc.safeTransferFrom(from, to, amount);
    }

    function func16(address from, address to) external {
        // ok: bad-transferFrom-access-control
        usdc.safeTransferFrom(owner, random, amount);
    }

    function func17(address from, address to) external {
        // ok: bad-transferFrom-access-control
        usdc.safeTransferFrom(pool, to, amount);
    }

    function func18(address from, uint256 amount, address random) external {
        // ok: bad-transferFrom-access-control
        usdc.safeTransferFrom(pool, owner, amount);
    }

    function transferFee2(uint256 amount, uint256 feeBps, address token, address from, address to)
        public
        returns (uint256)
    {
        uint256 fee = calculateFee(amount, feeBps);
        if (fee > 0) {
            if (token != NATIVE_TOKEN) {
                // ERC20 token
                if (from == address(this)) {
                    TransferHelper.safeTransfer(token, to, fee);
                } else {
                    // safeTransferFrom requires approval
                    // ruleid: bad-transferFrom-access-control
                    TransferHelper.safeTransferFrom(token, from, to, fee);
                }
            } else {
                require(from == address(this), "can only transfer eth from the router address");

                // Native ether
                (bool success,) = to.call{value: fee}("");
                require(success, "transfer failed in transferFee");
            }
            return fee;
        } else {
            return 0;
        }
    }

    function func19(address from, address to) external {
        _func20(from, to, amount);
    }

    function _func20(address from, address to) internal {
        // ruleid: bad-transferFrom-access-control
        usdc.safeTransferFrom(from, to, amount);
    }

}