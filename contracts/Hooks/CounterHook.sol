// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PoolId} from "@uniV4/src/types/PoolId.sol";
import {IPoolManager} from "@uniV4/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniV4/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniV4/src/types/PoolId.sol";
import {BalanceDelta} from "@uniV4/src/types/BalanceDelta.sol";
import {BaseHook} from "../BaseHook.sol";

/// @dev This hook (inspired by https://github.com/uniswapfoundation/v4-template/blob/main/src/Counter.sol)
///      counts the number of added liquidity, remove liquidity, swaps, and donates a pool undergoes
contract CounterHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    /// VARIABLES ///

    mapping(PoolId => uint256 count) public addedLiquidityCount;
    mapping(PoolId => uint256 count) public removedLiquidityCount;
    mapping(PoolId => uint256 count) public swappedCount;
    mapping(PoolId => uint256 count) public donatedCount;

    /// CONSTRUCTOR ///

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    /// OVERRIDES ///

    function afterAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        addedLiquidityCount[key.toId()]++;
        return this.afterAddLiquidity.selector;
    }

    function afterRemoveLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        removedLiquidityCount[key.toId()]++;
        return this.afterRemoveLiquidity.selector;
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        swappedCount[key.toId()]++;
        return this.afterSwap.selector;
    }

    function afterDonate(
        address,
        PoolKey calldata key,
        uint256,
        uint256,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        donatedCount[key.toId()]++;
        return this.afterDonate.selector;
    }
}
