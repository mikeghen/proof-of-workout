// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IClubPool} from "./interfaces/IClubPool.sol";

/// @title IClubPool Interface
/// @notice Interface for the ClubPool contract

contract ClubPool is IClubPool {
    IERC20 public usdc;
    uint256 public duration;
    uint256 public endTime;
    uint256 individualStake;
    uint256 public totalStake;
    bool public started;
    address owner;

    struct Member {
        uint256 stake;
        bool slashed;
        uint256 slashVotes;
    }

    mapping(address => Member) public members;
    address[] public memberList;

    modifier onlyStarted() {
        require(started, "Club has not started yet");
        _;
    }

    modifier onlyNotStarted() {
        require(!started, "Club has already started");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    constructor(address _usdc, uint256 _duration, address _owner, uint256 _stakeAmount) {
        usdc = IERC20(_usdc);
        duration = _duration;
        owner = _owner;
        individualStake = _stakeAmount;
    }


    /**
     * @notice Allows a user to join the club by staking a specific amount of USDC.
     * @dev Transfers the specified amount of USDC from the caller to the contract.
     */
    function join() external payable override onlyNotStarted {
        require(members[msg.sender].stake == 0, "Already a member");
        require(usdc.transferFrom(msg.sender, address(this), individualStake), "USDC transfer failed");

        members[msg.sender] = Member({
            stake: individualStake,
            slashed: false,
            slashVotes: 0
        });
        memberList.push(msg.sender);
        totalStake += individualStake;

        emit Joined(msg.sender, individualStake);
    }

    function startClub() external override onlyNotStarted onlyOwner {
        started = true;
        endTime = block.timestamp + duration;
    }

    function proposeSlash(address _runner) external override onlyStarted {
        require(members[msg.sender].stake > 0, "Not a member");
        require(!members[_runner].slashed, "Runner already slashed");

        members[_runner].slashVotes += 1;

        if (members[_runner].slashVotes >= 2) {
            members[_runner].slashed = true;
            totalStake -= members[_runner].stake;

            uint256 share = members[_runner].stake / (memberList.length - 1);
            for (uint256 i = 0; i < memberList.length; i++) {
                if (memberList[i] != _runner) {
                    members[memberList[i]].stake += share;
                }
            }

            emit Slashed(_runner);
        }
    }

    function vetoSlash(address _runner) external override onlyStarted onlyOwner {
        require(members[_runner].slashed = true, "Runner not slashed");

        members[_runner].slashed = false;
        members[_runner].slashVotes = 0;

        emit Vetoed(_runner);
    }

    function claim() external override onlyStarted {
        require(block.timestamp >= endTime, "Club duration not ended");
        require(!members[msg.sender].slashed, "You have been slashed");

        uint256 amount = members[msg.sender].stake;
        members[msg.sender].stake = 0;

        require(usdc.transfer(msg.sender, amount), "USDC transfer failed");

        emit Claimed(msg.sender, amount);
    }

    function totalStakes() external view override returns (uint256) {
        return totalStake;
    }

    function isSlashed(address _runner) external view override returns (bool) {
        return members[_runner].slashed;
    }

    function stakes(address _member) external view override returns (uint256) {
        return members[_member].stake;
    }

    function slashVotes(address _runner) external view override returns (uint256) {
        return members[_runner].slashVotes;
    }

    /**
     * @notice Records an activity for a member.
     * @param userId The ID of the user.
     * @param activityId The ID of the activity.
     * @param distance The distance covered in the activity.
     * @param time The time taken for the activity.
     */
    function recordActivity(uint256 userId, uint256 activityId, uint256 distance, uint256 time) external override {
        // Implementation for recording activity
        emit ActivityRecorded(userId, activityId, distance, time);
    }
}
