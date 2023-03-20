// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; //for ipfs


contract Event is Ownable, ReentrancyGuard, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable organizer = payable(msg.sender);
    address payable platform; //create our own wallet to collect
    uint256 ticketSupply;
    uint256 currentTicketSupply;
    string eventName;
    string company;
    string dateTime;
    string venue;
    uint256 commission;
    uint256 maxTicketsPerAddress;
    uint256 mintingPlatformFee = 0.02 ether;
    address payable protocolRecipient =
        payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4); //arbitray address
    bool public eventCancelled;

    string eventSymbol;
    mapping(string => Category) idToCategoryDetails;

    struct Category {
        string category;
        uint256 price;
        uint256 maxNumber;
        uint256 currentSupply;
    }

    mapping(uint256 => Ticket) public ticketIDs;
    mapping(address => uint256) public ticketsPerOwner;

    struct Ticket {
        address organizer;
        address ticketOwner;
        address prevTicketOwner;
        Category category; //category within ticket
        uint256 currentPrice;
        bool ticketListing;
        bool checkIn;
    }

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

    string[] categories;
    uint256[] categoryPrices;
    uint256[] categoryLimits;

    event ticketMinted(uint256 tokenId, address recipient);
    event ticketListed(uint256 tokenId, address user, uint256 price);
    event ticketUnlisted(uint256 tokenId, address user);
    event checkedIn(uint256 tokenId, address user);
    event TicketPurchased(address buyer, uint256 ticketID);
    event EventCancelled(string eventName);

    modifier validTicketId(uint256 id) {
        require(id < ticketSupply);
        _;
    }

    constructor(
        string[] memory _categories,
        uint256[] memory _categoryPrices,
        uint256[] memory _categoryLimits,
        string memory _eventName,
        string memory _dateTime,
        string memory _venue,
        uint256 _commission,
        uint256 _maxTicketPerAddress,
        string memory _eventSymbol
    ) public payable ERC721(_eventName, _eventSymbol) {
        //
        categories = _categories;
        categoryPrices = _categoryPrices;
        categoryLimits = _categoryLimits;

        eventName = _eventName;
        dateTime = _dateTime;
        venue = _venue;
        eventSymbol = _eventSymbol;
        commission = _commission; //as a percentage
        maxTicketsPerAddress = _maxTicketPerAddress;
        currentTicketSupply = 0;
        eventCancelled = false;

        require(
            categories.length == categoryPrices.length,
            "Please key in again"
        );
        require(
            categories.length == categoryLimits.length,
            "Please key in again"
        );
        ticketSupply = 0;
        for (uint256 i = 0; i < categories.length; i++) {
            idToCategoryDetails[categories[i]] = Category(
                categories[i],
                categoryPrices[i],
                categoryLimits[i],
                0
            );
            ticketSupply += categoryLimits[i];
        }

        //transfer listing fee to platform
        (bool success, ) = payable(protocolRecipient).call{
            value: mintingPlatformFee
        }("");
        require(success, "Transfer failed");
    }

    function getTotalSupply() public view returns (uint256) {
        return ticketSupply;
    }

    function mint(string memory category)
        public
        payable
        virtual
        returns (uint256)
    {
        require(!eventCancelled, "Event has been cancelled");
        require(
            ticketsPerOwner[msg.sender] + 1 <= maxTicketsPerAddress,
            "Exceeded Max Minting"
        );
        require(
            idToCategoryDetails[category].currentSupply + 1 <=
                idToCategoryDetails[category].maxNumber,
            "Exceeded Category minting"
        );
        require(
            msg.value >=
                (idToCategoryDetails[category].price *
                    (1 + (commission / 100))),
            "Not enough ETH"
        );
        //if all conditions met, create the ticket, update category numbers
        idToCategoryDetails[category].currentSupply =
            idToCategoryDetails[category].currentSupply +
            1;
        ticketSupply += 1;
        Ticket memory newTicket = Ticket(
            organizer,
            msg.sender,
            address(0),
            idToCategoryDetails[category],
            idToCategoryDetails[category].price,
            false,
            false
        );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        ticketsPerOwner[msg.sender] += 1;
        ticketIDs[newItemId] = newTicket;
        currentTicketSupply += 1;
        emit ticketMinted(newItemId, msg.sender);

        //give commission over and money to owner
        protocolRecipient.transfer((msg.value * commission) / 100);
        organizer.transfer(idToCategoryDetails[category].price);

        return newItemId; //get the newItemId
    }

    function getEventStatus() public view returns (bool) {
        return eventCancelled;
    }

    function buyTicket(uint256 id) public payable {
        require(!eventCancelled, "Event has been cancelled");
        require(
            msg.value >=
                (ticketIDs[id].currentPrice * (1 + (commission / 100))),
            "not enough ETH"
        );
        emit TicketPurchased(msg.sender, id);
        protocolRecipient.transfer((msg.value * commission) / 100);
        organizer.transfer(ticketIDs[id].currentPrice);
        transfer(id, msg.sender);
    }

    function transfer(uint256 id, address newOwner)
        public
        isTicketOwner(id)
        validTicketId(id)
    {
        ticketIDs[id].prevTicketOwner = ticketIDs[id].ticketOwner;
        ticketIDs[id].ticketOwner = newOwner;
    }

    function getPreviousOwner(uint256 id)
        public
        view
        validTicketId(id)
        returns (address)
    {
        return ticketIDs[id].prevTicketOwner;
    }

    function getCategoryInformation(string memory category)
        public
        view
        returns (
            uint256 _price,
            uint256 _maxNumber,
            uint256 _currentSupply
        )
    {
        return (
            idToCategoryDetails[category].price,
            idToCategoryDetails[category].maxNumber,
            idToCategoryDetails[category].currentSupply
        );
    }

    function getCommission() public view returns (uint256) {
        return commission;
    }

    function cancelEvent() public isOrganizer {
        require(!eventCancelled, "Event has already been cancelled");
        eventCancelled = true;
    }

    function getTicketPrice(uint256 id)
        public
        view
        validTicketId(id)
        returns (uint256)
    {
        return ticketIDs[id].currentPrice;
    }
}
