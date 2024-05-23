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

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {
    ERC20OwnershipAllowlistHook
} from "../contracts/Hooks/OwnershipAllowlistHooks.sol";
import {HookAddressMiner} from "../contracts/libraries/HookAddressMiner.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock", "MOCK") {
        _mint(
            address(uint160(uint256(keccak256("foundry default caller")))), /// @dev default sender
            10e24
        );
    }
}

contract ERC20OwnershipAllowlistHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    ERC20OwnershipAllowlistHook public erc20AllowlistHook;
    ERC20 public mockERC20;
    PoolId public poolId;
    
    function setUp() public {
        /// Deploys environment
        Deployers.deployFreshManagerAndRouters();
        Deployers.deployMintAndApprove2Currencies();

        /// Deploys Mock ERC20
        mockERC20 = new MockERC20();

        /// Deploys Hook
        /// MinBalance set to 1e18 (1 token)
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(ERC20OwnershipAllowlistHook).creationCode,
            abi.encode(address(manager), mockERC20, 10e18)
        ));
        uint160 desiredPrefix = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.BEFORE_DONATE_FLAG
        ) / (2 ** 148);

        (bytes32 salt, address minedAddress) = HookAddressMiner.mineAddress(bytecodeHash, desiredPrefix);
        erc20AllowlistHook = new ERC20OwnershipAllowlistHook{salt: salt}(IPoolManager(address(manager)), mockERC20, 10e18);
        require(address(erc20AllowlistHook) == minedAddress, "ERC20OwnershipAllowlistHookTest: Failed to mine valid address");

        /// Create pool
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(address(erc20AllowlistHook)));
        poolId = key.toId();
        manager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        /// Provide initial liquidity
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
    }

    function testInit() public {

    }
}