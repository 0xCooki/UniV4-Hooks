// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Hooks} from "@uniV4/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniV4/src/interfaces/IPoolManager.sol";
import {HookAddressMiner} from "../contracts/libraries/HookAddressMiner.sol";
import {BaseHook} from "../contracts/BaseHook.sol";

contract TestHookAddressMiner is Test {
    function setUp() public {}

    function testSimpleAddressMiner() public {
        /// @dev Pool manager constructor variable of address(0)
        bytes32 bytecodeHash = keccak256(abi.encodePacked(type(BaseHook).creationCode, abi.encode(address(0))));

        uint160 desiredPrefix = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG |
            Hooks.AFTER_INITIALIZE_FLAG |
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.AFTER_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
            Hooks.AFTER_REMOVE_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG |
            Hooks.BEFORE_DONATE_FLAG |
            Hooks.AFTER_DONATE_FLAG
        ) / (2 ** 148);

        (bytes32 salt, address minedAddress) = HookAddressMiner.mineAddress(bytecodeHash, desiredPrefix);

        if (salt != 0) {
            console2.log("Mined  Address: ", minedAddress);

            BaseHook baseHook = new BaseHook{salt: salt}(IPoolManager(address(0)));

            /// @dev Uniswap Hook validation function
            Hooks.Permissions memory permissions = Hooks.Permissions({
                beforeInitialize: true,
                afterInitialize: true,
                beforeAddLiquidity: true,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: true,
                afterRemoveLiquidity: true,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: true,
                afterDonate: true
            });
            Hooks.validateHookPermissions(baseHook, permissions);

            console2.log("Actual Address: ", address(baseHook));

            assertEq(minedAddress, address(baseHook));
        }
    }
}