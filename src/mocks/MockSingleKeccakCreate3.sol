// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { SingleKeccakCreate3 } from "../SingleKeccakCreate3.sol";

contract MockSingleKeccakCreate3 is SingleKeccakCreate3 {
    function deploy(bytes32 salt, bytes calldata data, uint256 value) external returns (address addr) {
        return _deploy(salt, data, value);
    }

    function deployAndCall(
        bytes32 salt,
        bytes calldata data,
        bytes[] calldata calldatas,
        uint256[] calldata values,
        uint256 value
    )
        external
        returns (address addr)
    {
        return _deployAndCall(salt, data, calldatas, values, value);
    }

    function deployAndSetupStorage(
        bytes32 salt,
        bytes calldata creationCode,
        bytes32[] calldata storageArgsVals,
        bytes32[] calldata storageArgsLoc,
        uint256 value
    )
        external
        returns (address)
    {
        return _deployAndSetupStorage(salt, creationCode, storageArgsVals, storageArgsLoc, value);
    }

    function deployAndSetupStorageAndCall(
        bytes32 salt,
        bytes calldata creationCode,
        bytes32[] calldata storageArgsVals,
        bytes32[] calldata storageArgsLoc,
        bytes[] calldata calldatas,
        uint256[] calldata values,
        uint256 value
    )
        external
        returns (address)
    {
        return
            _deployAndSetupStorageAndCall(salt, creationCode, storageArgsVals, storageArgsLoc, calldatas, values, value);
    }

    function getDeployedAddress(bytes32 salt) external view returns (address) {
        return _getDeployedAddress(salt, address(this));
    }
}
