// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { ISingleKeccakCreate3 } from "./interfaces/ISingleKeccakCreate3.sol";

contract SingleKeccakCreate3Proxy {
    uint256 private constant _DATA_OFFSET = 1;

    error InvalidPointer();

    /**
     *  // Equivalent ~solidity code
     *
     *     constructor() payable {
     *         bytes32 p = ISingleKeccakCreate3(msg.sender).setupInfo();
     *         bytes memory creationCode = SSTORE2.read(address(uint160(uint256(p))));
     *
     *         p = p >> 255;
     *         if (uint256(p) % 2 == 1) {
     *             (bytes32[] memory storageArgsVals, bytes32[] memory storageArgsLoc) = abi.decode(
     *                 SSTORE2.read(address(uint160(uint256(ISingleKeccakCreate3(msg.sender).storageArgs())))),
     *                 (bytes32[], bytes32[])
     *             );
     *
     *             for (uint256 i = 0; i < storageArgsVals.length; i++) {
     *                 assembly {
     *                     sstore(
     *                         mload(add(storageArgsLoc, add(0x20, mul(i, 0x20)))),
     *                         mload(add(storageArgsVals, add(0x20, mul(i, 0x20))))
     *                     )
     *                 }
     *             }
     *         }
     *
     *         assembly {
     *             return(add(creationCode, 0x20), mload(creationCode))
     *         }
     *     }
     */

    constructor() payable {
        assembly {
            // "setupInfo()"
            mstore(0x00, 0xc0c8e36f)
            pop(call(gas(), caller(), 0, 28, 0x04, 0, 0x20))
            let ptr := mload(0)
            let pointerCodeSize := extcodesize(ptr)
            if iszero(pointerCodeSize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            let size := sub(pointerCodeSize, _DATA_OFFSET)

            let bytecode := mload(0x40)
            mstore(0x40, add(bytecode, and(add(size, 0x3f), 0xffe0)))
            mstore(bytecode, size)
            mstore(add(add(bytecode, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(ptr, add(bytecode, 0x20), _DATA_OFFSET, size)

            // Set up storage if hasStorage flag is set
            if iszero(iszero(shr(255, ptr))) {
                // "storageArgs()"
                mstore(0x00, 0x5601376b)
                pop(call(gas(), caller(), 0, 28, 0x04, 0, 0x20))
                ptr := mload(0)
                pointerCodeSize := extcodesize(ptr)
                if iszero(pointerCodeSize) {
                    // Store the function selector of `InvalidPointer()`.
                    mstore(0x00, 0x11052bb4)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                size := sub(pointerCodeSize, _DATA_OFFSET)

                let storageArgs := mload(0x40)
                mstore(0x40, add(storageArgs, and(add(size, 0x3f), 0xffe0)))
                mstore(storageArgs, size)
                mstore(add(add(storageArgs, 0x20), size), 0) // Zeroize the last slot.
                extcodecopy(ptr, add(storageArgs, 0x20), _DATA_OFFSET, size)

                let valsArrStart := add(storageArgs, 0x60)
                let len := mload(valsArrStart)
                let locArrStart := add(add(valsArrStart, mul(len, 0x20)), 0x20)

                for { ptr := mul(len, 0x20) } ptr { ptr := sub(ptr, 0x20) } {
                    sstore(mload(add(locArrStart, ptr)), mload(add(valsArrStart, ptr)))
                }
            }
            return(add(bytecode, 0x20), mload(bytecode))
        }
    }
}
