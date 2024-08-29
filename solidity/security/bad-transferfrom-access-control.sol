contract Test {
    function func1(address from, address to) public {
        // ruleid: bad-transferfrom-access-control
        usdc.transferFrom(from, to, amount);
    }

    function func2(address from, address to) public {
        // ok: bad-transferfrom-access-control
        usdc.transferFrom(owner, random, amount);
    }

    function func3(address from, address to) public {
        // ok: bad-transferfrom-access-control
        usdc.transferFrom(pool, to, amount);
    }

    function func4(address from, uint256 amount, address random) public {
        // ok: bad-transferfrom-access-control
        usdc.transferFrom(pool, owner, amount);
    }

    function func5(address from, address to) external {
        // ruleid: bad-transferfrom-access-control
        usdc.transferFrom(from, to, amount);
    }

    function func6(address from, address to) external {
        // ok: bad-transferfrom-access-control
        usdc.transferFrom(owner, random, amount);
    }

    function func7(address from, address to) external {
        // ok: bad-transferfrom-access-control
        usdc.transferFrom(pool, to, amount);
    }

    function func8(address from, uint256 amount, address random) external {
        // ok: bad-transferfrom-access-control
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
                    // ruleid: bad-transferfrom-access-control
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
        // todoruleid: bad-transferfrom-access-control
        usdc.transferFrom(from, to, amount);
    }


    // SAFE TRANSFER TESTS

    function func11(address from, address to) public {
        // ruleid: bad-transferfrom-access-control
        usdc.safeTransferFrom(from, to, amount);
    }

    function func12(address from, address to) public {
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(owner, random, amount);
    }

    function func13(address from, address to) public {
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(pool, to, amount);
    }

    function func14(address from, uint256 amount, address random) public {
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(pool, owner, amount);
    }

    function func15(address from, address to) external {
        // ruleid: bad-transferfrom-access-control
        usdc.safeTransferFrom(from, to, amount);
    }

    function func16(address from, address to) external {
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(owner, random, amount);
    }

    function func17(address from, address to) external {
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(pool, to, amount);
    }

    function func18(address from, uint256 amount, address random) external {
        // ok: bad-transferfrom-access-control
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
                    // ruleid: bad-transferfrom-access-control
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
        // todoruleid: bad-transferfrom-access-control
        usdc.safeTransferFrom(from, to, amount);
    }

    function _func21(address from, address to) internal {
        // internal never called
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(from, to, amount);
        // ok: bad-transferfrom-access-control
        usdc.transferFrom(from, to, amount);
        // ok: bad-transferfrom-access-control
        Helper.safeTransferFrom(token, from, to, amount);
        // ok: bad-transferfrom-access-control
        Helper.transferFrom(token, from, to, amount);
    }

    function func22(address from, address to) external {
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(from, from, amount);
    }

    function func23(address to, address from) external {
        // ruleid: bad-transferfrom-access-control
        usdc.safeTransferFrom(from, to, amount);
    }

    function transferFrom(address to, address from, uint256 amount) external {
        // ok: bad-transferfrom-access-control
        super.transferFrom(from, to, amount);
    }

    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external override nonReentrant {
        _validateHandler();
        _stake(_fundingAccount, _account, _depositToken, _amount);
    }

    function _stake(address _fundingAccount, address _account, address _depositToken, uint256 _amount) private {
        require(_amount > 0, "RewardTracker: invalid _amount");
        require(isDepositToken[_depositToken], "RewardTracker: invalid _depositToken");

        // ok: bad-transferfrom-access-control
        IERC20(_depositToken).transferFrom(_fundingAccount, address(this), _amount);

        _updateRewards(_account);

        stakedAmounts[_account] = stakedAmounts[_account] + _amount;
        depositBalances[_account][_depositToken] = depositBalances[_account][_depositToken] + _amount;
        totalDepositSupply[_depositToken] = totalDepositSupply[_depositToken] + _amount;

        _mint(_account, _amount);
    }


    function func24(address from, address to) onlyOwner public {
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(from, to, amount);
    }

    function func25(address from, address to) public {
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(from, address(this), amount);
    }

    function transferIn(
    address _token,
    address _sender,
    uint256 _amount
    ) public onlyGame onlyWhitelistedToken(_token) {
        // ok: bad-transferfrom-access-control
        IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
    }

    function func26(address random, address from, address to) public {
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(from, someaddress, amount);
    }

    function func28(address random, address from, address to) public {
        // ok: bad-transferfrom-access-control
        usdc.safeTransferFrom(this, some, from);
    }

    function func29(address random, address from, address token, address onemore) public {
        // ok: bad-transferfrom-access-control
        IERC20(token).safeTransferFrom(this, some, amount);
    }
}

