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
    mapping(PoolId => uint256 count) public swappededLiquidityCount;
    mapping(PoolId => uint256 count) public DonatedLiquidityCount;

    /// CONSTRUCTOR ///

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    /// OVERRIDES ///

    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override poolManagerOnly returns (bytes4) {
        sender;
        params;
        delta;
        hookData;

        addedLiquidityCount[key.toId()]++;
        return this.afterAddLiquidity.selector;
    }

    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override poolManagerOnly returns (bytes4) {
        sender;
        params;
        delta;
        hookData;

        removedLiquidityCount[key.toId()]++;
        return this.afterRemoveLiquidity.selector;
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override poolManagerOnly returns (bytes4) {
        sender;
        params;
        delta;
        hookData;

        swappededLiquidityCount[key.toId()]++;
        return this.afterSwap.selector;
    }

    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external override poolManagerOnly returns (bytes4) {
        sender;
        amount0;
        amount1;
        hookData;

        DonatedLiquidityCount[key.toId()]++;
        return this.afterDonate.selector;
    }
}
