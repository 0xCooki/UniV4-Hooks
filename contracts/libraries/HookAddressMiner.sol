// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice A library that can be used to mine a salt for deploying a hook contract 
///         to a pre-determined address via create2.
/// @dev    The desired address prefix must be 12 bits (1.5 bytes) in length.
library HookAddressMiner {

    /// @notice This function can be used to mine addresses with a desired 12 bit prefix 
    ///         for use as Uniswap V4 hooks.
    /// @param  _bytecodeHash The hashed bytecode of the to-be-deployed smart contract.
    /// @param  _desiredPrefix The desired prefix of the to-be-deployed contract address.
    /// @return bytes32 The mined salt value, 0 if no suitable candidate is found.
    /// @return address The mined address, address(0) if no suitable candidate is found.
    function mineAddress(
        bytes32 _bytecodeHash,
        uint160 _desiredPrefix
    ) external view returns (
        bytes32,
        address
    ) {
        uint160 tempAddress;
        bytes32 salt;

        for (uint256 i; i < 42000; i++) {
            salt = keccak256(abi.encodePacked(i, block.number));

            tempAddress = uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                _bytecodeHash
            ))));

            if (_doesMinedAddressMeetRequirements(tempAddress, _desiredPrefix)) {
                return (salt, address(tempAddress));
            }
        }

        return (0, address(0));
    }

    /// @dev Inspects the first 12 bits of the address; 148 = 160 - 12
    function _doesMinedAddressMeetRequirements(
        uint160 _minedAddress, 
        uint160 _desiredPrefix
    ) internal pure returns (bool) {
        return _minedAddress / (2 ** 148) == _desiredPrefix;
    }
}