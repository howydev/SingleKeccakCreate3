// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { CREATE3 } from "@solady/src/utils/CREATE3.sol";
import { Create2 } from "@openzeppelin-contracts/contracts/utils/Create2.sol";
import { SingleKeccakCreate3Proxy } from "./SingleKeccakCreate3Proxy.sol";
import { ISingleKeccakCreate3 } from "./interfaces/ISingleKeccakCreate3.sol";

/**
 * @title SingleKeccakCreate3
 * @notice CREATE3 that requires a single keccak256 hash operation to mine
 * @dev 4 deploy modes - no storage, storage, no storage with init calls, storage with init calls
 */
abstract contract SingleKeccakCreate3 is ISingleKeccakCreate3 {
    /**
     * @dev 1st byte: bool hasStorage
     * @dev last 20 bytes: address pointer
     */
    bytes32 public setupInfo;
    bytes32 public storageArgs;

    uint256 internal constant _DATA_OFFSET = 1;

    error DeploymentFailed();
    error AlreadyDeployed();
    error CallFailed(uint256 idx);
    error LengthMismatch();

    /// Private helper methods

    /**
     * @notice Private helper function to set up an SSTORE2 pointer
     * @dev some logic lifted from solady SSTORE2. Uses create2 instead of create
     * @param data contract creation code
     */
    function _setupPointer(bytes memory data) private returns (bytes32 addr) {
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, _DATA_OFFSET)
            mstore(
                // Do a out-of-gas revert if `dataSize` is more than 2 bytes.
                // The actual EVM limit may be smaller and may change over time.
                add(data, gt(dataSize, 0xffff)),
                // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                or(0xfd61000080600a3d393df300, shl(0x40, dataSize))
            )

            dataSize := add(dataSize, 0xa)
            let dataStart := add(data, 0x15)

            // FMP:     00000000_00000000_000000FF_20BYTESADDRESS
            // FMP+32:  salt = 0
            // FMP+64:  initBytecodeHash
            let fmp := mload(0x40)
            mstore(add(fmp, 0x40), keccak256(dataStart, dataSize))
            mstore(fmp, or(shl(160, 0xff), address()))
            addr := shr(96, shl(96, keccak256(add(fmp, 0x0b), 85)))

            // if no code at address, deploy
            if iszero(extcodesize(addr)) {
                let deployedAddr := create2(0, dataStart, dataSize, returndatasize())
                if iszero(deployedAddr) {
                    mstore(0x00, 0x30116425)
                    revert(0x1c, 0x04)
                }
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /**
     * Private helper function to make calls to deployed contracts
     * @param target contract to call
     * @param calldatas array of calldata for calls
     * @param values array of values for calls
     */
    function _call(address target, bytes[] calldata calldatas, uint256[] calldata values) private {
        if (calldatas.length != values.length) {
            revert LengthMismatch();
        }

        uint256 len = calldatas.length;
        for (uint256 i = 0; i < len; i++) {
            (bool success,) = target.call{ value: values[i] }(calldatas[i]);
            if (!success) {
                revert CallFailed(i);
            }
        }
    }

    function _getDeployedAddress(bytes32 salt, address deployer) internal pure returns (address addr) {
        bytes memory proxy = type(SingleKeccakCreate3Proxy).creationCode;
        assembly {
            // layout   :
            // ptr:     00000000_00000000_000000FF_20BYTESADDRESS
            // ptr+32:  salt = 0
            // ptr+64:  initBytecodeHash
            let ptr := mload(0x40)
            mstore(add(ptr, 0x40), keccak256(add(proxy, 0x20), mload(proxy)))
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, or(shl(160, 0xff), deployer))
            addr := keccak256(add(ptr, 0x0b), 85)
        }
    }

    /// Internal Functions

    /**
     * @notice Deploy a contract using single keccak create3
     * @param salt salt for create3
     * @param creationCode contract creation code
     * @param value value to send
     */
    function _deploy(bytes32 salt, bytes calldata creationCode, uint256 value) internal returns (address) {
        // hasStorage = false
        setupInfo = _setupPointer(creationCode);

        return address(new SingleKeccakCreate3Proxy{ salt: salt, value: value }());
    }

    /**
     * @notice Deploy a contract using single keccak create3 then perform specified calls
     * @param salt salt for create3
     * @param creationCode contract creation code
     * @param calldatas array of calldata for calls
     * @param values array of values for calls
     * @param value value to send
     */
    function _deployAndCall(
        bytes32 salt,
        bytes calldata creationCode,
        bytes[] calldata calldatas,
        uint256[] calldata values,
        uint256 value
    )
        internal
        returns (address deployed)
    {
        deployed = _deploy(salt, creationCode, value);
        _call(deployed, calldatas, values);
    }

    /**
     * @notice Deploy a contract using single keccak create3, setup storage
     * @param salt salt for create3
     * @param creationCode contract creation code
     * @param storageArgsVals array of bytes32 storage arguments
     * @param storageArgsLoc array of storage locations to save data into
     * @param value value to send
     */
    function _deployAndSetupStorage(
        bytes32 salt,
        bytes calldata creationCode,
        bytes32[] calldata storageArgsVals,
        bytes32[] calldata storageArgsLoc,
        uint256 value
    )
        internal
        returns (address)
    {
        if (storageArgsVals.length != storageArgsLoc.length) {
            revert LengthMismatch();
        }

        // hasStorage = true
        setupInfo = _setupPointer(creationCode) | bytes32(uint256(1) << 255);
        storageArgs = _setupPointer(abi.encode(storageArgsVals, storageArgsLoc));

        return address(new SingleKeccakCreate3Proxy{ salt: salt, value: value }());
    }

    /**
     * @notice Deploy a contract using single keccak create3, setup storage, then perform specified calls
     * @param salt salt for create3
     * @param creationCode contract creation code
     * @param storageArgsVals array of bytes32 storage arguments
     * @param storageArgsLoc array of storage locations to save data into
     * @param calldatas array of calldata for calls
     * @param values array of values for calls
     * @param value value to send
     */
    function _deployAndSetupStorageAndCall(
        bytes32 salt,
        bytes calldata creationCode,
        bytes32[] calldata storageArgsVals,
        bytes32[] calldata storageArgsLoc,
        bytes[] calldata calldatas,
        uint256[] calldata values,
        uint256 value
    )
        internal
        returns (address deployed)
    {
        deployed = _deployAndSetupStorage(salt, creationCode, storageArgsVals, storageArgsLoc, value);
        _call(deployed, calldatas, values);
    }
}
