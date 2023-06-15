// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BALBBA3USDOracle is IOracle, IOracleValidate {

    function _get() internal view returns (uint256) {
        uint256 usdcLinearPoolPrice = _getLinearPoolPrice(BAL_BB_A3_USDC);
        uint256 usdtLinearPoolPrice = _getLinearPoolPrice(BAL_BB_A3_USDT);
        uint256 daiLinearPoolPrice = _getLinearPoolPrice(BAL_BB_A3_DAI);

        uint256 minValue = Math.min(
        Math.min(usdcLinearPoolPrice, usdtLinearPoolPrice),
        daiLinearPoolPrice
        );  
        // ruleid: balancer-readonly-reentrancy-getrate
        return (BAL_BB_A3_USD.getRate() * minValue) / 1e18;
    }

    function check() internal view returns (uint256) {
        
        VaultReentrancyLib.ensureNotInVaultContext(IVault(BALANCER_VAULT));
        // ok: balancer-readonly-reentrancy-getrate
        return (BAL_BB_A3_USD.getRate() * minValue) / 1e18;
    }

}

contract PoolRecoveryHelper is SingletonAuthentication {

    function _updateTokenRateCache(
        uint256 index,
        IRateProvider provider,
        uint256 duration
    ) internal virtual {
        // ok: balancer-readonly-reentrancy-getrate
        uint256 rate = provider.getRate();
        bytes32 cache = _tokenRateCaches[index];

        _tokenRateCaches[index] = cache.updateRateAndDuration(rate, duration);

        emit TokenRateCacheUpdated(index, rate);
    }
}