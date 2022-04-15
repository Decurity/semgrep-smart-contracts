pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./RBep20.sol";

interface oracleChainlink {
    function decimals() external view returns (uint8);
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract SimplePriceOracle is PriceOracle {
    mapping(address => uint) prices;

    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    mapping(address => oracleChainlink) public oracleData;

    constructor() public {
    }
    // ruleid: rikkei-setoracledata-not-restricted
    function setOracleData(address rToken, oracleChainlink _oracle) external {
        oracleData[rToken] = _oracle;
    }

    function getUnderlyingPrice(RToken rToken) public view returns (uint) {
        uint decimals = oracleData[address(rToken)].decimals();
        (uint80 roundId,int256 answer,uint256 startedAt,uint256 updatedAt,uint80 answeredInRound) = oracleData[address(rToken)].latestRoundData();
        return 10 ** (18 - decimals) * uint(answer);
    }
}