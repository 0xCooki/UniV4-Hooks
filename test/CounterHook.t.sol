// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {IPoolManager} from "@uniV4/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniV4/src/interfaces/IHooks.sol";
import {Deployers} from "@uniV4/test/utils/Deployers.sol";
import {Hooks} from "@uniV4/src/libraries/Hooks.sol";
import {TickMath} from "@uniV4/src/libraries/TickMath.sol";
import {PoolId, PoolIdLibrary} from "@uniV4/src/types/PoolId.sol";
import {PoolKey} from "@uniV4/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniV4/src/types/Currency.sol";

import {CounterHook} from "../contracts/Hooks/CounterHook.sol";
import {HookAddressMiner} from "../contracts/libraries/HookAddressMiner.sol";

contract CounterHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    CounterHook public counterHook;
    PoolId public poolId;

    function setUp() public {
        /// Deploys environment
        Deployers.deployFreshManagerAndRouters();
        Deployers.deployMintAndApprove2Currencies();

        /// Deploys Counter Hook
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(CounterHook).creationCode,
            abi.encode(address(manager)))
        );
        uint160 desiredPrefix = uint160(
            Hooks.AFTER_ADD_LIQUIDITY_FLAG |
            Hooks.AFTER_REMOVE_LIQUIDITY_FLAG |
            Hooks.AFTER_SWAP_FLAG |
            Hooks.AFTER_DONATE_FLAG
        ) / (2 ** 148);

        (bytes32 salt, address minedAddress) = HookAddressMiner.mineAddress(bytecodeHash, desiredPrefix);
        counterHook = new CounterHook{salt: salt}(IPoolManager(address(manager)));
        require(address(counterHook) == minedAddress, "CounterHookTest: Failed to mine valid address");

        /// Create pool
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(address(counterHook)));
        poolId = key.toId();
        manager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        /// Provide initial liquidity
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
    }

    function testTest() public {}
}