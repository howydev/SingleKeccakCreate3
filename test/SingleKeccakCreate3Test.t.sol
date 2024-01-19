// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { Test } from "forge-std/Test.sol";
import { MockSingleKeccakCreate3 } from "../src/mocks/MockSingleKeccakCreate3.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";

contract SingleKeccakCreate3Test is Test {
    MockERC20 public mockErc20;

    MockSingleKeccakCreate3 public deployer;

    function setUp() public {
        deployer = new MockSingleKeccakCreate3();
        mockErc20 = new MockERC20(5);
    }

    function test_flagsInPointer() public {
        bytes32[] memory bytes32Arr = new bytes32[](1);

        // no storage, no immutable
        deployer.deploy(0, address(mockErc20).code, 0);
        assertEq((uint256(deployer.setupInfo() >> 255)), 0);

        // has storage
        deployer.deployAndSetupStorage(bytes32(uint256(2)), address(mockErc20).code, bytes32Arr, bytes32Arr, 0);
        assertEq((uint256(deployer.setupInfo() >> 255)), 1);
        assertTrue(uint256(deployer.storageArgs()) >= 1);
    }

    function test_deployedHasFunctionality() public {
        MockERC20 a = MockERC20(deployer.deploy(0, address(mockErc20).code, 0));

        assertEq(address(a).code.length, address(mockErc20).code.length);
        assertEq(a.name(), "testErc20");
        assertEq(a.symbol(), "testErc20");
        assertEq(a.balanceOf(address(this)), 0);
    }

    function test_matchDeployedBytecode() public {
        // address.code gives runtime code with immutables already set
        MockERC20 a = MockERC20(deployer.deploy(0, address(mockErc20).code, 0));

        assertEq((address(mockErc20).code).length, (address(a).code).length);
        assertEq(address(mockErc20).code, address(a).code);
    }

    function test_getDeployedAddress(bytes32 r) public {
        address a = deployer.getDeployedAddress(r);
        address b = deployer.deploy(r, address(mockErc20).code, 0);

        assertEq(a, b);
    }

    function test_noStorageOrImmutableVars() public {
        // "creation code" with default values for immutables
        MockERC20 a = new MockERC20(0);

        MockERC20 b = MockERC20(deployer.deploy(0, address(a).code, 0));

        assertEq(b.totalSupply(), 0);
        assertEq(b.balanceOf(address(this)), 0);
    }

    function test_storageVars(uint128 mintAmt) public {
        bytes32[] memory storageSlots = new bytes32[](3);
        storageSlots[0] =
            bytes32(keccak256(abi.encodePacked(bytes32(uint256(uint160(address(this)))), bytes32(uint256(0)))));
        storageSlots[1] = bytes32(uint256(2));
        storageSlots[2] = bytes32(uint256(5));

        bytes32[] memory storageVals = new bytes32[](3);
        storageVals[0] = bytes32(uint256(mintAmt));
        storageVals[1] = bytes32(uint256(mintAmt));
        storageVals[2] = bytes32(uint256(uint160(address(this))));

        MockERC20 b =
            MockERC20(deployer.deployAndSetupStorage(0, address(mockErc20).code, storageVals, storageSlots, 0));

        assertEq(b.totalSupply(), uint256(mintAmt));
        assertEq(b.balanceOf(address(this)), uint256(mintAmt));

        b.mint(address(this), uint256(mintAmt)); // is owner, so can mint
        assertEq(b.totalSupply(), uint256(mintAmt) * 2);
        assertEq(b.balanceOf(address(this)), uint256(mintAmt) * 2);
    }
}
