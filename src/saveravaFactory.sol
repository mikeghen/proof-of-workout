// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ClubPool} from "./saverava.sol";
import {IClubPool} from "./interfaces/IClubPool.sol";

/**
 * @title ClubPoolFactory
 * @dev Factory contract to create and manage instances of the ClubPool contract.
 */
contract ClubPoolFactory {
    /// @notice Emitted when a new ClubPool instance is created.
    event ClubPoolCreated(address indexed clubPoolAddress, address indexed creator);

    /// @notice Array to store the addresses of all created ClubPool contracts.
    address[] public clubPools;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    /**
     * @notice Creates a new instance of the ClubPool contract.
     * @param _usdc The address of the USDC token contract.
     * @param _duration The duration for the ClubPool.
     * @return The address of the newly created ClubPool contract.
     */
    function createClubPool(address _usdc, uint256 _duration, address) external onlyOwner returns (address) {
        ClubPool clubPool = new ClubPool(_usdc, _duration, msg.sender);
        clubPools.push(address(clubPool));
        emit ClubPoolCreated(address(clubPool), msg.sender);
        return address(clubPool);
    }

    /**
     * @notice Returns the total number of ClubPool instances created.
     * @return The total number of ClubPool instances.
     */
    function getClubPoolsCount() external view returns (uint256) {
        return clubPools.length;
    }

    /**
     * @notice Returns the address of the ClubPool instance at a specific index.
     * @param index The index of the ClubPool instance.
     * @return The address of the ClubPool instance.
     */
    function getClubPool(uint256 index) external view returns (address) {
        require(index < clubPools.length, "Index out of bounds");
        return clubPools[index];
    }
}
