// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {IPoolManager} from "@uniV4/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniV4/src/interfaces/IHooks.sol";
import {PoolSwapTest} from "@uniV4/src/test/PoolSwapTest.sol";
import {Deployers} from "@uniV4/test/utils/Deployers.sol";

contract Swap is Test, Deployers {
    function setUp() public {
        initializeManagerRoutersAndPoolsWithLiq(IHooks(address(0)));
    }

    function testSwap() public {
        IPoolManager.SwapParams memory swapParams = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: -100, 
            sqrtPriceLimitX96: SQRT_RATIO_1_2
        });

        PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({
            takeClaims: true, 
            settleUsingBurn: false
        });

        /*
        vm.expectEmit(true, true, true, true);
        emit Swap(
            key.toId(), address(swapRouter), int128(-100), int128(98), 79228162514264329749955861424, 1e18, -1, 3000
        );
        */

        swapRouter.swap(key, swapParams, testSettings, ZERO_BYTES);
    }
}