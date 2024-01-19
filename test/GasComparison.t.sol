// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Test } from "forge-std/Test.sol";
import { MockSingleKeccakCreate3 } from "../src/mocks/MockSingleKeccakCreate3.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { CREATE3 } from "@solady/src/utils/CREATE3.sol";

contract GasComparisonTest is Test {
    uint256 mintAmt = 5;
    MockERC20 public mockErc20; // has been deployed by deployer
    MockSingleKeccakCreate3 public deployer;

    function setUp() public {
        deployer = new MockSingleKeccakCreate3();

        bytes32[] memory storageSlots = new bytes32[](1);
        storageSlots[0] = bytes32(uint256(5));
        bytes32[] memory storageVals = new bytes32[](1);
        storageVals[0] = bytes32(uint256(uint160(address(this))));

        mockErc20 = MockERC20(
            deployer.deployAndSetupStorage(0, address(new MockERC20(mintAmt)).code, storageVals, storageSlots, 0)
        );
    }

    function test_soladyCreate3() public {
        bytes memory creationCode = abi.encodePacked(type(MockERC20).creationCode, mintAmt);
        CREATE3.deploy(0, creationCode, 0);
    }

    function test_singleKeccakCreate3() public {
        // mutate storage args a little to force a sstore2 instance
        bytes32[] memory storageSlots = new bytes32[](3);
        storageSlots[0] =
            bytes32(keccak256(abi.encodePacked(bytes32(uint256(uint160(address(this)))), bytes32(uint256(0)))));
        storageSlots[1] = bytes32(uint256(2));
        storageSlots[2] = bytes32(uint256(5));

        bytes32[] memory storageVals = new bytes32[](3);
        storageVals[0] = bytes32(uint256(mintAmt));
        storageVals[1] = bytes32(uint256(mintAmt));
        storageVals[2] = bytes32(uint256(uint160(address(this))));

        // mutate the code a little to force a sstore2 instance
        deployer.deployAndSetupStorage(
            bytes32(uint256(1)), abi.encodePacked(address(mockErc20).code, uint256(1)), storageVals, storageSlots, 0
        );
    }

    function test_singleKeccakCreate3_NoStorage() public {
        // mutate the code a little to force a sstore2 instance
        deployer.deploy(bytes32(uint256(1)), abi.encodePacked(address(mockErc20).code, uint256(1)), 0);
    }

    function test_singleKeccakCreate3_Repeat() public {
        // mutate storage args a little to force a sstore2 instance
        bytes32[] memory storageSlots = new bytes32[](3);
        storageSlots[0] =
            bytes32(keccak256(abi.encodePacked(bytes32(uint256(uint160(address(this)))), bytes32(uint256(0)))));
        storageSlots[1] = bytes32(uint256(2));
        storageSlots[2] = bytes32(uint256(5));

        bytes32[] memory storageVals = new bytes32[](3);
        storageVals[0] = bytes32(uint256(mintAmt));
        storageVals[1] = bytes32(uint256(mintAmt));
        storageVals[2] = bytes32(uint256(uint160(address(this))));

        // no sstore2 instance here
        deployer.deployAndSetupStorage(bytes32(uint256(1)), address(mockErc20).code, storageVals, storageSlots, 0);
    }

    function test_singleKeccakCreate3_NoStorage_Repeat() public {
        // no sstore2 instance here
        deployer.deploy(bytes32(uint256(1)), address(mockErc20).code, 0);
    }
}
