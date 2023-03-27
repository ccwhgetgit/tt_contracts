pragma solidity ^0.8.4;

import "./Profile.sol";

contract DAO {
    Profile profile;
    struct Proposal {
        uint256 proposalID;
        string description;
        uint256 positiveVotes;
        uint256 negativeVotes;
        bool passed;
    }

    Proposal[] public proposals;
    address owner = msg.sender;
    uint256 public proposalIDCounter = 0;
    uint256 public minimumVotes = 2;
    mapping(address => bool) public users;
    mapping(address => mapping(uint256 => bool)) hasVoted;

    event ProposalAdded(uint256 proposalID, string description);
    event Voted(uint256 proposalID, address voter, bool vote);
    event EarnPoints(uint256 proposalID, address voter, uint256 votingPower);
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // receive address during deployment script
    constructor(address _profile) public{
        profile = Profile(_profile);
    }


    function createProposal(string memory description) public {
        require(profile.checkMembership(msg.sender) == true, "Not authorized to create a proposal. Sign up on Profile");
        Proposal memory newProposal = Proposal(
            proposalIDCounter,
            description,
            0,
            0,
            false
        );
        proposalIDCounter += 1;
        proposals.push(newProposal);
        emit ProposalAdded(proposalIDCounter, description);
    }

    function vote(uint256 proposalID, bool choice) public {
        require(proposalID < proposals.length, "Invalid proposal");
        require(proposals[proposalID].passed == false, "Proposal has ended");

        require(profile.checkMembership(msg.sender) == true, "Not authorized to create a proposal. Sign up on Profile");
        require(hasVoted[msg.sender][proposalID] == false, "Already voted");
        if (choice) {
            proposals[proposalID].positiveVotes += 1;
        } else {
            proposals[proposalID].negativeVotes += 1;
        }
        hasVoted[msg.sender][proposalID] = true;
        emit Voted(proposalID, msg.sender, choice);
        profile.earnPoints(msg.sender, 2); //update points

    }

    function endProposal(uint256 proposalID) public onlyOwner {
        require(proposalID < proposals.length, "Invalid proposal");

        Proposal storage proposal = proposals[proposalID];
        uint256 totalVotes = proposal.positiveVotes + proposal.negativeVotes;
        require(totalVotes > minimumVotes, "Quorum not reached");
        if (proposal.positiveVotes > proposal.negativeVotes) {
            proposal.passed = true;
        } else {
            proposal.passed = false;
        }
    }
}