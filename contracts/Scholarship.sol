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

    // Tracks whether a given address has already applied in the current round.
    // Prevents multiple applications from the same account.
    mapping(uint256 => mapping(address => bool)) public hasApplied;

    // The currently active scholarship round.
    // Increments when the committee starts the next round.
    uint256 public currentRound;

    // The timestamp marking when the current round began.
    // Used to enforce the 3-day voting window: no votes allowed after (roundStartTime + votingDuration).
    uint256 public roundStartTime;

    constructor(address[] memory _committee, uint256 _requiredVotes) payable {
        require(_committee.length > 0, "Need at least one committee member");
        require(_requiredVotes > 0, "requiredVotes must be > 0");
        require(msg.value >= 0.01 ether, "Seed of at least 0.01 ETH required");

        for (uint256 i = 0; i < _committee.length; i++) {
            require(_committee[i] != address(0), "Invalid committee member");
            require(!isCommittee[_committee[i]], "Duplicate committee member");
            isCommittee[_committee[i]] = true;
            committeeCount++;
        }

        requiredVotes = _requiredVotes;
        currentRound = 1;
        roundStartTime = block.timestamp;

        emit NewRoundStarted(currentRound);
    }

    // donation logic, seed = base, donators could contribute more
    // anyone can donate ETH to the pool, requires a pos donation amount 
    function donate() external payable{
        require(msg.value > 0, "Donation must be > 0");
        emit Donated(msg.sender, msg.value);
    }

    // fallback for plain ETH transfers where no func is called; so using wallet, or address(contract).transfer(amount), send() from another contract
    receive() external payable{
        require(msg.value > 0, "Donation must be > 0");
        emit Donated(msg.sender, msg.value);
    }

    // app. logic itself, how to apply?
    function apply(string calldata ipfsHash) external{
        // constraint one: if a winner exists, no more apps could be submitted
        require(!roundHasWinner[currentRound], "Round already closed");
        // constraint two: prevent incomplete apps from being submitted
        require(bytes(ipfsHash).length > 0, "ipfsHash cannot be empty");
        require(!hasApplied[currentRound][msg.sender], "You have already applied this round");
        
        // take the number of apps already submitted and increment by 1
        uint256 newID = applicationsCountByRound[currentRound] + 1;
        applicationsCountByRound[currentRound] = newId;

        applications[currentRound][newId] = Application([
            id: newId,
            applicant: msg.sender,
            ipfsHash: ipfsHash,
            voteCount: 0,
            exists: true
        });
        hasApplied[currentRound][msg.sender] = true;
        // public entry log 
        emit ApplicationSubmitted(currentRound, newId, msg.sender, ipfsHash);
    }

    // voting logic next, winner = first to 10 votes in 3 days, if surpassed, then first to recieve the most amount of votes, in case of tie: ??

    


    
    

    

    



    
