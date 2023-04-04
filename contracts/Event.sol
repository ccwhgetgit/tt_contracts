// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Profile.sol";
import "./Marketplace.sol";

contract Event is ERC721 {
    using SafeMath for uint256;
    Profile profile;
    Marketplace marketplace;
    using Counters for Counters.Counter;
    Counters.Counter private _ticketIds;

    address payable organizer = payable(msg.sender);
    uint256 ticketSupply;
    uint256 commission = 2;
    struct TicketCategory {
        string categoryName;
        uint256 price;
        uint256 supplyLimit;
        uint256 sold;
    }

    struct Ticket {
        address organizer;
        address ticketOwner;
        TicketCategory category; //category within ticket
        uint256 currentPrice;
        bool ticketListing;
    }

    uint256 categoryId;

    mapping(uint256 => TicketCategory) public ticketCategories;
    mapping(uint256 => Ticket) public ticketIDs;
    mapping(address => uint256) public ticketsPerOwner;
    event TicketMinted(address _owner, uint256 ticketId);
    event TicketTransferred(address _newOwner, uint256 ticketId);

    modifier isTicketOwner(uint256 ticketId) {
        require(
            ticketIDs[ticketId].ticketOwner == msg.sender,
            "Not authorized"
        );
        _;
    }

    modifier isOrganizer() {
        require(organizer == msg.sender, "Not authorized to adjust sale");
        _;
    }

    modifier validTicketId(uint256 id) {
        require(id < ticketSupply);
        _;
    }

    constructor(
        address _profile,
        address _marketplace,
        string[] memory _categories,
        uint256[] memory _categoryPrices,
        uint256[] memory _categoryLimits,
        string memory _eventName,
        string memory _eventSymbol
    ) payable ERC721(_eventName, _eventSymbol) {
        marketplace = Marketplace(_marketplace);
        profile = Profile(_profile);
        require(
            _categories.length == _categoryPrices.length,
            "Please key in again"
        );
        require(
            _categories.length == _categoryLimits.length,
            "Please key in again"
        );
        categoryId = 0;
        for (uint256 i = 0; i < _categories.length; i++) {
            TicketCategory memory newTicketCategory = TicketCategory(
                _categories[i],
                _categoryPrices[i],
                _categoryLimits[i],
                0
            );
            ticketCategories[categoryId] = newTicketCategory;
            ticketSupply = ticketSupply.add(_categoryLimits[i]);
            categoryId += 1;
        }
    }

    function mint(uint256 _category) public payable {
        require(
            ticketCategories[_category].sold <
                ticketCategories[_category].supplyLimit,
            "Not enough tickets available for this category"
        );
        require(
            msg.value >= ticketCategories[_category].price,
            "Not enough ETH sent"
        );
        _ticketIds.increment();
        uint256 newItemId = _ticketIds.current();

        Ticket memory newTicket = Ticket(
            organizer,
            msg.sender,
            ticketCategories[_category],
            ticketCategories[_category].price,
            false
        );

       
         (bool success, ) = payable(organizer).call{
            value:ticketCategories[_category].price
        }("");
        require(success, "Transfer failed");
         _safeMint(msg.sender, newItemId);
        ticketsPerOwner[msg.sender] += 1;
        ticketIDs[newItemId] = newTicket;
        ticketCategories[_category].sold += 1;
        emit TicketMinted(msg.sender, newItemId);
    }

    function getOwner(uint256 ticketId)
        public
        view
        validTicketId(ticketId)
        returns (address)
    {
        return ticketIDs[ticketId].ticketOwner;
    }

    function getCategoryInformation(uint256 category)
        public
        view
        returns (
            uint256 _price,
            uint256 _maxNumber,
            uint256 _currentSupply
        )
    {
        return (
            ticketCategories[category].price,
            ticketCategories[category].supplyLimit,
            ticketCategories[category].sold
        );
    }

    function getTicketPrice(uint256 ticketId)
        public
        view
        validTicketId(ticketId)
        returns (uint256)
    {
        return ticketIDs[ticketId].currentPrice;
    }
}
