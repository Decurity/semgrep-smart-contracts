// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./LeetSwapV2Fees.sol";
import "./ILeetSwapV2Factory.sol";
import "./ILeetSwapV2Pair.sol";
import "./ILeetSwapV2Callee.sol";
import "./Math.sol";
import "./IERC20Metadata.sol";

// The base pair of pools, either stable or volatile
contract LeetSwapV2Pair is ILeetSwapV2Pair {
    uint8 public constant decimals = 18;

    // Used to denote stable or volatile pair, not immutable since construction happens in the initialize method for CREATE2 deterministic addresses
    bool public immutable stable;

    uint256 public totalSupply = 0;

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    bytes32 internal DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 internal constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    address public immutable token0;
    address public immutable token1;
    address public immutable fees;
    address public immutable factory;

    // Structure to capture time period observations every 30 minutes, used for local oracles
    struct Observation {
        uint256 timestamp;
        uint256 reserve0Cumulative;
        uint256 reserve1Cumulative;
    }

    // Capture oracle reading every 30 minutes
    uint256 constant periodSize = 1800;

    Observation[] public observations;

    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public blockTimestampLast;

    uint256 public reserve0CumulativeLast;
    uint256 public reserve1CumulativeLast;

    // index0 and index1 are used to accumulate fees, this is split out from normal trades to keep the swap "clean"
    // this further allows LP holders to easily claim fees for tokens they have/staked
    uint256 public index0 = 0;
    uint256 public index1 = 0;

    // position assigned to each LP to track their current index0 & index1 vs the global position
    mapping(address => uint256) public supplyIndex0;
    mapping(address => uint256) public supplyIndex1;

    // tracks the amount of unclaimed, but claimable tokens off of fees for token0 and token1
    mapping(address => uint256) public claimable0;
    mapping(address => uint256) public claimable1;

    event Fees(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    event Claim(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1
    );

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    error DEXPaused();
    error InvalidToken();
    error TransferFailed();
    error InsufficientOutputAmount();
    error InsufficientInputAmount();
    error InsufficientLiquidity();
    error ReentrancyGuard();
    error DeadlineExpired();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InvariantNotRespected();
    error InvalidSwapRecipient();
    error InvalidSignature();

    constructor() {
        factory = msg.sender;
        (address _token0, address _token1, bool _stable) = ILeetSwapV2Factory(
            msg.sender
        ).getInitializable();
        (token0, token1, stable) = (_token0, _token1, _stable);

        fees = address(new LeetSwapV2Fees(_token0, _token1));

        observations.push(Observation(block.timestamp, 0, 0));
    }

    function decimals0() internal view returns (uint256) {
        return 10**IERC20Metadata(token0).decimals();
    }

    function decimals1() internal view returns (uint256) {
        return 10**IERC20Metadata(token1).decimals();
    }

    function name() public view returns (string memory) {
        if (stable) {
            return
                string(
                    abi.encodePacked(
                        "LeetSwapV2 StableV1 Pair - ",
                        IERC20Metadata(token0).symbol(),
                        "/",
                        IERC20Metadata(token1).symbol()
                    )
                );
        }

        return
            string(
                abi.encodePacked(
                    "LeetSwapV2 VolatileV1 Pair - ",
                    IERC20Metadata(token0).symbol(),
                    "/",
                    IERC20Metadata(token1).symbol()
                )
            );
    }

    function symbol() public view returns (string memory) {
        if (stable) {
            return
                string(
                    abi.encodePacked(
                        "sLS2-",
                        IERC20Metadata(token0).symbol(),
                        "/",
                        IERC20Metadata(token1).symbol()
                    )
                );
        }

        return
            string(
                abi.encodePacked(
                    "vLS2-",
                    IERC20Metadata(token0).symbol(),
                    "/",
                    IERC20Metadata(token1).symbol()
                )
            );
    }

    // simple re-entrancy check
    uint256 internal _unlocked = 1;
    modifier lock() {
        if (_unlocked != 1) revert ReentrancyGuard();
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function observationLength() external view returns (uint256) {
        return observations.length;
    }

    function lastObservation() public view returns (Observation memory) {
        return observations[observations.length - 1];
    }

    function metadata()
        external
        view
        returns (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            address t1
        )
    {
        return (
            decimals0(),
            decimals1(),
            reserve0,
            reserve1,
            stable,
            token0,
            token1
        );
    }

    function tokens() external view returns (address, address) {
        return (token0, token1);
    }

    // claim accumulated but unclaimed fees (viewable via claimable0 and claimable1)
    function claimFees() external returns (uint256 claimed0, uint256 claimed1) {
        return claimFeesFor(msg.sender);
    }

    function claimFeesFor(address recipient)
        public
        lock
        returns (uint256 claimed0, uint256 claimed1)
    {
        _updateFor(recipient);

        claimed0 = claimable0[recipient];
        claimed1 = claimable1[recipient];

        claimable0[recipient] = 0;
        claimable1[recipient] = 0;

        LeetSwapV2Fees(fees).claimFeesFor(recipient, claimed0, claimed1);

        emit Claim(msg.sender, recipient, claimed0, claimed1);
    }

    function claimableFeesFor(address account)
        public
        view
        returns (uint256 _claimable0, uint256 _claimable1)
    {
        uint256 _supplied = balanceOf[account];
        _claimable0 = claimable0[account];
        _claimable1 = claimable1[account];
        if (_supplied > 0) {
            uint256 _delta0 = index0 - supplyIndex0[account];
            uint256 _delta1 = index1 - supplyIndex1[account];
            if (_delta0 > 0) {
                uint256 _share = (_supplied * _delta0) / 1e18;
                _claimable0 += _share;
            }
            if (_delta1 > 0) {
                uint256 _share = (_supplied * _delta1) / 1e18;
                _claimable1 += _share;
            }
        }
    }

    function claimableFees()
        external
        view
        returns (uint256 _claimable0, uint256 _claimable1)
    {
        return claimableFeesFor(msg.sender);
    }

    // Used to transfer fees when calling _update[01]
    //ruleid: public-transfer-fees-supporting-tax-tokens
    function _transferFeesSupportingTaxTokens(address token, uint256 amount)
        public
        returns (uint256)
    {
        if (amount == 0) {
            return 0;
        }

        uint256 balanceBefore = IERC20(token).balanceOf(fees);
        _safeTransfer(token, fees, amount);
        uint256 balanceAfter = IERC20(token).balanceOf(fees);

        return balanceAfter - balanceBefore;
    }

    // Accrue fees on token0
    function _update0(uint256 amount) internal {
        uint256 _protocolFeesShare = ILeetSwapV2Factory(factory)
            .protocolFeesShare();
        address _protocolFeesRecipient = ILeetSwapV2Factory(factory)
            .protocolFeesRecipient();
        uint256 _protocolFeesAmount = (amount * _protocolFeesShare) / 10000;
        amount = _transferFeesSupportingTaxTokens(
            token0,
            amount - _protocolFeesAmount
        );
        if (_protocolFeesAmount > 0)
            _safeTransfer(token0, _protocolFeesRecipient, _protocolFeesAmount);
        uint256 _ratio = (amount * 1e18) / totalSupply;
        if (_ratio > 0) {
            index0 += _ratio;
        }
        emit Fees(msg.sender, amount, 0);
    }

    // Accrue fees on token1
    function _update1(uint256 amount) internal {
        uint256 _protocolFeesShare = ILeetSwapV2Factory(factory)
            .protocolFeesShare();
        address _protocolFeesRecipient = ILeetSwapV2Factory(factory)
            .protocolFeesRecipient();
        uint256 _protocolFeesAmount = (amount * _protocolFeesShare) / 10000;
        amount = _transferFeesSupportingTaxTokens(
            token1,
            amount - _protocolFeesAmount
        );
        if (_protocolFeesAmount > 0)
            _safeTransfer(token1, _protocolFeesRecipient, _protocolFeesAmount);
        uint256 _ratio = (amount * 1e18) / totalSupply;
        if (_ratio > 0) {
            index1 += _ratio;
        }
        emit Fees(msg.sender, 0, amount);
    }

    // this function MUST be called on any balance changes, otherwise can be used to infinitely claim fees
    // Fees are segregated from core funds, so fees can never put liquidity at risk
    function _updateFor(address recipient) internal {
        uint256 _supplied = balanceOf[recipient]; // get LP balance of `recipient`
        if (_supplied > 0) {
            uint256 _supplyIndex0 = supplyIndex0[recipient]; // get last adjusted index0 for recipient
            uint256 _supplyIndex1 = supplyIndex1[recipient];
            uint256 _index0 = index0; // get global index0 for accumulated fees
            uint256 _index1 = index1;
            supplyIndex0[recipient] = _index0; // update user current position to global position
            supplyIndex1[recipient] = _index1;
            uint256 _delta0 = _index0 - _supplyIndex0; // see if there is any difference that need to be accrued
            uint256 _delta1 = _index1 - _supplyIndex1;
            if (_delta0 > 0) {
                uint256 _share = (_supplied * _delta0) / 1e18; // add accrued difference for each supplied token
                claimable0[recipient] += _share;
            }
            if (_delta1 > 0) {
                uint256 _share = (_supplied * _delta1) / 1e18;
                claimable1[recipient] += _share;
            }
        } else {
            supplyIndex0[recipient] = index0; // new users are set to the default global state
            supplyIndex1[recipient] = index1;
        }
    }

    function getReserves()
        public
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal {
        uint256 blockTimestamp = block.timestamp;
        uint256 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            reserve0CumulativeLast += _reserve0 * timeElapsed;
            reserve1CumulativeLast += _reserve1 * timeElapsed;
        }

        Observation memory _point = lastObservation();
        timeElapsed = blockTimestamp - _point.timestamp; // compare the last observation with current timestamp, if greater than 30 minutes, record a new event
        if (timeElapsed > periodSize) {
            observations.push(
                Observation(
                    blockTimestamp,
                    reserve0CumulativeLast,
                    reserve1CumulativeLast
                )
            );
        }
        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices()
        public
        view
        returns (
            uint256 reserve0Cumulative,
            uint256 reserve1Cumulative,
            uint256 blockTimestamp
        )
    {
        blockTimestamp = block.timestamp;
        reserve0Cumulative = reserve0CumulativeLast;
        reserve1Cumulative = reserve1CumulativeLast;

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        ) = getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint256 timeElapsed = blockTimestamp - _blockTimestampLast;
            reserve0Cumulative += _reserve0 * timeElapsed;
            reserve1Cumulative += _reserve1 * timeElapsed;
        }
    }

    // gives the current twap price measured from amountIn * tokenIn gives amountOut
    function current(address tokenIn, uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        Observation memory _observation = lastObservation();
        (
            uint256 reserve0Cumulative,
            uint256 reserve1Cumulative,

        ) = currentCumulativePrices();
        if (block.timestamp == _observation.timestamp) {
            _observation = observations[observations.length - 2];
        }

        uint256 timeElapsed = block.timestamp - _observation.timestamp;
        uint256 _reserve0 = (reserve0Cumulative -
            _observation.reserve0Cumulative) / timeElapsed;
        uint256 _reserve1 = (reserve1Cumulative -
            _observation.reserve1Cumulative) / timeElapsed;
        amountOut = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    // as per `current`, however allows user configured granularity, up to the full window size
    function quote(
        address tokenIn,
        uint256 amountIn,
        uint256 granularity
    ) external view returns (uint256 amountOut) {
        uint256[] memory _prices = sample(tokenIn, amountIn, granularity, 1);
        uint256 priceAverageCumulative;
        for (uint256 i = 0; i < _prices.length; i++) {
            priceAverageCumulative += _prices[i];
        }
        return priceAverageCumulative / granularity;
    }

    // returns a memory set of twap prices
    function prices(
        address tokenIn,
        uint256 amountIn,
        uint256 points
    ) external view returns (uint256[] memory) {
        return sample(tokenIn, amountIn, points, 1);
    }

    function sample(
        address tokenIn,
        uint256 amountIn,
        uint256 points,
        uint256 window
    ) public view returns (uint256[] memory) {
        uint256[] memory _prices = new uint256[](points);

        uint256 length = observations.length - 1;
        uint256 i = length - (points * window);
        uint256 nextIndex = 0;
        uint256 index = 0;

        for (; i < length; i += window) {
            nextIndex = i + window;
            uint256 timeElapsed = observations[nextIndex].timestamp -
                observations[i].timestamp;
            uint256 _reserve0 = (observations[nextIndex].reserve0Cumulative -
                observations[i].reserve0Cumulative) / timeElapsed;
            uint256 _reserve1 = (observations[nextIndex].reserve1Cumulative -
                observations[i].reserve1Cumulative) / timeElapsed;
            _prices[index] = _getAmountOut(
                amountIn,
                tokenIn,
                _reserve0,
                _reserve1
            );
            index = index + 1;
        }
        return _prices;
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        uint256 _balance0 = IERC20Metadata(token0).balanceOf(address(this));
        uint256 _balance1 = IERC20Metadata(token1).balanceOf(address(this));
        uint256 _amount0 = _balance0 - _reserve0;
        uint256 _amount1 = _balance1 - _reserve1;

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(_amount0 * _amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                (_amount0 * _totalSupply) / _reserve0,
                (_amount1 * _totalSupply) / _reserve1
            );
        }
        if (liquidity <= 0) revert InsufficientLiquidityMinted();
        _mint(to, liquidity);

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, _amount0, _amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function burn(address to)
        external
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        (address _token0, address _token1) = (token0, token1);
        uint256 _balance0 = IERC20Metadata(_token0).balanceOf(address(this));
        uint256 _balance1 = IERC20Metadata(_token1).balanceOf(address(this));
        uint256 _liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (_liquidity * _balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (_liquidity * _balance1) / _totalSupply; // using balances ensures pro-rata distribution
        if (amount0 <= 0 || amount1 <= 0) revert InsufficientLiquidityBurned();
        _burn(address(this), _liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        _balance0 = IERC20Metadata(_token0).balanceOf(address(this));
        _balance1 = IERC20Metadata(_token1).balanceOf(address(this));

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        if (ILeetSwapV2Factory(factory).isPaused()) revert DEXPaused();
        if (amount0Out <= 0 && amount1Out <= 0)
            revert InsufficientOutputAmount();
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        if (amount0Out >= _reserve0 || amount1Out >= _reserve1)
            revert InsufficientLiquidity();

        uint256 _balance0;
        uint256 _balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            if (to == _token0 || to == _token1) revert InvalidSwapRecipient();
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0)
                ILeetSwapV2Callee(to).hook(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                ); // callback, used for flash loans
            _balance0 = IERC20Metadata(_token0).balanceOf(address(this));
            _balance1 = IERC20Metadata(_token1).balanceOf(address(this));
        }
        uint256 amount0In = _balance0 > _reserve0 - amount0Out
            ? _balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = _balance1 > _reserve1 - amount1Out
            ? _balance1 - (_reserve1 - amount1Out)
            : 0;
        if (amount0In <= 0 && amount1In <= 0) revert InsufficientInputAmount();
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            uint256 _tradingFees = ILeetSwapV2Factory(factory).tradingFees(
                address(this),
                to
            );
            if (amount0In > 0) _update0((amount0In * _tradingFees) / 10000); // accrue fees for token0 and move them out of pool
            if (amount1In > 0) _update1((amount1In * _tradingFees) / 10000); // accrue fees for token1 and move them out of pool
            _balance0 = IERC20Metadata(_token0).balanceOf(address(this)); // since we removed tokens, we need to reconfirm balances, can also simply use previous balance - amountIn/ 10000, but doing balanceOf again as safety check
            _balance1 = IERC20Metadata(_token1).balanceOf(address(this));
            // The curve, either x3y+y3x for stable pools, or x*y for volatile pools
            if (_k(_balance0, _balance1) < _k(_reserve0, _reserve1))
                revert InvariantNotRespected();
        }

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        (address _token0, address _token1) = (token0, token1);
        _safeTransfer(
            _token0,
            to,
            IERC20Metadata(_token0).balanceOf(address(this)) - (reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20Metadata(_token1).balanceOf(address(this)) - (reserve1)
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20Metadata(token0).balanceOf(address(this)),
            IERC20Metadata(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return
            (x0 * ((((y * y) / 1e18) * y) / 1e18)) /
            1e18 +
            (((((x0 * x0) / 1e18) * x0) / 1e18) * y) /
            1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return
            (3 * x0 * ((y * y) / 1e18)) /
            1e18 +
            ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _get_y(
        uint256 x0,
        uint256 xy,
        uint256 y
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 y_prev = y;
            uint256 k = _f(x0, y);
            if (k < xy) {
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
                y = y + dy;
            } else {
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address to
    ) public view returns (uint256) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        uint256 _tradingFees = ILeetSwapV2Factory(factory).tradingFees(
            address(this),
            to
        );
        amountIn -= (amountIn * _tradingFees) / 10000; // remove fee from amount received
        return _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256)
    {
        return getAmountOut(amountIn, tokenIn, msg.sender);
    }

    function _getAmountOut(
        uint256 amountIn,
        address tokenIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256) {
        if (stable) {
            uint256 xy = _k(_reserve0, _reserve1);
            _reserve0 = (_reserve0 * 1e18) / decimals0();
            _reserve1 = (_reserve1 * 1e18) / decimals1();
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            amountIn = tokenIn == token0
                ? (amountIn * 1e18) / decimals0()
                : (amountIn * 1e18) / decimals1();
            uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            return (y * (tokenIn == token0 ? decimals1() : decimals0())) / 1e18;
        } else {
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            return (amountIn * reserveB) / (reserveA + amountIn);
        }
    }

    function _k(uint256 x, uint256 y) internal view returns (uint256) {
        if (stable) {
            uint256 _x = (x * 1e18) / decimals0();
            uint256 _y = (y * 1e18) / decimals1();
            uint256 _a = (_x * _y) / 1e18;
            uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return (_a * _b) / 1e18; // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }

    function _mint(address dst, uint256 amount) internal {
        _updateFor(dst); // balances must be updated on mint/burn/transfer
        totalSupply += amount;
        balanceOf[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint256 amount) internal {
        _updateFor(dst);
        totalSupply -= amount;
        balanceOf[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (deadline < block.timestamp) revert DeadlineExpired();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress == address(0) || recoveredAddress != owner)
            revert InvalidSignature();
        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[src][spender];

        if (spender != src && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - amount;
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        _updateFor(src); // update fee position for src
        _updateFor(dst); // update fee position for dst

        balanceOf[src] -= amount;
        balanceOf[dst] += amount;

        emit Transfer(src, dst, amount);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        if (token.code.length == 0) revert InvalidToken();
        bool success = IERC20(token).transfer(to, value);
        if (!success) revert TransferFailed();
    }
}