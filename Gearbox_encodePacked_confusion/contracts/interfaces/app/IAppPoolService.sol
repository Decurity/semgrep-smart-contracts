// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

/// @title POptimised for front-end Pool Service Interface
interface IAppPoolService {

    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    ) external;

    function removeLiquidity(uint256 amount, address to) external returns(uint256);

}
