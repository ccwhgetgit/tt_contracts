// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Profile.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RentalAgreement {
    using SafeMath for uint256;

    struct RentAgreement {
        uint256 rentId;
        address owner;
        address renter;
        uint256 startDate;
        uint256 endDate;
        uint256 rentalFee;
        uint256 logsId;
        bool isActive;
    }

    mapping(uint256 => RentAgreement) public rentalAgreements;
    mapping(address => uint256[]) public ownerAgreements;
    mapping(address => uint256[]) public renterAgreements;

    uint256 private rentIdCounter = 0;

    modifier onlyActiveAgreement(uint256 _rentId) {
        require(
            rentalAgreements[_rentId].isActive == true,
            "Rent is not active"
        );
        _;
    }

    modifier onlyOwner(uint256 _rentId) {
        require(
            rentalAgreements[_rentId].owner == msg.sender,
            "Not authorized"
        );
        _;
    }

    modifier onlyRenter(uint256 _rentId) {
        require(
            rentalAgreements[_rentId].renter == msg.sender,
            "Not authorized"
        );
        _;
    }

    Profile profile;

    // receive address during deployment script
    constructor(Profile _profile) {
        profile = _profile;
    }


    event RentCreated(
        uint256 rentId,
        address owner,
        address renter,
        uint256 startDate,
        uint256 endDate,
        uint256 rentalFee,
        uint256 logsId
    );
    event RentCancelled(uint256 rentId);
    event RentCompleted(uint256 rentId);

    function createRent(
        address _renter,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _rentalFee,
        uint256 _logsId
    ) external {
        require(_renter != address(0), "Invalid renter address");
        require(_startDate < _endDate, "Invalid rent duration");
        require(_startDate >= block.timestamp, "Invalid start duration");

        rentIdCounter = rentIdCounter.add(1); // use SafeMath for incrementing rentIdCounter


        rentalAgreements[rentIdCounter] = RentAgreement(
            rentIdCounter,
            tx.origin,
            _renter,
            _startDate,
            _endDate,
            _rentalFee,
            _logsId,
            true
        );

        ownerAgreements[tx.origin].push(rentIdCounter);
        renterAgreements[_renter].push(rentIdCounter);

        emit RentCreated(
            rentIdCounter,
            tx.origin,
            _renter,
            _startDate,
            _endDate,
            _rentalFee,
            _logsId
        );
    }

    function cancelAgreement(uint256 _rentId)
        public
        onlyOwner(_rentId)
        onlyActiveAgreement(_rentId)
    {
        rentalAgreements[_rentId].isActive = false;

        emit RentCancelled(_rentId);
    }

    function completeAgreement(
        uint256 _rentId //only by renter who then pays
    ) public payable onlyRenter(_rentId) onlyActiveAgreement(_rentId) {
        rentalAgreements[_rentId].isActive = false;

        // Clock points for renter
        profile.earnPoints(msg.sender, 3);
        emit RentCompleted(_rentId);
    }

    function getOwner(uint256 rentId) public view returns (address) {
        return rentalAgreements[rentId].owner;
    }

    function getRenter(uint256 rentId) public view returns (address) {
        return rentalAgreements[rentId].renter;
    }

    function getOwnerAgreements(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return ownerAgreements[_owner];
    }

    function getRenterAgreements(address _renter)
        public
        view
        returns (uint256[] memory)
    {
        return renterAgreements[_renter];
    }

}