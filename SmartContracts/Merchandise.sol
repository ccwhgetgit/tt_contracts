// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; //for ipfs

contract MerchandiseContract is Ownable, ReentrancyGuard, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable organizer = payable(msg.sender);
    address payable platform; //create our own wallet to collect
    uint256 merchandiseSupply;
    uint256 currentMerchandiseSupply;
    string merchandiseName;
    string dateTime;
    uint256 commission;
    uint256 mintingPlatformFee = 0.02 ether;
    address protocolRecipient = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148; //arbitray address

    struct Category {
        string category;
        uint256 price;
        uint256 maxNumber;
        uint256 currentSupply;
    }

    enum MerchandiseStatus {
        CREATED,
        SALE,
        CANCELLED
    }

    struct Merchandise {
        address organizer;
        address merchandiseOwner;
        Category category; //category within merchandise
        uint256 currentPrice;
        MerchandiseStatus _merchandiseStatus; //enum
    }

    string merchandiseSymbol;
    mapping(string => Category) idToCategoryDetails;
    mapping(uint256 => Merchandise) public merchandiseIDs;
    mapping(address => uint256) public merchandisesPerOwner;

    modifier isMerchandiseOwner(uint256 merchandiseId) {
        require(
            merchandiseIDs[merchandiseId].merchandiseOwner == msg.sender,
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

    event merchandiseMinted(uint256 tokenId, address recipient);
    event merchandiseListed(uint256 tokenId, address user, uint256 price);
    event merchandiseUnlisted(uint256 tokenId, address user);

    constructor(
        string[] memory _categories,
        uint256[] memory _categoryPrices,
        uint256[] memory _categoryLimits,
        string memory _merchandiseName,
        string memory _dateTime,
        uint256 _commission,
        string memory _merchandiseSymbol
    ) public payable ERC721(merchandiseName, _merchandiseSymbol) {
        //
        categories = _categories;
        categoryPrices = _categoryPrices;
        categoryLimits = _categoryLimits;

        merchandiseName = _merchandiseName;
        dateTime = _dateTime;
        merchandiseSymbol = _merchandiseSymbol;
        commission = _commission; //as a percentage
        currentMerchandiseSupply = 0;

        require(
            categories.length == categoryPrices.length,
            "Please key in again"
        );
        require(
            categories.length == categoryLimits.length,
            "Please key in again"
        );
        merchandiseSupply = 0;
        for (uint256 i = 0; i < categories.length; i++) {
            Category memory category_details = Category(
                categories[i],
                categoryPrices[i],
                categoryLimits[i],
                0
            );
            idToCategoryDetails[categories[i]] = category_details;
            merchandiseSupply += categoryLimits[i];
        }

        //transfer listing fee to platform
        (bool success, ) = payable(protocolRecipient).call{
            value: mintingPlatformFee
        }("");
        require(success, "Transfer failed");
    }

    function mint(string memory category)
        public
        payable
        virtual
        returns (uint256)
    {
        require(
            idToCategoryDetails[category].currentSupply <
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
        merchandiseSupply += 1;
        Merchandise memory newMerchandise = Merchandise(
            organizer,
            msg.sender,
            idToCategoryDetails[category],
            idToCategoryDetails[category].price,
            MerchandiseStatus.CREATED
        );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        merchandiseIDs[newItemId] = newMerchandise;
        currentMerchandiseSupply += 1;
        emit merchandiseMinted(newItemId, msg.sender);

        return newItemId;
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

    function merchandiseCancelled() public isOrganizer {
        for (uint256 i = 0; i < currentMerchandiseSupply; i++) {
            merchandiseIDs[i]._merchandiseStatus = MerchandiseStatus.CANCELLED;
        }
    }
}
