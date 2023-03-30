// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Profile.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Marketplace is ReentrancyGuard, IERC721Receiver {
    Profile profile;
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

    event PointsEarned(address member, uint256 points); 

    modifier isOwner(address ticketAddress, uint256 tokenId) {
        require(
            IERC721(ticketAddress).ownerOf(tokenId) == msg.sender,
            "Not authorized"
        );
        _;
    }

    // receive address during deployment script
    constructor(address _profile) public {
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
            msg.value > (listedItem.price * (1 + protocolFee / 100)),
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
        (bool success, ) = payable(newOwner).call{
            value: listedItem.price
        }("");
        require(success, "Transfer failed");
        emit TicketTransferred(prevOwner, newOwner, tokenId);
        profile.earnPoints(newOwner, 3); 
        emit PointsEarned(newOwner, 3);

    }

    function updateListing(
        address ticketAddress,
        uint256 tokenId,
        uint256 newPrice
    ) public isOwner(ticketAddress, tokenId) nonReentrant {
        require(newPrice > 0, "Invalid Price");
        MarketItem memory listing = listings[ticketAddress][tokenId];
        require(listing.price <= 0, "Already listed");
        listings[ticketAddress][tokenId].price = newPrice;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getListing(address ticketAddress, uint256 tokenId)
        public
        view
        returns (MarketItem memory)
    {
        return listings[ticketAddress][tokenId];
    }
}
