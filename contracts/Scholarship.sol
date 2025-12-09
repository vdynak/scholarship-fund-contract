// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Scholarship{
    event Donated(address indexed donor, unit256 amount);
    event ApplicationSubmitted(uint256 indexed round, uint 256 indexed appId, address indexed applicant, string ipfsHash);
    event VoteCast(uint256 indexed round, uint256 indexed appId, address indexed committeeMember);
    event WinnerSelected(uint256 indexed round, address indexed winner, uint256 amountAwarded);
    event NewRoundStarted(uint256 indexed newRound);

    // committee & config
    mapping(address => bool) public isCommittee;
    uint256 public committeeCount;
    uint256 public requiredVotes;
    uint256 public votingDuration = 3 days;

    // app data
    struct Applicatiion{
        uint256 id;
        address applicant;
        string ipfsHash;
        uint256 voteCount;
        bool exists;
    }

    // Stores all applications for each round.
    // Structure: applications[roundId][applicationId] => Application struct
    mapping(uint256 => mapping(uint256 => Application)) public applications;

    // Tracks how many applications have been submitted in each round.
    // Used to assign new application IDs and to loop through applications when selecting a winner.
    mapping(uint256 => uint256) public applicationsCountByRound;
    
    mapping(uint256 => bool) public roundHasWinner;
    mapping(uint256 => address) public roundWinner;

    // Tracks whether a specific committee member has voted for a specific application in a specific round.
    // Prevents double voting.
    // Structure: hasVoted[roundId][applicationId][voterAddress] => true/false
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public hasVoted;

    // The currently active scholarship round.
    // Increments when the committee starts the next round.
    uint256 public currentRound;

    // The timestamp marking when the current round began.
    // Used to enforce the 3-day voting window: no votes allowed after (roundStartTime + votingDuration).
    uint256 public roundStartTime;


    
    

    

    



    
