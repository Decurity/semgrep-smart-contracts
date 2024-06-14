// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.6;

import {FullMath} from '../uniswap-v2/libraries/FullMath.sol';
import {IPriceGetter} from '../uniswap-v2/interfaces/IPriceGetter.sol';
import {IERC20Metadata} from '../uniswap-v2/interfaces/IERC20Metadata.sol';

interface ICurvePoolWithOracle {
  function price_oracle(uint256 i) external view returns (uint256);

  function get_p(uint256 i) external view returns (uint256);
}

interface IUwUOracle {
  function getAssetPrice(address asset) external view returns (uint256);
}

contract sUSDePriceProviderBUniCatch is IPriceGetter {
  address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
  address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public constant CRVUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
  address public constant GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
  ICurvePoolWithOracle public constant FRAX_POOL =
    ICurvePoolWithOracle(0x5dc1BF6f1e983C0b21EfB003c105133736fA0743);
  ICurvePoolWithOracle public constant DAI_POOL =
    ICurvePoolWithOracle(0xF36a4BA50C603204c3FC6d2dA8b78A7b69CBC67d);
  ICurvePoolWithOracle public constant USDC_POOL =
    ICurvePoolWithOracle(0x02950460E2b9529D0E00284A5fA2d7bDF3fA4d72);
  ICurvePoolWithOracle public constant CRVUSD_POOL =
    ICurvePoolWithOracle(0xF55B0f6F2Da5ffDDb104b58a60F2862745960442);
  ICurvePoolWithOracle public constant GHO_POOL =
    ICurvePoolWithOracle(0x670a72e6D22b0956C0D2573288F82DCc5d6E3a61);
  IUwUOracle public constant uwuOracle = IUwUOracle(0xAC4A2aC76D639E10f2C05a41274c1aF85B772598);
  IPriceGetter public immutable UNI_V3_TWAP_USDT_ORACLE;

  uint256 public sUSDeScalingFactor = 1047;
  address public owner;

  constructor(address _usdeUsdtOracle) public {
    owner = msg.sender;
    UNI_V3_TWAP_USDT_ORACLE = IPriceGetter(_usdeUsdtOracle);
  }

  /******* VIEW *******/

  function getPrice() external view override returns (uint256) {
    (uint256[] memory prices, bool uniFail) = _getPrices(true);

    uint256 median = uniFail ? (prices[5] + prices[6]) / 2 : prices[5];

    require(median > 0, 'Median is zero');

    return FullMath.mulDiv(median, sUSDeScalingFactor, 1e3);
  }

  function getPrices(bool sorted) external view returns (uint256[] memory, bool) {
    // ruleid: oracle-uses-curve-spot-price
    return _getPrices(sorted);
  }

  function getMedianUsdePriceInUSD() external view returns (uint256) {
    (uint256[] memory prices, bool uniFail) = _getPrices(true);

    return uniFail ? (prices[5] + prices[6]) / 2 : prices[5];
  }

  function getUSDeFraxEMAInUSD() external view returns (uint256, uint256) {
    // ruleid: oracle-uses-curve-spot-price
    return _getUSDeFraxEMAInUSD();
  }

  function getUSDeUSDCEMAInUSD() external view returns (uint256, uint256) {
    // ruleid: oracle-uses-curve-spot-price
    return _getUSDeUsdcEMAInUSD();
  }

  function getUSDeDAIEMAInUSD() external view returns (uint256, uint256) {
    // ruleid: oracle-uses-curve-spot-price
    return _getUSDeDaiEMAInUSD();
  }

  function getUSDeCrvUsdEMAInUSD() external view returns (uint256, uint256) {
    // ruleid: oracle-uses-curve-spot-price
    return _getCrvUsdUSDeEMAInUSD();
  }

  function getUSDeGhoEMAInUSD() external view returns (uint256, uint256) {
    // ruleid: oracle-uses-curve-spot-price
    return _getUSDeGhoEMAInUSD();
  }

  function getUSDeUsdtTWAPInUSD() external view returns (uint256) {
    try UNI_V3_TWAP_USDT_ORACLE.getPrice() returns (uint256 price) {
      return price;
    } catch {
      return 0;
    }
  }

  /******* OWNER *******/

  function changeScalingFactor(uint256 _newScalingFactor) external {
    require(msg.sender == owner, 'Only Owner');
    require(_newScalingFactor >= 1000, 'Factor cannot be lower than 1000');
    sUSDeScalingFactor = _newScalingFactor;
  }

  function transferOwnership(address _newOwner) external {
    require(msg.sender == owner, 'Only Owner');
    owner = _newOwner;
  }

  /******* INTERNAL *******/

  function _getPrices(bool sorted) internal view returns (uint256[] memory, bool uniFail) {
    uint256[] memory prices = new uint256[](11);
    (prices[0], prices[1]) = _getUSDeFraxEMAInUSD();
    (prices[2], prices[3]) = _getUSDeUsdcEMAInUSD();
    (prices[4], prices[5]) = _getUSDeDaiEMAInUSD();
    (prices[6], prices[7]) = _getCrvUsdUSDeEMAInUSD();
    (prices[8], prices[9]) = _getUSDeGhoEMAInUSD();
    try UNI_V3_TWAP_USDT_ORACLE.getPrice() returns (uint256 price) {
      prices[10] = price;
    } catch {
      uniFail = true;
    }

    if (sorted) {
      _bubbleSort(prices);
    }
    // ruleid: oracle-uses-curve-spot-price
    return (prices, uniFail);
  }

  function _getUSDeFraxEMAInUSD() internal view returns (uint256, uint256) {
    uint256 price = uwuOracle.getAssetPrice(FRAX);
    // (USDe/FRAX * FRAX/USD) / 1e18
    // ruleid: oracle-uses-curve-spot-price
    return (
      FullMath.mulDiv(FRAX_POOL.price_oracle(0), price, 1e18),
      FullMath.mulDiv(FRAX_POOL.get_p(0), price, 1e18)
    );
  }

  function _getUSDeUsdcEMAInUSD() internal view returns (uint256, uint256) {
    uint256 price = uwuOracle.getAssetPrice(USDC);
    // (USDC/USD * 1e18) / USDC/USDe
    // ruleid: oracle-uses-curve-spot-price
    return (
      FullMath.mulDiv(price, 1e18, USDC_POOL.price_oracle(0)),
      FullMath.mulDiv(price, 1e18, USDC_POOL.get_p(0))
    );
  }

  function _getUSDeDaiEMAInUSD() internal view returns (uint256, uint256) {
    uint256 price = uwuOracle.getAssetPrice(DAI);
    // (DAI/USD * 1e18) / DAI/USDe
    // ruleid: oracle-uses-curve-spot-price
    return (
      FullMath.mulDiv(price, 1e18, DAI_POOL.price_oracle(0)),
      FullMath.mulDiv(price, 1e18, DAI_POOL.get_p(0))
    );
  }

  function _getCrvUsdUSDeEMAInUSD() internal view returns (uint256, uint256) {
    uint256 price = uwuOracle.getAssetPrice(CRVUSD);
    // (CRVUSD/USD * 1e18) / CRVUSD/USDe
    // ruleid: oracle-uses-curve-spot-price
    return (
      FullMath.mulDiv(price, 1e18, CRVUSD_POOL.price_oracle(0)),
      FullMath.mulDiv(price, 1e18, CRVUSD_POOL.get_p(0))
    );
  }

  function _getUSDeGhoEMAInUSD() internal view returns (uint256, uint256) {
    uint256 price = uwuOracle.getAssetPrice(GHO);
    // (USDe/GHO * GHO/USD) / 1e18
    // ruleid: oracle-uses-curve-spot-price
    return (
      FullMath.mulDiv(GHO_POOL.price_oracle(0), price, 1e18),
      FullMath.mulDiv(GHO_POOL.get_p(0), price, 1e18)
    );
  }

  function _bubbleSort(uint[] memory arr) internal pure returns (uint[] memory) {
    uint256 n = arr.length;
    for (uint256 i = 0; i < n - 1; i++) {
      for (uint256 j = 0; j < n - i - 1; j++) {
        if (arr[j] > arr[j + 1]) {
          (arr[j], arr[j + 1]) = (arr[j + 1], arr[j]);
        }
      }
    }
    // ruleid: oracle-uses-curve-spot-price
    return arr;
  }
}
