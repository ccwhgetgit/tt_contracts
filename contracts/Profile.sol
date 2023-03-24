// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Profile {

    address public owner;
    uint256 public goldTierPoints;
    uint256 public silverTierPoints;
    uint256 public bronzeTierPoints;
    uint256 public discountRate;

    enum Tier { Bronze, Silver, Gold }

    struct Member {
        address payable walletAddress;
        Tier tier;
        uint256 points;
    }

    mapping (address => Member) public members;
    mapping(address => bool) public membership; 


    constructor( uint256 goldPoints, uint256 silverPoints, uint256 bronzePoints) {
        owner = payable(msg.sender);
        goldTierPoints = goldPoints;
        silverTierPoints = silverPoints;
        bronzeTierPoints = bronzePoints;
    }

    function createMember() public  {
        require(membership[msg.sender] == false, "Already a member");
        membership[msg.sender] = true;
        members[msg.sender] = Member(payable(msg.sender), Tier.Bronze, 0);
    }

    //for voting -> 2 points, for purchase -> 1 point 
    //for tickets -> 1 point 
    //for rental agreement completion -> 3 point 
    function earnPoints(uint256 amount) public  {
        members[msg.sender].points += amount;
        uint256 updatedPoints = members[msg.sender].points; 
        if (updatedPoints >= goldTierPoints){
            members[msg.sender].tier = Tier.Gold; 
        } else if (updatedPoints >= silverTierPoints){
            members[msg.sender].tier = Tier.Silver; 
        }
    }

    function checkMembership(address _address) public view returns (bool){ 
        return membership[_address];
    }

    
}
