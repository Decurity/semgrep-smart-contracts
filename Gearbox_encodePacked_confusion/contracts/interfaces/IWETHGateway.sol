// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


interface IWETHGateway {
    /// @dev convert ETH to WETH and add liqudity to pool
    /// @param pool Address of PoolService contract which where user wants to add liquidity. This pool should has WETH as underlying asset
    /// @param onBehalfOf The address that will receive the diesel tokens, same as msg.sender if the user  wants to receive them on his
    ///                   own wallet, or a different address if the beneficiary of diesel tokens is a different wallet
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    /// 0 if the action is executed directly by the user, without any middle-man
    function addLiquidityETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    /// @dev Removes liquidity from pool and convert WETH to ETH
    ///       - burns lp's diesel (LP) tokens
    ///       - returns underlying tokens to lp
    /// @param pool Address of PoolService contract which where user wants to withdraw liquidity. This pool should has WETH as underlying asset
    /// @param amount Amount of tokens to be transfer
    /// @param to Address to transfer liquidity
    function removeLiquidityETH(
        address pool,
        uint256 amount,
        address payable to
    ) external;

    /// @dev Opens credit account in ETH
    /// @param creditManager Address of credit Manager. Should used WETH as underlying asset
    /// @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
    ///                   or a different address if the beneficiary is a different wallet
    /// @param leverageFactor Multiplier to borrowers own funds
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    ///                     0 if the action is executed directly by the user, without any middle-man
    function openCreditAccountETH(
        address creditManager,
        address payable onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    ) external payable;

    /// @dev Repays credit account in ETH
    ///       - transfer borrowed money with interest + fee from borrower account to pool
    ///       - transfer all assets to "to" account
    /// @param creditManager Address of credit Manager. Should used WETH as underlying asset
    /// @param to Address to send credit account assets
    function repayCreditAccountETH(address creditManager, address to)
        external
        payable;

    function addCollateralETH(address creditManager, address onBehalfOf)
        external
        payable;

    /// @dev Unwrap WETH => ETH
    /// @param to Address to send eth
    /// @param amount Amount of WETH was transferred
    function unwrapWETH(address to, uint256 amount) external;
}
