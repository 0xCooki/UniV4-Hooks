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
import {ERC721} from "@openzeppelin/token/ERC721/ERC721.sol";
import {ERC1155} from "@openzeppelin/token/ERC1155/ERC1155.sol";
import {
    ERC20OwnershipAllowlistHook,
    ERC721OwnershipAllowlistHook,
    ERC1155OwnershipAllowlistHook
} from "../contracts/Hooks/OwnershipAllowlistHooks.sol";
import {HookAddressMiner} from "../contracts/libraries/HookAddressMiner.sol";

/// MOCKS ///

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock", "MOCK") {
        _mint(
            address(uint160(uint256(keccak256("foundry default caller")))), /// @dev default sender
            1e24
        );
    }
}

contract MockERC721 is ERC721 {
    uint256 public nonce;

    constructor() ERC721("Mock", "MOCK") {}

    function mint() external {
        _mint(tx.origin, nonce);
        ++nonce;
    }
}

contract MockERC1155 is ERC1155 {
    constructor() ERC1155("") {}

    function mint(uint256 _tokenId, uint256 _amount) external {
        _mint(tx.origin, _tokenId, _amount, "");
    }
}

/// TESTS ///

contract ERC20OwnershipAllowlistHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    ERC20OwnershipAllowlistHook public erc20AllowlistHook;
    MockERC20 public mockERC20;
    PoolId public poolId;
    address public cooki;
    
    function setUp() public {
        /// Deploys environment
        Deployers.deployFreshManagerAndRouters();
        Deployers.deployMintAndApprove2Currencies();

        cooki = address(420);
        vm.deal(cooki, 1e24);

        /// Deploys Mock ERC20
        mockERC20 = new MockERC20();

        /// Deploys Hook
        /// MinBalance set to 1e18 (1 token)
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(ERC20OwnershipAllowlistHook).creationCode,
            abi.encode(address(manager), mockERC20, 1e18)
        ));
        uint160 desiredPrefix = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.BEFORE_DONATE_FLAG
        ) / (2 ** 148);

        (bytes32 salt, address minedAddress) = HookAddressMiner.mineAddress(bytecodeHash, desiredPrefix);
        erc20AllowlistHook = new ERC20OwnershipAllowlistHook{salt: salt}(IPoolManager(address(manager)), mockERC20, 1e18);
        require(address(erc20AllowlistHook) == minedAddress, "ERC20OwnershipAllowlistHookTest: Failed to mine valid address");

        /// Create pool
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(address(erc20AllowlistHook)));
        poolId = key.toId();
        manager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        /// Provide initial liquidity
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
    }

    function testInit() public view {
        /// Validate correct hooks
        Hooks.Permissions memory permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: true,
            afterDonate: false
        });
        Hooks.validateHookPermissions(erc20AllowlistHook, permissions);

        /// Correct initial counters
        assertEq(address(erc20AllowlistHook.erc20()), address(mockERC20));
        assertEq(erc20AllowlistHook.minBalance(), 1e18);
    }

    function testAddLiquidity() public {
        /// Should Fail
        vm.startPrank(cooki, cooki); /// @dev Sets msg.sender, tx.origin
        vm.expectRevert(ERC20OwnershipAllowlistHook.MinBalanceNotHeld.selector);
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
        vm.stopPrank();

        /// Should suceed
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
    }

    function testSwap() public {
        /// Should Fail
        vm.startPrank(cooki, cooki);
        vm.expectRevert(ERC20OwnershipAllowlistHook.MinBalanceNotHeld.selector);
        swap(key, true, 1e18, ZERO_BYTES);
        vm.stopPrank();

        /// Should suceed
        swap(key, true, 1e18, ZERO_BYTES);
    }

    function testDonate() public {
        /// Should Fail
        vm.startPrank(cooki, cooki);
        vm.expectRevert(ERC20OwnershipAllowlistHook.MinBalanceNotHeld.selector);
        donateRouter.donate(key, 0, 0, ZERO_BYTES);
        vm.stopPrank();

        /// Should suceed
        donateRouter.donate(key, 0, 0, ZERO_BYTES);
    }
}

contract ERC721OwnershipAllowlistHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    ERC721OwnershipAllowlistHook public erc721AllowlistHook;
    MockERC721 public mockERC721;
    PoolId public poolId;
    address public cooki;
    
    function setUp() public {
        /// Deploys environment
        Deployers.deployFreshManagerAndRouters();
        Deployers.deployMintAndApprove2Currencies();

        cooki = address(420);
        vm.deal(cooki, 1e24);

        /// Deploys Mock ERC20
        mockERC721 = new MockERC721();
        mockERC721.mint();

        /// Deploys Hook
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(ERC721OwnershipAllowlistHook).creationCode,
            abi.encode(address(manager), mockERC721, 1)
        ));
        uint160 desiredPrefix = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.BEFORE_DONATE_FLAG
        ) / (2 ** 148);

        (bytes32 salt, address minedAddress) = HookAddressMiner.mineAddress(bytecodeHash, desiredPrefix);
        erc721AllowlistHook = new ERC721OwnershipAllowlistHook{salt: salt}(IPoolManager(address(manager)), mockERC721, 1);
        require(address(erc721AllowlistHook) == minedAddress, "ERC721OwnershipAllowlistHookTest: Failed to mine valid address");

        /// Create pool
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(address(erc721AllowlistHook)));
        poolId = key.toId();
        manager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        /// Provide initial liquidity
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
    }

    function testInit() public view {
        /// Validate correct hooks
        Hooks.Permissions memory permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: true,
            afterDonate: false
        });
        Hooks.validateHookPermissions(erc721AllowlistHook, permissions);

        /// Correct initial counters
        assertEq(address(erc721AllowlistHook.erc721()), address(mockERC721));
        assertEq(erc721AllowlistHook.minBalance(), 1);
    }

    function testAddLiquidity() public {
        /// Should Fail
        vm.startPrank(cooki, cooki); /// @dev Sets msg.sender, tx.origin
        vm.expectRevert(ERC721OwnershipAllowlistHook.MinBalanceNotHeld.selector);
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
        vm.stopPrank();

        /// Should suceed
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
    }

    function testSwap() public {
        /// Should Fail
        vm.startPrank(cooki, cooki);
        vm.expectRevert(ERC721OwnershipAllowlistHook.MinBalanceNotHeld.selector);
        swap(key, true, 1e18, ZERO_BYTES);
        vm.stopPrank();

        /// Should suceed
        swap(key, true, 1e18, ZERO_BYTES);
    }

    function testDonate() public {
        /// Should Fail
        vm.startPrank(cooki, cooki);
        vm.expectRevert(ERC721OwnershipAllowlistHook.MinBalanceNotHeld.selector);
        donateRouter.donate(key, 0, 0, ZERO_BYTES);
        vm.stopPrank();

        /// Should suceed
        donateRouter.donate(key, 0, 0, ZERO_BYTES);
    }
}

contract ERC1155OwnershipAllowlistHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    ERC1155OwnershipAllowlistHook public erc1155AllowlistHook;
    MockERC1155 public mockERC1155;
    PoolId public poolId;
    address public cooki;
    
    function setUp() public {
        /// Deploys environment
        Deployers.deployFreshManagerAndRouters();
        Deployers.deployMintAndApprove2Currencies();

        cooki = address(420);
        vm.deal(cooki, 1e24);

        /// Deploys Mock ERC20
        mockERC1155 = new MockERC1155();
        mockERC1155.mint(0, 1e24); /// Allowlist asset

        /// Deploys Hook
        /// MinBalance set to 1e18 (1 token) of token id 0
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(ERC1155OwnershipAllowlistHook).creationCode,
            abi.encode(address(manager), mockERC1155, 0, 1e18)
        ));
        uint160 desiredPrefix = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.BEFORE_DONATE_FLAG
        ) / (2 ** 148);

        (bytes32 salt, address minedAddress) = HookAddressMiner.mineAddress(bytecodeHash, desiredPrefix);
        erc1155AllowlistHook = new ERC1155OwnershipAllowlistHook{salt: salt}(IPoolManager(address(manager)), mockERC1155, 0, 1e18);
        require(address(erc1155AllowlistHook) == minedAddress, "ERC721OwnershipAllowlistHookTest: Failed to mine valid address");

        /// Create pool
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(address(erc1155AllowlistHook)));
        poolId = key.toId();
        manager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        /// Provide initial liquidity
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
    }

    function testInit() public view {
        /// Validate correct hooks
        Hooks.Permissions memory permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: true,
            afterDonate: false
        });
        Hooks.validateHookPermissions(erc1155AllowlistHook, permissions);

        /// Correct initial counters
        assertEq(address(erc1155AllowlistHook.erc1155()), address(mockERC1155));
        assertEq(erc1155AllowlistHook.minBalance(), 1e18);
    }

    function testAddLiquidity() public {
        /// Should Fail
        vm.startPrank(cooki, cooki); /// @dev Sets msg.sender, tx.origin
        vm.expectRevert(ERC1155OwnershipAllowlistHook.MinBalanceNotHeld.selector);
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
        vm.stopPrank();

        /// Should suceed
        modifyLiquidityRouter.modifyLiquidity(key, IPoolManager.ModifyLiquidityParams(-60, 60, 10 ether), ZERO_BYTES);
    }

    function testSwap() public {
        /// Should Fail
        vm.startPrank(cooki, cooki);
        vm.expectRevert(ERC1155OwnershipAllowlistHook.MinBalanceNotHeld.selector);
        swap(key, true, 1e18, ZERO_BYTES);
        vm.stopPrank();

        /// Should suceed
        swap(key, true, 1e18, ZERO_BYTES);
    }

    function testDonate() public {
        /// Should Fail
        vm.startPrank(cooki, cooki);
        vm.expectRevert(ERC1155OwnershipAllowlistHook.MinBalanceNotHeld.selector);
        donateRouter.donate(key, 0, 0, ZERO_BYTES);
        vm.stopPrank();

        /// Should suceed
        donateRouter.donate(key, 0, 0, ZERO_BYTES);
    }
}