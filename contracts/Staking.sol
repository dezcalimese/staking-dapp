// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title A staking contract
/// @author Dez Calimese
contract Staking {
    address public owner;

    /// @notice An amount of ether staked at a specific address @ period of time for some length
    /// @param walletAddress address that created the position
    /// @param open boolean showing whether position has been closed or not
    struct Position {
        uint positionId;
        address walletAddress;
        uint createdDate;
        uint unlockDate;
        uint percentInterest;
        uint weiStaked;
        uint weiInterest;
        bool open;
    }

    Position position;

    // increment after each new position is created
    uint public currentPositionId; // increment after each new position is created
    // every newly created position will be added to this mapping,
    // each position will be queryable by the id of the key it's stored under
    mapping(uint => Position) public positions;
    // gives us abilty to query all positions they have created
    mapping(address => uint[]) public positionIdsByAddress;
    // contains data about number of days & interest rate user can stake eth at
    mapping(uint => uint) public tiers;
    // contains different lock periods
    uint[] public lockPeriods;

    constructor() payable {
        owner = msg.sender;
        currentPositionId = 0;

        // 7% apy tier
        tiers[30] = 700;
        // 9% apy tier
        tiers[90] = 1000;
        // 12% apy tier
        tiers[180] = 1200;

        lockPeriods.push(30);
        lockPeriods.push(90);
        lockPeriods.push(180);
    }

    /// @param numDays number of days the ether is being staked for
    function stakeEther(uint numDays) external payable {
        require(tiers[numDays] > 0, "Mapping not found");

        positions[currentPositionId] = Position(
            currentPositionId,
            msg.sender,
            block.timestamp,
            block.timestamp + (numDays * 1 days),
            tiers[numDays], // Interest rate
            msg.value,
            calculateInterest(tiers[numDays], numDays, msg.value),
            true
        );

        // this allows a user to pass in an address and get positions (staked ether) they own
        positionIdsByAddress[msg.sender].push(currentPositionId);
        currentPositionId++;
    }

    function calculateInterest(
        uint basisPoints,
        uint numDays,
        uint weiAmount
    ) private pure returns (uint) {
        return (basisPoints * weiAmount) / 10000;
    }

    /// @notice allows owner to create/edit new lock periods
    function modifyLockPeriods(uint numDays, uint basisPoints) external {
        require(owner == msg.sender, "Only owner may modify staking periods");

        tiers[numDays] = basisPoints;
        lockPeriods.push(numDays);
    }

    function getLockPeriods() external view returns (uint[] memory) {
        return lockPeriods;
    }

    function getInterestRate(uint numDays) external view returns (uint) {
        return tiers[numDays];
    }

    /// @notice lets users query their positions in UI
    function getPositionById(uint positionId)
        external
        view
        returns (Position memory)
    {
        return positions[positionId];
    }

    /// @notice lets users get all positions for address
    function getPositionIdsForAddress(address walletAddress)
        external
        view
        returns (uint[] memory)
    {
        return positionIdsByAddress[walletAddress];
    }

    /// @notice allows owner to change unlock date for a position
    function changeUnlockDate(uint positionId, uint newUnlockDate) external {
        require(owner == msg.sender, "Only owner may modify unlock dates");

        positions[positionId].unlockDate = newUnlockDate;
    }

    /// @notice allows user to unstake ether
    function closePosition(uint positionId) external {
        require(
            positions[positionId].walletAddress == msg.sender,
            "Only position creator may modify position"
        );
        require(positions[positionId].open == true, "Position is closed");

        positions[positionId].open = false;

        // If eth unstaked before unlock date, no interest is earned
        if (block.timestamp > positions[positionId].unlockDate) {
            uint amount = positions[positionId].weiStaked +
                positions[positionId].weiInterest;
            payable(msg.sender).call{value: amount}("");
        } else {
            payable(msg.sender).call{value: positions[positionId].weiStaked}(
                ""
            );
        }
    }
}
