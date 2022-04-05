// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
import {IAppPoolService} from "./app/IAppPoolService.sol";


/// @title Pool Service Interface
/// @notice Implements business logic:
///   - Adding/removing pool liquidity
///   - Managing diesel tokens & diesel rates
///   - Lending/repaying funds to credit Manager
/// More: https://dev.gearbox.fi/developers/pool/abstractpoolservice
interface IPoolService is IAppPoolService {
    // Emits each time when LP adds liquidity to the pool
    event AddLiquidity(
        address indexed sender,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 referralCode
    );

    // Emits each time when LP removes liquidity to the pool
    event RemoveLiquidity(
        address indexed sender,
        address indexed to,
        uint256 amount
    );

    // Emits each time when Credit Manager borrows money from pool
    event Borrow(
        address indexed creditManager,
        address indexed creditAccount,
        uint256 amount
    );

    // Emits each time when Credit Manager repays money from pool
    event Repay(
        address indexed creditManager,
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    );

    // Emits each time when Interest Rate model was changed
    event NewInterestRateModel(address indexed newInterestRateModel);

    // Emits each time when new credit Manager was connected
    event NewCreditManagerConnected(address indexed creditManager);

    // Emits each time when borrow forbidden for credit manager
    event BorrowForbidden(address indexed creditManager);

    // Emits each time when uncovered (non insured) loss accrued
    event UncoveredLoss(address indexed creditManager, uint256 loss);

    // Emits after expected liquidity limit update
    event NewExpectedLiquidityLimit(uint256 newLimit);

    // Emits each time when withdraw fee is udpated
    event NewWithdrawFee(uint256 fee);

    //
    // LIQUIDITY MANAGEMENT
    //

    /**
     * @dev Adds liquidity to pool
     * - transfers lp tokens to pool
     * - mint diesel (LP) tokens and provide them
     * @param amount Amount of tokens to be transfer
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    ) external override;

    /**
     * @dev Removes liquidity from pool
     * - burns lp's diesel (LP) tokens
     * - returns underlying tokens to lp
     * @param amount Amount of tokens to be transfer
     * @param to Address to transfer liquidity
     */

    function removeLiquidity(uint256 amount, address to)
        external
        override
        returns (uint256);

    /**
     * @dev Transfers money from the pool to credit account
     * and updates the pool parameters
     * @param borrowedAmount Borrowed amount for credit account
     * @param creditAccount Credit account address
     */
    function lendCreditAccount(uint256 borrowedAmount, address creditAccount)
        external;

    /**
     * @dev Recalculates total borrowed & borrowRate
     * mints/burns diesel tokens
     */
    function repayCreditAccount(
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    ) external;

    //
    // GETTERS
    //

    /**
     * @return expected pool liquidity
     */
    function expectedLiquidity() external view returns (uint256);

    /**
     * @return expected liquidity limit
     */
    function expectedLiquidityLimit() external view returns (uint256);

    /**
     * @dev Gets available liquidity in the pool (pool balance)
     * @return available pool liquidity
     */
    function availableLiquidity() external view returns (uint256);

    /**
     * @dev Calculates interest accrued from the last update using the linear model
     */
    function calcLinearCumulative_RAY() external view returns (uint256);

    /**
     * @dev Calculates borrow rate
     * @return borrow rate in RAY format
     */
    function borrowAPY_RAY() external view returns (uint256);

    /**
     * @dev Gets the amount of total borrowed funds
     * @return Amount of borrowed funds at current time
     */
    function totalBorrowed() external view returns (uint256);

    /**
     * @return Current diesel rate
     **/

    function getDieselRate_RAY() external view returns (uint256);

    /**
     * @dev Underlying token address getter
     * @return address of underlying ERC-20 token
     */
    function underlyingToken() external view returns (address);

    /**
     * @dev Diesel(LP) token address getter
     * @return address of diesel(LP) ERC-20 token
     */
    function dieselToken() external view returns (address);

    /**
     * @dev Credit Manager address getter
     * @return address of Credit Manager contract by id
     */
    function creditManagers(uint256 id) external view returns (address);

    /**
     * @dev Credit Managers quantity
     * @return quantity of connected credit Managers
     */
    function creditManagersCount() external view returns (uint256);

    function creditManagersCanBorrow(address id) external view returns (bool);

    function toDiesel(uint256 amount) external view returns (uint256);

    function fromDiesel(uint256 amount) external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function _timestampLU() external view returns (uint256);

    function _cumulativeIndex_RAY() external view returns (uint256);

    function calcCumulativeIndexAtBorrowMore(
        uint256 amount,
        uint256 dAmount,
        uint256 cumulativeIndexAtOpen
    ) external view returns (uint256);

}
