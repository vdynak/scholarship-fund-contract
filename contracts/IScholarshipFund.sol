// IScholarshipFund.sol
// 25 November 2025

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    --------------------------------------------------------------------------
    DRAFT CONSTRUCTOR
    --------------------------------------------------------------------------

    constructor(
        address[] memory _committeeMembers,
        uint256 _requiredYesVotes,
        uint256 _votingDuration
    ) {
        // Initialize committee members
        for (uint256 i = 0; i < _committeeMembers.length; i++) {
            committee[_committeeMembers[i]] = true;
        }

        // Required YES votes to approve a scholarship
        requiredYesVotes = _requiredYesVotes;

        // Length of time students can be voted on (in seconds)
        votingDuration = _votingDuration;
    }
*/

/// @title IScholarshipFund
/// @notice Interface for a decentralized scholarship distribution system.
interface IScholarshipFund {

    // ----------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------

    /// @notice Emitted whenever someone donates ETH into the main pool.
    event DonationMade(address indexed donor, uint256 amount);

    /// @notice Emitted when a student submits their scholarship application.
    event ApplicationSubmitted(
        uint256 indexed applicationId,
        address indexed applicant,
        string ipfsHash
    );

    /// @notice Emitted when a committee member casts a vote on an application.
    event VoteCast(
        uint256 indexed applicationId,
        address indexed voter,
        bool support
    );

    /// @notice Emitted once a winner is selected and funds are paid out.
    event ScholarshipAwarded(
        uint256 indexed applicationId,
        address indexed recipient,
        uint256 amount
    );

    // ----------------------------------------------------------------------
    // Function Signatures
    // ----------------------------------------------------------------------

    /// @notice Anyone can donate ETH to the scholarship pool.
    function donate() external payable;

    /// @notice Allows a student to submit an application with an IPFS hash.
    /// @param ipfsHash  The hash of the application materials.
    /// @return applicationId  The ID assigned to the newly created application.
    function apply(string calldata ipfsHash)
        external
        returns (uint256 applicationId);

    /// @notice Committee members can vote for or against an application.
    function vote(uint256 applicationId, bool support)
        external;

    /// @notice Finalizes an application and pays out the award if it passed.
    /// NOTE: Add responsibility here so that only committee can finalize, review logic
    function finalize(uint256 applicationId)
        external;

    /// @notice Returns details about a specific application.
    function getApplicationInfo(uint256 applicationId)
        external
        view
        returns (
            address applicant,
            uint256 votesFor,
            uint256 votesAgainst,
            string memory ipfsHash
        );
}
