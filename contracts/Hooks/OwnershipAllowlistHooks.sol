// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/token/ERC1155/IERC1155.sol";
import {PoolId} from "@uniV4/src/types/PoolId.sol";
import {IPoolManager} from "@uniV4/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniV4/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniV4/src/types/PoolId.sol";
import {BalanceDelta} from "@uniV4/src/types/BalanceDelta.sol";
import {BaseHook} from "../BaseHook.sol";

/// @notice These hooks (inspired by https://github.com/wagmiwiz/nft-owners-only-uniswap-hook) restricts adding liqudity,
///         swapping, and donating depending on whether the tx.origin owns a specified token. Supported token standards
///         include ERC20s, ERC721s, and ERC1155s.

/// @notice This hooks restricts access given a minimum balance of an ERC20 token.
contract ERC20OwnershipAllowlistHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    /// ERRORS ///

    error MinBalanceNotHeld();

    /// IMMUTABLES ///

    IERC20 public immutable erc20;
    uint256 public immutable minBalance;

    /// CONSTRUCTOR ///

    constructor(
        IPoolManager _poolManager,
        IERC20 _erc20,
        uint256 _minBalance
    ) BaseHook(_poolManager) {
        erc20 = _erc20;
        minBalance = _minBalance;
    }

    /// OVERRIDES ///

    function beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeAddLiquidity.selector;
    }

    function beforeSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeSwap.selector;
    }

    function beforeDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeDonate.selector;
    }

    /// INTERNALS ///

    function _senderHoldsMinTokens(address _sender) internal view returns (bool) {
        return (erc20.balanceOf(_sender) >= minBalance);
    }
}

/// @dev build the 721 and 1155 counterparts also