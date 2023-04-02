// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Profile.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Marketplace is ReentrancyGuard {
    Profile profile;
    using SafeMath for uint256;

    address owner = msg.sender;
    uint256 protocolFee = 2;
    address protocolRecipient = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148; //arbitray address

    struct MarketItem {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => MarketItem)) private listings;
    event TicketTransferred(
        address _prevOwner,
        address _newOwner,
        uint256 tokenId
    );
    event ListItem(
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    );
    event UnlistItem(
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );
    event UpdateItem(
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId, 
        uint256 newPrice
    );


    modifier isOwner(address ticketAddress, uint256 tokenId) {
        require(
            IERC721(ticketAddress).ownerOf(tokenId) == msg.sender,
            "Not authorized"
        );
        _;
    }

    // receive address during deployment script
    constructor(address _profile)  {
        profile = Profile(_profile);
    }

    function listItem(
        address ticketAddress,
        uint256 tokenId,
        uint256 price
    ) public isOwner(ticketAddress, tokenId) nonReentrant {
        MarketItem memory listing = listings[ticketAddress][tokenId];
        require(listing.price <= 0, "Already listed");
        listings[ticketAddress][tokenId] = MarketItem(price, msg.sender);
        
        emit ListItem(msg.sender, ticketAddress, tokenId, price);
    }

    function unlistItem(address ticketAddress, uint256 tokenId)
        public
        isOwner(ticketAddress, tokenId)
    {
        delete (listings[ticketAddress][tokenId]);
        emit UnlistItem(msg.sender, ticketAddress, tokenId);
    }

    function buy(address ticketAddress, uint256 tokenId)
        public
        payable
        nonReentrant
    {
        MarketItem memory listedItem = listings[ticketAddress][tokenId];
        require(listedItem.price > 0, "Not listed");
        require(
    msg.value >= SafeMath.mul(listedItem.price, SafeMath.add(1, SafeMath.div(protocolFee, 100))),
    "Not enough"
);
        require(
            IERC721(ticketAddress).getApproved(tokenId) == address(this),
            "Not approved"
        );
        delete (listings[ticketAddress][tokenId]);
        address newOwner = msg.sender;
        address prevOwner = listedItem.seller;
        IERC721(ticketAddress).safeTransferFrom(
            prevOwner,
            newOwner,
            tokenId
        );
        (bool success, ) = payable(newOwner).call{ value: SafeMath.add(listedItem.price, 0) }("");

        require(success, "Transfer failed");
        emit TicketTransferred(prevOwner, newOwner, tokenId);

    }

    function updateListing(
        address ticketAddress,
        uint256 tokenId,
        uint256 newPrice
    ) public isOwner(ticketAddress, tokenId) nonReentrant {
        require(newPrice > 0, "Invalid Price");
        MarketItem memory listing = listings[ticketAddress][tokenId];
        require(listing.price >= 0, "Not listed yet");
        listings[ticketAddress][tokenId].price = newPrice;
        emit  UpdateItem( listing.seller, ticketAddress, tokenId, newPrice);
    }


    function getListingPrice(address ticketAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return listings[ticketAddress][tokenId].price;
    }
}
