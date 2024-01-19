// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { MockSingleKeccakCreate3 } from "../src/mocks/MockSingleKeccakCreate3.sol";
import { SingleKeccakCreate3 } from "../src/SingleKeccakCreate3.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { Script, console2 } from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";

/**
 * @title Safe Deploy Demo. Steps:
 * @dev 1. if salt is used
 * @dev 2. deploys an instance locally (this sets up immutable arguments), then copies that bytecode
 * @dev 3. does checks on expected constructor logic (total supply, balances)
 */
contract SafeDeployPatternDemo is Script, SingleKeccakCreate3, Test {
    function run() public {
        // Replace these vars before actually deploying
        bytes32 salt = 0x0;
        address deployerAddr = address(0);
        MockERC20 expected = new MockERC20(5);
        uint256 mintAmt = 5;
        address owner = address(0);

        bytes memory runtimeCode = address(expected).code;

        // gasless salt test
        if (_getDeployedAddress(salt, deployerAddr).code.length > 0) {
            console2.log("Salt already used");
            return;
        }

        MockSingleKeccakCreate3 skc3 = MockSingleKeccakCreate3(deployerAddr);

        vm.startBroadcast();

        bytes32[] memory storageSlots = new bytes32[](2);
        storageSlots[0] = bytes32(keccak256(abi.encodePacked(bytes32(uint256(uint160(owner))), bytes32(uint256(0)))));
        storageSlots[1] = bytes32(uint256(2));

        bytes32[] memory storageVals = new bytes32[](2);
        storageVals[0] = bytes32(mintAmt);
        storageVals[1] = bytes32(mintAmt);

        MockERC20 deployed = MockERC20(skc3.deployAndSetupStorage(salt, runtimeCode, storageVals, storageSlots, 0));

        vm.stopBroadcast();

        // Add tests on the deployed contract
        if (address(deployed).code.length == 0) {
            revert("Deployment failed");
        }

        if (deployed.balanceOf(owner) != 5) {
            revert("Mint failed");
        }

        if (deployed.totalSupply() != 5) {
            revert("Total supply failed");
        }
    }
}
