// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/interfaces/IERC20.sol";

interface IPoolManager {
    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }
    
    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
    }
}

struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

type Currency is address;
type PoolId is bytes32;

struct BeforeSwapDelta {
    int128 deltaAmountSpecified;
    int128 deltaAmountUnspecified;
}

contract Test {
    modifier onlyPoolManager() {
        require(msg.sender == address(poolManager), "Not authorized");
        _;
    }
    
    modifier whenNotPaused() {
        _;
    }

    address constant ZERO_ADDRESS = address(0);
    address poolManager;
    mapping(address => uint8) positionManagers;
    mapping(PoolId => address) beforeAddLiquidityPolicies;
    PoolId constant DEFAULT_POOL = PoolId.wrap(bytes32(0));

    // ok: uniswap-v4-callback-not-protected
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata hookData
    ) external view override onlyPoolManager whenNotPaused returns (bytes4) {
        if (sender == ZERO_ADDRESS || positionManagers[sender] != 1) {
            revert("PositionManagerNotAllowed");
        }

        PoolId id = toId(key);
        address policy = beforeAddLiquidityPolicies[DEFAULT_POOL];
        if (beforeAddLiquidityPolicies[id] != ZERO_ADDRESS) {
            policy = beforeAddLiquidityPolicies[id];
        }

        return bytes4(0);
    }

    // ok: uniswap-v4-callback-not-protected
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override onlyPoolManager returns (bytes4, BeforeSwapDelta memory delta, uint24) {
        delta = BeforeSwapDelta(-int128(params.amountSpecified), int128(100));
        return (this.beforeSwap.selector, delta, 0);
    }

    // ok: uniswap-v4-callback-not-protected
    function afterInitialize(
        address sender,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        int24 tick,
        bytes calldata hookData
    ) external view onlyPoolManager override returns (bytes4) {
        return bytes4(0);
    }

    // ok: uniswap-v4-callback-not-protected
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external view override onlyPoolManager returns (bytes4) {
        return bytes4(0);
    }

    // ok: uniswap-v4-callback-not-protected
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external override onlyPoolManager returns (bytes4) {
        require(msg.sender == poolManager, "Access control check");
        return bytes4(0);
    }

    // ok: uniswap-v4-callback-not-protected
    function beforeInitialize(
        address sender,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        bytes calldata hookData
    ) external returns (bytes4) {
        require(msg.sender == address(poolManager), "Only pool manager");
        return bytes4(0);
    }

    // ok: uniswap-v4-callback-not-protected
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BeforeSwapDelta memory delta,
        bytes calldata hookData
    ) external returns (bytes4) {
        require(poolManager == msg.sender, "Unauthorized access");
        return bytes4(0);
    }

    // ok: uniswap-v4-callback-not-protected
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BeforeSwapDelta memory delta,
        bytes calldata hookData
    ) external returns (bytes4) {
        if (msg.sender != poolManager) {
            revert("Access denied");
        }
        return bytes4(0);
    }

    // ok: uniswap-v4-callback-not-protected
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BeforeSwapDelta memory delta,
        bytes calldata hookData
    ) external returns (bytes4) {
        if (msg.sender != address(poolManager)) {
            revert("Unauthorized");
        }
        return bytes4(0);
    }

    // ok: uniswap-v4-callback-not-protected
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external view returns (bytes4) {
        require(address(poolManager) == msg.sender, "Access control failed");
        return bytes4(0);
    }

    // ruleid: uniswap-v4-callback-not-protected
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta memory delta, uint24) {
        // This function is missing onlyPoolManager modifier
        delta = BeforeSwapDelta(-int128(params.amountSpecified), int128(100));
        return (this.beforeSwap.selector, delta, 0);
    }

    // ruleid: uniswap-v4-callback-not-protected
    function afterInitialize(
        address sender,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        int24 tick,
        bytes calldata hookData
    ) external view override returns (bytes4) {
        // Missing access control
        return bytes4(0);
    }

    // ruleid: uniswap-v4-callback-not-protected
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external view returns (bytes4) {
        // No protection mechanism
        return bytes4(0);
    }

    // ruleid: uniswap-v4-callback-not-protected
    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BeforeSwapDelta memory delta,
        bytes calldata hookData
    ) external returns (bytes4) {
        // Unprotected callback
        return bytes4(0);
    }

    // ruleid: uniswap-v4-callback-not-protected
    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external view returns (bytes4) {
        // No access control check
        return bytes4(0);
    }

    // ruleid: uniswap-v4-callback-not-protected
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BeforeSwapDelta memory delta,
        bytes calldata hookData
    ) external returns (bytes4) {
        // Missing onlyPoolManager modifier
        return bytes4(0);
    }

    // ruleid: uniswap-v4-callback-not-protected
    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external override returns (bytes4) {
        // Vulnerable to unauthorized access
        return bytes4(0);
    }

    // ruleid: uniswap-v4-callback-not-protected
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external view override returns (bytes4) {
        // No protection against unauthorized calls
        return bytes4(0);
    }

    // ruleid: uniswap-v4-callback-not-protected
    function beforeInitialize(
        address sender,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        bytes calldata hookData
    ) external returns (bytes4) {
        // Should have onlyPoolManager modifier but doesn't
        return bytes4(0);
    }

    // ruleid: uniswap-v4-callback-not-protected
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BeforeSwapDelta memory delta,
        bytes calldata hookData
    ) external returns (bytes4) {
        // This callback lacks proper access control
        return bytes4(0);
    }

    // Helper functions
    function toId(PoolKey calldata key) internal pure returns (PoolId) {
        return PoolId.wrap(keccak256(abi.encode(key)));
    }
} 