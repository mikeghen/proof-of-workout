# Interest Math for Club Pools
This document explains how interest is handled in the club pools.

## Overview
* All stakes are immediately supplied into Aave to earn yields
* A member MUST complete runs and finish the season to earn the interest
* Interest rate is distributed proportionally to members after the season ends

## Stake Deposit and Withdrawal
* During a deposit, USDC is supplied to Aave to earn interest
    * The totalStake amount is updated to checkpoint the total USDC supplied (w/o interest)
* During a withdraw, USDC is withdrawn from Aave and interest is realized as USDC
    * The totalStake - USDC.balanceOf(this) = interest earned for the pool
    * This interest earned is claimed by users on withdraw by proportional distribution to each member
        * i.e. userInterest = interestEarned / finalMemberCount
        * withdraw amount = userStake + userInterest
