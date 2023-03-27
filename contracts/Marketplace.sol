// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Profile.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {
    Profile profile;
    address owner = msg.sender;
    uint256 protocolFee = 2;
    address protocolRecipient = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148; //arbitray address

    struct MarketItem {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => MarketItem)) private listings;

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
    ) public isOwner(ticketAddress, tokenId) {
        MarketItem memory listing = listings[ticketAddress][tokenId];
        require(listing.price <= 0, "Already listed");
        require(
            IERC721(ticketAddress).getApproved(tokenId) == address(this),
            "NFT not approved yet"
        );
        listings[ticketAddress][tokenId] = MarketItem(price, msg.sender);
    }

    function unlistItem(address ticketAddress, uint256 tokenId)
        public
        isOwner(ticketAddress, tokenId)
    {
        delete (listings[ticketAddress][tokenId]);
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
        delete (listings[ticketAddress][tokenId]);
        IERC721(ticketAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            tokenId
        );
        (bool success, ) = payable(listedItem.seller).call{
            value: listedItem.price
        }("");
        require(success, "Transfer failed");
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

    function getListing(address ticketAddress, uint256 tokenId)
        public
        view
        returns (MarketItem memory)
    {
        return listings[ticketAddress][tokenId];
    }
}
