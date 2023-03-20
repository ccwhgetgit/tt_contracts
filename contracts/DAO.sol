// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proposals {
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
    uint256 public minimumVotes = 10;
    mapping(address => bool) public users;
    mapping(address => mapping(uint256 => bool)) hasVoted;

    event ProposalAdded(uint256 proposalID, string description);
    event Voted(uint256 proposalID, address voter, bool vote);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function createProposal(string memory description) public {
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
        require(hasVoted[msg.sender][proposalID] == false, "Already voted");
        if (choice) {
            proposals[proposalID].positiveVotes += 1;
        } else {
            proposals[proposalID].negativeVotes += 1;
        }
        hasVoted[msg.sender][proposalIDCounter] = true;
        emit Voted(proposalID, msg.sender, choice);
    }

    function endProposal(uint256 proposalID) public onlyOwner {
        require(proposalID < proposals.length - 1, "Invalid proposal");

        Proposal storage proposal = proposals[proposalID];
        uint256 totalVotes = proposal.positiveVotes + proposal.negativeVotes;
        if (totalVotes > minimumVotes) {
            if (proposal.positiveVotes > proposal.negativeVotes) {
                proposal.passed = true;
            } else {
                proposal.passed = false;
            }
        }
    }
}
