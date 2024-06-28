// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MockERC20.sol";
import "../interfaces/IPool.sol";

contract MockPool is IPool {
    // Reference to the MockERC20 token
    MockERC20 public token;

    // Mapping to keep track of supplied assets by address
    mapping(address => mapping(address => uint256)) private _supplies;

    // Event to log the supply action
    event Supplied(address indexed asset, uint256 amount, address indexed onBehalfOf);

    // Event to log the withdrawal action
    event Withdrawn(address indexed asset, uint256 amount, address indexed to);

    // Constructor to initialize the MockERC20 token
    constructor(MockERC20 _token) {
        token = _token;
    }

    // Function to supply assets to the pool
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 // referralCode
    ) external override {
        require(amount > 0, "Amount must be greater than zero");
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        _supplies[onBehalfOf][asset] += amount;
        token.mint(onBehalfOf, amount);
        emit Supplied(asset, amount, onBehalfOf);
    }

    // Function to withdraw assets from the pool
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external override returns (uint256) {
        uint256 balance = _supplies[msg.sender][asset];
        require(amount <= balance, "Insufficient balance");

        if (amount == type(uint256).max) {
            amount = balance;
        }

        _supplies[msg.sender][asset] -= amount;
        IERC20(asset).transfer(to, amount);
        token.burn(msg.sender, amount);
        emit Withdrawn(asset, amount, to);

        return amount;
    }
}
