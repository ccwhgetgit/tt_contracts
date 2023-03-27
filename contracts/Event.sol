pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Profile.sol";

contract Event is ERC721 {
    Profile profile;
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
        address prevTicketOwner;
        TicketCategory category; //category within ticket
        uint256 currentPrice;
        bool ticketListing;
    }

    uint256 categoryId;

    mapping(uint256 => TicketCategory) public ticketCategories;
    mapping(uint256 => Ticket) public ticketIDs;
    mapping(address => uint256) public ticketsPerOwner;

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
        string[] memory _categories,
        uint256[] memory _categoryPrices,
        uint256[] memory _categoryLimits,
        string memory _eventName,
        string memory _eventSymbol
    ) public payable ERC721(_eventName, _eventSymbol) {
        profile = Profile(_profile);
        require(
            profile.checkMembership(msg.sender) == true,
            "Not authorized to create a proposal. Sign up on Profile"
        );

        require(
            _categories.length == _categoryPrices.length,
            "Please key in again"
        );
        require(
            _categories.length == _categoryLimits.length,
            "Please key in again"
        );
        categoryId = 1;
        for (uint256 i = 0; i < _categories.length; i++) {
            TicketCategory memory newTicketCategory = TicketCategory(
                _categories[i],
                _categoryPrices[i],
                _categoryLimits[i],
                0
            );
            ticketCategories[categoryId] = newTicketCategory;
            ticketSupply += _categoryLimits[i];
            categoryId += 1;
        }
    }

    function mint(uint256 _category) public payable {
        require(
            profile.checkMembership(msg.sender) == true,
            "Not authorized to create a proposal. Sign up on Profile"
        );

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
            address(0),
            ticketCategories[_category],
            ticketCategories[_category].price,
            false
        );

        _safeMint(msg.sender, newItemId);
        ticketsPerOwner[msg.sender] += 1;
        ticketIDs[newItemId] = newTicket;
        ticketCategories[_category].sold += 1;
        organizer.transfer(ticketCategories[_category].price);
    }

    function transfer(uint256 ticketId, address newOwner)
        public
        isTicketOwner(ticketId)
        validTicketId(ticketId)
    {
        ticketIDs[ticketId].prevTicketOwner = ticketIDs[ticketId].ticketOwner;
        ticketIDs[ticketId].ticketOwner = newOwner;
    }

    function getPreviousOwner(uint256 ticketId)
        public
        view
        validTicketId(ticketId)
        returns (address)
    {
        return ticketIDs[ticketId].prevTicketOwner;
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
