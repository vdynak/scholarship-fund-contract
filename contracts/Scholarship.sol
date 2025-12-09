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
    uint256 public applicationDuration = 3 days;
    uint256 public votingDuration = 1 days;

    // Round phases: applications open → voting open → round closed
    enum RoundPhase{Applications, Voting, Closed}
    RoundPhase public phase;

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

    // Tracks whether a committee member has already cast their single vote for this round
    mapping(uint256 => mapping(address => bool)) public hasVotedThisRound;

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
        require(_committee.length >= _requiredVotes, "Not enough committee to reach required votes");
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
        phase = RoundPhase.Applications;

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
        // constraint one: if the app period has ended, no more apps could be submitted
        require(phase == RoundPhase.Applications, "Applications are not open");
        require(block.timestamp <= roundStartTime + applicationDuration, "Application period ended");
        // constraint two: prevent incomplete apps from being submitted
        require(!isCommittee[msg.sender], "Committee members cannot apply");
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
    function startVoting() external{
    // will need as transition from app period to voting period
    }

    function vote(uint256 appId) external{
        require(phase == RoundPhase.Voting, "Voting period is not active");
        require(
            block.timestamp <= roundStartTime + applicationDuration + votingDuration, 
            "Voting period ended"
        );
        require(isCommittee[msg.sender], "Only committee can vote");
        require(!hasVotedThisRound[currentRound][msg.sender], "You already voted this round");
        // creates a pointer to the actual application struct in contract storage, when committee votes and we increment voteCount, change is saved permanently, avoid copying data.
        // round 1
        //    - app 1 --> (ipfsHash, applicant, voteCount, exists)
        //    - app 2 --> (ipfsHash, applicant, voteCount, exists)
        Application storage app = applications[currentRound][appId];
        require(app.exists, "Application does not exist");

        // vote happens here
        hasVotedThisRound[currentRound][msg.sender] = true;
        app.voteCount ++;
        emit VoteCast(currentRound, appId, msg.sender);
    }
    


    
    

    

    



    
