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
import {BalanceDelta} from "@uniV4/src/types/BalanceDelta.sol";
import {PoolSwapTest} from "@uniV4/src/test/PoolSwapTest.sol";

import {ReceiptHook} from "../contracts/Hooks/ReceiptHook.sol";
import {HookAddressMiner} from "../contracts/libraries/HookAddressMiner.sol";



contract ReceiptHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    ReceiptHook public receiptHook;
    PoolId public poolId0;
    PoolId public poolId1;
    PoolKey public key0;
    PoolKey public key1;

    address public defaultSender = address(uint160(uint256(keccak256("foundry default caller"))));

    function setUp() public {
        /// Deploys environment
        Deployers.deployFreshManagerAndRouters();
        Deployers.deployMintAndApprove2Currencies();

        /// Deploys Hook
        string memory uri = "URI_STRING";
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(ReceiptHook).creationCode,
            abi.encode(address(manager), uri)
        ));
        uint160 desiredPrefix = uint160(Hooks.AFTER_SWAP_FLAG) / (2 ** 148);

        (bytes32 salt, address minedAddress) = HookAddressMiner.mineAddress(bytecodeHash, desiredPrefix);
        receiptHook = new ReceiptHook{salt: salt}(IPoolManager(address(manager)), uri);
        require(address(receiptHook) == minedAddress, "ReceiptHookTest: Failed to mine valid address");

        /// Create 2 pools
        key0 = PoolKey(currency0, currency1, 3000, 60, IHooks(address(receiptHook)));
        poolId0 = key0.toId();
        manager.initialize(key0, SQRT_RATIO_1_1, ZERO_BYTES);

        key1 = PoolKey(currency0, currency1, 3000, 30, IHooks(address(receiptHook)));
        poolId1 = key1.toId();
        manager.initialize(key1, SQRT_RATIO_1_1, ZERO_BYTES);

        /// Provide initial liquidity to each
        modifyLiquidityRouter.modifyLiquidity(key0, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
        modifyLiquidityRouter.modifyLiquidity(key1, IPoolManager.ModifyLiquidityParams(-60, 30, 10 ether), ZERO_BYTES);
    }

    function testInit() public view {
        /// Validate correct hooks
        Hooks.Permissions memory permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false
        });
        Hooks.validateHookPermissions(receiptHook, permissions);

        assertEq(receiptHook.nonce(), 1);
        assertEq(receiptHook.receiptsExists(poolId0), false);
        assertEq(receiptHook.receiptsExists(poolId1), false);
        assertEq(receiptHook.poolIdToTokenId(poolId0), 0);
        assertEq(receiptHook.poolIdToTokenId(poolId1), 0);
    }

    function testSwapAndMint() public {
        
        /// Swap via first pool
        swap(key0, true, 1e18, ZERO_BYTES);

        assertEq(receiptHook.nonce(), 2);
        assertEq(receiptHook.receiptsExists(poolId0), true);
        assertEq(receiptHook.poolIdToTokenId(poolId0), 1);
        assertEq(receiptHook.balanceOf(defaultSender, 1), 1);

        /// Swap via second pool
        swap(key1, true, 1e18, ZERO_BYTES);

        assertEq(receiptHook.nonce(), 3);
        assertEq(receiptHook.receiptsExists(poolId1), true);
        assertEq(receiptHook.poolIdToTokenId(poolId1), 2);
        assertEq(receiptHook.balanceOf(defaultSender, 2), 1);
    }
}