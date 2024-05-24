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
/// @dev    Contracts below use tx.origin rather than msg.sender to determine ownership. The reason for this is so that
///         ownership isn't queried from the swap router, but instead the originator of the transaction. This does however
///         introduce the risk of malicious contracts exploiting user's owned assets to add liquidity, swap, or donate
///         without owning the asset themselves.

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
    ) external view override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeAddLiquidity.selector;
    }

    function beforeSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external view override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeSwap.selector;
    }

    function beforeDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external view override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeDonate.selector;
    }

    /// INTERNALS ///

    function _senderHoldsMinTokens(address _sender) internal view returns (bool) {
        return (erc20.balanceOf(_sender) >= minBalance);
    }
}

/// @notice This hooks restricts access given a minimum balance of an ERC721 token
contract ERC721OwnershipAllowlistHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    /// ERRORS ///

    error MinBalanceNotHeld();

    /// IMMUTABLES ///

    IERC721 public immutable erc721;
    uint256 public immutable minBalance;

    /// CONSTRUCTOR ///

    constructor(
        IPoolManager _poolManager, 
        IERC721 _erc721,
        uint256 _minBalance
    ) BaseHook(_poolManager) {
        erc721 = _erc721;
        minBalance = _minBalance;
    }

    /// OVERRIDES ///

    function beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external view override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeAddLiquidity.selector;
    }

    function beforeSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external view override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeSwap.selector;
    }

    function beforeDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external view override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeDonate.selector;
    }

    /// INTERNALS ///

    function _senderHoldsMinTokens(address _sender) internal view returns (bool) {
        return (erc721.balanceOf(_sender) >= minBalance);
    }
}

/// @notice This hooks restricts access given a minimum balance of an ERC1155 token
contract ERC1155OwnershipAllowlistHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    /// ERRORS ///

    error MinBalanceNotHeld();

    /// IMMUTABLES ///

    IERC1155 public immutable erc1155;
    uint256 public immutable tokenId;
    uint256 public immutable minBalance;

    /// CONSTRUCTOR ///

    constructor(
        IPoolManager _poolManager, 
        IERC1155 _erc1155,
        uint256 _tokenId,
        uint256 _minBalance
    ) BaseHook(_poolManager) {
        erc1155 = _erc1155;
        tokenId = _tokenId;
        minBalance = _minBalance;
    }

    /// OVERRIDES ///

    function beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external view override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeAddLiquidity.selector;
    }

    function beforeSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external view override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeSwap.selector;
    }

    function beforeDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external view override poolManagerOnly returns (bytes4) {
        if (!_senderHoldsMinTokens(tx.origin)) revert MinBalanceNotHeld();
        return this.beforeDonate.selector;
    }

    /// INTERNALS ///

    function _senderHoldsMinTokens(address _sender) internal view returns (bool) {
        return (erc1155.balanceOf(_sender, tokenId) >= minBalance);
    }
}