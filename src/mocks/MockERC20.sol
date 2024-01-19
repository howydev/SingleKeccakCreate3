// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

import { ERC20 } from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { ShortString, ShortStrings } from "@openzeppelin-contracts/contracts/utils/ShortStrings.sol";
import { Ownable } from "@openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title MockERC20
 * @dev is ownable, uses immutables for ERC20 name()/symbol(), and does mint on creation
 */
contract MockERC20 is ERC20, Ownable {
    /**
     * Storage Layout:
     *  balances in slot 0
     *  totalSupply in slot 2
     *  name in slot 3
     *  symbol in slot 4
     *  owner in slot 5
     */

    using ShortStrings for string;
    using ShortStrings for ShortString;

    ShortString internal immutable $name;
    ShortString internal immutable $symbol;

    function name() public view override returns (string memory) {
        return $name.toString();
    }

    function symbol() public view override returns (string memory) {
        return $symbol.toString();
    }

    constructor(uint256 amt) ERC20("", "") Ownable(msg.sender) {
        $name = string("testErc20").toShortString();
        $symbol = string("testErc20").toShortString();

        _mint(msg.sender, amt);
    }

    function mint(address to, uint256 amt) external onlyOwner {
        _mint(to, amt);
    }
}
