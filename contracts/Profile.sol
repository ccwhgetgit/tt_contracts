// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Profile {
    using SafeMath for uint256;

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

    function earnPoints(address _address, uint256 amount) public {
        members[_address].points = members[_address].points.add(amount);
        uint256 updatedPoints = members[_address].points;
        if (updatedPoints >= goldTierPoints){
            members[_address].tier = Tier.Gold; 
        } else if (updatedPoints >= silverTierPoints){
            members[_address].tier = Tier.Silver; 
    }
}

    function checkPoints(address _address) public view returns(uint256){
        return members[_address].points;
    }

    function checkMembership(address _address) public view returns (bool){ 
        return membership[_address];
    }

    
}