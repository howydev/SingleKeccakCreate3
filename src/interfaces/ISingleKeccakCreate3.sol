// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

interface ISingleKeccakCreate3 {
    function setupInfo() external view returns (bytes32);
    function storageArgs() external view returns (bytes32);
}
