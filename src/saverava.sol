// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title IClubPool Interface
/// @notice Interface for the ClubPool contract
interface IClubPool {
    event Joined(address indexed member, uint256 amount);
    event Slashed(address indexed runner);
    event Vetoed(address indexed runner);
    event Claimed(address indexed member, uint256 amount);

    function join() external payable;
    function startClub() external;
    function proposeSlash(address _runner) external;
    function vetoSlash(address _runner) external;
    function claim() external;
    function totalStakes() external view returns (uint256);
    function isSlashed(address _runner) external view returns (bool);
    function stakes(address _member) external view returns (uint256);
    function slashVotes(address _runner) external view returns (uint256);
}

contract ClubPool is IClubPool {
    IERC20 public usdc;
    uint256 public duration;
    uint256 public endTime;
    uint256 public totalStake;
    bool public started;

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

    constructor(address _usdc, uint256 _duration) {
        usdc = IERC20(_usdc);
        duration = _duration;
    }

    function join() external payable override onlyNotStarted {
        require(usdc.transferFrom(msg.sender, address(this), 50 * 1e6), "USDC transfer failed");
        require(members[msg.sender].stake == 0, "Already a member");

        members[msg.sender] = Member({
            stake: 50 * 1e6,
            slashed: false,
            slashVotes: 0
        });
        memberList.push(msg.sender);
        totalStake += 50 * 1e6;

        emit Joined(msg.sender, 50 * 1e6);
    }

    function startClub() external override onlyNotStarted {
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

    // Add access control Only onwer needed
    function vetoSlash(address _runner) external override onlyStarted {
        require(members[_runner].slashed, "Runner not slashed");

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
}
