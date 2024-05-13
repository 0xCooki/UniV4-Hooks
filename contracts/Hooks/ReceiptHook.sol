// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC1155} from "@openzeppelin/token/ERC1155/ERC1155.sol";
import {PoolId} from "@uniV4/src/types/PoolId.sol";
import {IPoolManager} from "@uniV4/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniV4/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniV4/src/types/PoolId.sol";
import {BalanceDelta} from "@uniV4/src/types/BalanceDelta.sol";
import {BaseHook} from "../BaseHook.sol";

/// @dev This hook mints an NFT receipt in the form of an ERC1155 token after each swap performed on a pool.
contract ReceiptHook is BaseHook, ERC1155 {
    using PoolIdLibrary for PoolKey;

    /// VARIABLES ///

    mapping(PoolId => uint256 tokenId) public poolIdToTokenId;
    mapping(PoolId => bool) public receiptsExists;
    uint256 public nonce;
    
    /// CONSTRUCTOR ///

    constructor(IPoolManager _poolManager, string memory _URI) BaseHook(_poolManager) ERC1155(_URI) {
        nonce = 1;
    }

    /// OVERRIDES ///

    /// @dev Uses tx.origin rather than sender to avoid sending the NFT to a swap router
    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        _setNewPoolToTokenId(key.toId());
        _mint(tx.origin, poolIdToTokenId[key.toId()], 1, "");
        return this.afterSwap.selector;
    }

    /// INTERNALS ///

    function _setNewPoolToTokenId(PoolId keyId) internal {
        if (!receiptsExists[keyId]) {
            poolIdToTokenId[keyId] = nonce;
            nonce++;
            receiptsExists[keyId] = true;
        }
    }
}