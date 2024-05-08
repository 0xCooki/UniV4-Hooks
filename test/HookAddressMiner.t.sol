// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {HookAddressMiner} from "../contracts/libraries/HookAddressMiner.sol";
import {BaseHook} from "../contracts/BaseHook.sol";

contract TestHookAddressMiner is Test {
    function setUp() public {}

    function testSimpleAddressMiner() public {
        /// @dev No constructor vars, just the BaseHook contract
        bytes32 bytecodeHash = keccak256(type(BaseHook).creationCode);

        (bytes32 salt, address minedAddress) = HookAddressMiner.mineAddress(bytecodeHash, 0xFFF);

        if (salt != 0) {
            console2.log("Mined  Address: ", minedAddress);

            BaseHook baseHook = new BaseHook{salt: salt}();

            console2.log("Actual Address: ", address(baseHook));

            assertEq(minedAddress, address(baseHook));
        }
    }
}