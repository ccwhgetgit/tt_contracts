// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Profile.sol";
import "./RentalAgreement.sol";

contract Auction {
    // static
    address _owner = msg.sender;
    uint public minIncrement;
    uint public startBlock;
    uint public endBlock;

    // state
    bool public canceled;
    bool public endedSuccessfully;
    uint public highestBindingBid;
    address public highestBidder;
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;

    event BidReceived(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid);
    event WithdrawalDone(address withdrawer, address withdrawalAccount, uint amount);
    event AuctionCancelled();
    event AuctionEnded();

    Profile profile;
    RentalAgreement rentalAgreement;
    address logsAddress;
    uint256 logsId;

    // receive address during deployment script
    constructor(Profile _profile, RentalAgreement _rentalAgreement, address _logsAddress, uint256 _logsId, uint _minIncrement, uint _timeInDays) {
        require(_timeInMilliseconds >= 0, "Time input must be > 0");
        minIncrement = _minIncrement;
        startBlock = block.timestamp;
        endBlock = startBlock + (_timeInDays * 1 days);
        rentalAgreement = _rentalAgreement;
        profile = _profile;
        logsAddress = _logsAddress;
        logsId = _logsId;
    }

    function getHighestBid() public view
        returns (uint)
    {
        return fundsByBidder[highestBidder];
    }

    function placeBid() public
        payable
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotOwner
        returns (bool success)
    {
        require(profile.checkMembership(msg.sender) == true, "Not authorized to place a bid. Sign up on Profile");
        // reject payments of 0 ETH
        require(msg.value > 0);

        uint newBid = fundsByBidder[msg.sender] + msg.value;
        require(newBid > highestBindingBid);

        // grab the previous highest bid (before updating fundsByBidder, in case msg.sender is the
        // highestBidder and is just increasing their maximum bid).
        uint highestBid = fundsByBidder[highestBidder];

        fundsByBidder[msg.sender] = newBid;

        if (newBid <= highestBid) {
            highestBindingBid = min(newBid + minIncrement, highestBid);
        } else {
            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;
                highestBindingBid = min(newBid, highestBid + minIncrement);
            }
            highestBid = newBid;
        }

        emit BidReceived(msg.sender, newBid, highestBidder, highestBid, highestBindingBid);
        return true;
    }

    function min(uint a, uint b)
        private pure
        returns (uint)
    {
        if (a < b) return a;
        return b;
    }

    function endAuction() public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        endedSuccessfully = true;
        emit AuctionEnded();
        return true;
    }

    function cancelAuction() public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        canceled = true;
        emit AuctionCancelled();
        return true;
    }

    function withdraw() public payable
        onlyEndedOrCanceled
        returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];

        } else {
            // the auction finished without being canceled

            if (msg.sender == _owner) {
                // the auction's owner should be allowed to withdraw the highestBindingBid
                withdrawalAccount = highestBidder;
                withdrawalAmount = highestBindingBid;
                ownerHasWithdrawn = true;

                // start a logistics contract with winner address
                rentalAgreement.createRent(highestBidder, block.timestamp, block.timestamp + 7 days, highestBindingBid, logsAddress, logsId);
            } else if (msg.sender == highestBidder) {
                withdrawalAccount = highestBidder;
                if (ownerHasWithdrawn) {
                    withdrawalAmount = fundsByBidder[highestBidder];
                } else {
                    withdrawalAmount = fundsByBidder[highestBidder] - highestBindingBid;
                }

            } else {
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
            }
        }

        require(withdrawalAmount > 0);

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;

        // send funds back
        require(payable(msg.sender).send(withdrawalAmount));

        emit WithdrawalDone(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Only owner");
        _;
    }

    modifier onlyNotOwner {
        require(msg.sender != _owner, "Only not owner");
        _;
    }

    modifier onlyAfterStart {
        require(block.number >= startBlock, "Only after start block");
        _;
    }

    modifier onlyBeforeEnd {
        require(block.number <= endBlock, "Only before end block");
        _;
    }

    modifier onlyNotCanceled {
        require(!canceled, "Only not cancelled");
        _;
    }

    modifier onlyEndedOrCanceled {
        require(block.timestamp > endBlock || endedSuccessfully || canceled, "Only cancelled or ended");
        _;
    }
}