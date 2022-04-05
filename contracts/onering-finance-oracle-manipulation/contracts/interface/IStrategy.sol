pragma solidity 0.6.12;

interface IStrategy {
    function unsalvagableTokens(address tokens) external view returns (bool);

    function underlying() external view returns (address);

    function vault() external view returns (address);

    function withdrawAllToVault() external;

    function withdrawToVault(uint256 amount) external;

    function investAllUnderlying() external;

    function investedBalance() external view returns (uint256); // itsNotMuch()

    function strategyEnabled(address) external view returns (bool);

    // should only be called by controller
    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external;

    function doHardWork() external;

    function harvest(uint256 _denom, address sender) external;

    function depositArbCheck() external view returns (bool);

    // new functions
    function investedBalanceInUSD() external view returns (uint256);

    function withdrawAllToVault(address _underlying) external;

    function withdrawToVault(uint256 _amount, address _underlying) external;

    function assetToUnderlying(address _asset) external returns (uint256);

    function getUSDBalanceFromUnderlyingBalance(uint256 _bal)
        external
        view
        returns (uint256 _amount);
}
