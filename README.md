# Saverava White Paper

## Introduction

Saverava merges Strava running clubs with web3 wallets for a unique "run-to-earn" experience. Runners join clubs, stake USDC, and track their progress via Strava. If a runner doesn't meet the club's requirements, they can be slashed by other members, losing their USDC stake, which is then redistributed to compliant members. At the end of the club duration, successful runners can reclaim their stake along with interest and additional rewards, promoting commitment and discipline.

## How It Works

1. **Join a Club**: Runners join a running club through the Saverava application.
2. **Club Requirements**: Each club has specific requirements that members must meet, including:
   - Number of miles to run
   - Frequency of runs (e.g., weekly)
   - Duration (e.g., 3 months)
3. **Staking**: Runners stake a specified amount of USDC to join a club.
4. **Tracking Progress**: Runs are tracked via Strava integration.
5. **Social Slashing**: Members can slash others who do not meet the club's requirements.
6. **Distribution of Stakes**: When a runner is slashed, their stake is distributed proportionally among the remaining members.
7. **End of Duration**: At the end of the club duration, runners who have not been slashed can claim their initial stake plus any interest earned and shares from social slashing.

### A Real Example

#### Scenario

Let's walk through a real example to illustrate how Saverava works. Suppose we have a running club called "10-Mile Challengers" with the following requirements:
- Each member must run at least 10 miles per week.
- The challenge lasts for 3 months.
- Each member stakes 50 USDC to join.

**Members:**
- Alice
- Bob
- Charlie
- Dave (Club Owner)

#### Joining the Club

1. **Alice, Bob, and Charlie** decide to join "10-Mile Challengers."
2. **Alice** stakes 50 USDC and joins the club.
3. **Bob** stakes 50 USDC and joins the club.
4. **Charlie** stakes 50 USDC and joins the club.
5. **Dave** (Club Owner) stakes 50 USDC and joins the club.

#### Running and Tracking

1. Each member uses Strava to track their runs.
2. In the first week, Alice and Bob complete their 10 miles, but Charlie only runs 5 miles.

#### Social Slashing

1. **Alice** notices that **Charlie** did not meet the 10-mile requirement and proposes to slash him.
2. **Bob** also proposes to slash **Charlie** for not meeting the requirement.
3. The smart contract records these proposals and notifies **Dave** (the Club Owner).

#### Club Owner Veto

1. **Dave** reviews the slash proposals.
2. **Dave** decides not to veto the slashing.

#### Slashing Execution

1. Since **Charlie** has been slashed by two members and the club owner did not veto, the smart contract confirms the slashing.
2. **Charlie's** 50 USDC stake is distributed among **Alice**, **Bob**, and **Dave** proportionally.
3. **Alice**, **Bob**, and **Dave** each receive 16.67 USDC from **Charlie's** stake.

#### Completion of Duration

1. At the end of the 3-month duration, **Alice**, **Bob**, and **Dave** have consistently met the 10-mile requirement every week.
2. **Alice**, **Bob**, and **Dave** can claim back their initial 50 USDC stake plus any additional USDC earned from slashing incidents and interest.
3. **Charlie** does not receive any USDC back because he was slashed.

#### Summary

- **Alice, Bob, and Dave** each claim back their initial 50 USDC plus 16.67 USDC from Charlie’s slashing, resulting in a total of 66.67 USDC.
- **Charlie** loses his entire 50 USDC stake due to not meeting the club’s requirements.

This example demonstrates how Saverava's combination of Strava integration, staking, and social slashing mechanisms ensures fair play and rewards consistent runners.

## Application Architecture

### Frontend

**Technology Stack**: Next.js, Typescript, wagmi, Rainbowkit, Coinbase Smart Wallet

**Pages and Components**:
- **Login Page**: Authentication via Strava
- **Dashboard**: Overview of clubs, personal statistics, and upcoming runs
- **Club View**: Details of a specific club, including members and their progress
- **Activity View**: Detailed view of individual activities
- **Profile Page**: User profile and settings

**Components**:
- **ClubCard**: Displays summary of a club
- **RunTracker**: Integrates with Strava API to show run details
- **StakingModal**: Modal for staking USDC to join a club
- **SlashButton**: Allows members to slash non-compliant runners
- **ClaimRewardsButton**: Enables eligible members to claim their rewards at the end of the duration

### Backend

**Technology Stack**: Node.js, Express, MongoDB, Web3.js, Strava API

**Endpoints**:
- **/auth/strava**: Authentication and login through Strava
- **/clubs**: Fetches available clubs and their details
- **/clubs/join**: Endpoint to join a club and stake USDC
- **/clubs/slash**: Endpoint to slash a non-compliant runner
- **/clubs/claim**: Endpoint to claim rewards at the end of the duration
- **/activities**: Fetches activities from Strava

## Sample Smart Contract Interfaces

**Join Pool Contract**:
```solidity
pragma solidity ^0.8.0;

contract ClubPool {
    address public owner;
    uint256 public stakeAmount;
    uint256 public duration;
    uint256 public startTime;
    uint256 public endTime;
    mapping(address => uint256) public stakes;
    mapping(address => bool) public isSlashed;

    constructor(uint256 _stakeAmount, uint256 _duration) {
        owner = msg.sender;
        stakeAmount = _stakeAmount;
        duration = _duration;
        startTime = block.timestamp;
        endTime = block.timestamp + _duration;
    }

    function join() public payable {
        require(msg.value == stakeAmount, "Incorrect stake amount");
        require(block.timestamp < startTime, "Club already started");
        stakes[msg.sender] += msg.value;
    }

    function slash(address _runner) public {
        require(block.timestamp < endTime, "Club already ended");
        require(!isSlashed[_runner], "Runner already slashed");
        isSlashed[_runner] = true;
    }

    function claim() public {
        require(block.timestamp >= endTime, "Club not ended yet");
        require(!isSlashed[msg.sender], "You have been slashed");
        uint256 reward = stakes[msg.sender]; // Calculate rewards
        stakes[msg.sender] = 0;
        payable(msg.sender).transfer(reward);
    }
}
```
## Diagrams

### Join Pool Contract Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant WebApp
    participant SmartContract

    User->>WebApp: Join Club (stakeAmount)
    WebApp->>SmartContract: join()
    SmartContract->>WebApp: Confirm Stake
    WebApp->>User: Confirmation

    alt Incorrect Stake Amount
        SmartContract->>WebApp: Error Message
        WebApp->>User: Display Error
    end

    alt Club Already Started
        SmartContract->>WebApp: Error Message
        WebApp->>User: Display Error
    end
```

### Slash Runner Sequence Diagram

```mermaid
sequenceDiagram
    participant Member1
    participant Member2
    participant WebApp
    participant SmartContract
    participant ClubOwner

    Member1->>WebApp: Slash Runner (runnerAddress)
    WebApp->>SmartContract: proposeSlash(runnerAddress)
    SmartContract->>WebApp: Slash Proposed
    WebApp->>Member1: Slash Proposal Confirmation

    Member2->>WebApp: Slash Runner (runnerAddress)
    WebApp->>SmartContract: proposeSlash(runnerAddress)
    SmartContract->>WebApp: Slash Proposed
    WebApp->>Member2: Slash Proposal Confirmation

    SmartContract->>ClubOwner: Notify Slash Proposal
    ClubOwner->>SmartContract: VetoSlash (optional)

    alt ClubOwner Vetos Slash
        SmartContract->>WebApp: Slash Vetoed
        WebApp->>Member1: Slash Vetoed
        WebApp->>Member2: Slash Vetoed
    else ClubOwner Does Not Veto Slash
        SmartContract->>WebApp: Confirm Slash
        WebApp->>Member1: Slash Confirmation
        WebApp->>Member2: Slash Confirmation
        WebApp->>Runner: You Have Been Slashed
    end

    alt Runner Already Slashed
        SmartContract->>WebApp: Error Message
        WebApp->>Member1: Display Error
        WebApp->>Member2: Display Error
    end

    alt Club Already Ended
        SmartContract->>WebApp: Error Message
        WebApp->>Member1: Display Error
        WebApp->>Member2: Display Error
    end

```

### Claim Rewards Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant WebApp
    participant SmartContract

    User->>WebApp: Claim Rewards
    WebApp->>SmartContract: claim()
    SmartContract->>WebApp: Transfer Rewards
    WebApp->>User: Confirmation

    alt Club Not Ended Yet
        SmartContract->>WebApp: Error Message
        WebApp->>User: Display Error
    end

    alt User Has Been Slashed
        SmartContract->>WebApp: Error Message
        WebApp->>User: Display Error
    end
```

These diagrams outline the key interactions between users, the web application, and the smart contracts for joining a club, slashing a runner, and claiming rewards.

