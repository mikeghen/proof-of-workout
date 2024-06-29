// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ClubPool} from "./ClubPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClubPoolFactory {
    address[] public deployedPools;
    address public owner;

    event ClubPoolCreated(address poolAddress, uint256 clubId, address usdc, uint256 duration, uint256 requiredDistance, address owner, uint256 stakeAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createClubPool(
        uint256 _clubId,
        address _usdc,
        uint256 _duration,
        uint256 _requiredDistance,
        uint256 _stakeAmount
    ) external onlyOwner {
        ClubPool newPool = new ClubPool(_clubId, _usdc, _duration, _requiredDistance, msg.sender, _stakeAmount);
        deployedPools.push(address(newPool));

        emit ClubPoolCreated(address(newPool), _clubId, _usdc, _duration, _requiredDistance, msg.sender, _stakeAmount);
    }

    function getDeployedPools() external view returns (address[] memory) {
        return deployedPools;
    }
}
