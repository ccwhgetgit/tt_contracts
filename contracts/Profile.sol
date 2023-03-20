// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SoulBoundProfile is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Variables
    enum Tier {
        Bronze,
        Silver,
        Gold
    }

    struct User {
        address walletAddress;
        string username;
        string dob;
        uint256 points;
        Tier tier;
    }

    mapping(Tier => uint256) private tiers;
    mapping(Tier => uint256) public tierBenefits; //for discount and promo codes for each tier
    mapping(uint256 => User) private userIDs;
    mapping(string => uint256) private usernameToIndex;
    mapping(address => uint256) private addressToIndex;

    string[] private usernames;
    address[] private addresses;

    function usernameExists(string memory username) public view returns (bool) {
        return (usernameToIndex[username] > 0);
    }

    function addressExists(address userAdddress) public view returns (bool) {
        return (addressToIndex[userAdddress] > 0 ||
            userAdddress == addresses[0]);
    }

    // Events
    event NftMinted(uint256 indexed tokenId, address indexed minter);

    constructor(
        uint256 bronze_points,
        uint256 silver_points,
        uint256 gold_points,
        uint256 bronze_promo,
        uint256 silver_promo,
        uint256 gold_promo
    ) ERC721("SoulBoundProfile", "SBP") {
        address owner = msg.sender;
        //construct the tiers
        tiers[Tier.Gold] = gold_points;
        tiers[Tier.Silver] = silver_points;
        tiers[Tier.Bronze] = bronze_points;
        tierBenefits[Tier.Gold] = gold_promo;
        tierBenefits[Tier.Silver] = silver_promo;
        tierBenefits[Tier.Bronze] = bronze_promo; //for getting the promotions
    }

    function mintProfileToken(
        string memory username,
        string memory dob,
        address to
    ) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        require(!usernameExists(username));
        require(!addressExists(msg.sender));
        User memory newUser = User(msg.sender, username, dob, 0, Tier.Bronze);
        usernames.push(username);
        addresses.push(msg.sender);

        addressToIndex[msg.sender] = addresses.length - 1;
        usernameToIndex[username] = addresses.length - 1;
        userIDs[addresses.length - 1] = newUser;
        _tokenIdCounter.increment();
        emit NftMinted(tokenId, msg.sender);
    }

    function updateUserDetails(
        string memory existing_username,
        string memory new_username,
        string memory new_dob
    ) public returns (bool success) {
        require(addressExists(msg.sender));
        uint256 user_id = usernameToIndex[existing_username];
        require(msg.sender == userIDs[user_id].walletAddress, "Not authorized");
        require(!usernameExists(new_username), "Username already exists");
        User memory updatedUser = User(
            msg.sender,
            new_username,
            new_dob,
            0,
            userIDs[user_id].tier
        );
        userIDs[user_id] = updatedUser;
        return true;
    }

    function getUserCount() public view returns (uint256) {
        return addresses.length;
    }

    /*
    do not allow updating of pointselse need to for loop through all user tiers and update again 
    */
    function pointsUpdate(string memory username, uint256 points_change)
        private
    {
        //private function to update points automatically
        require(usernameExists(username), "Username does not exist");
        uint256 user_id = usernameToIndex[username];
        User memory existing_user = userIDs[user_id];
        uint256 updated_points = userIDs[user_id].points + points_change;
        uint256 bronze_tier_points = tiers[Tier.Bronze];
        uint256 silver_tier_points = tiers[Tier.Silver];
        uint256 gold_tier_points = tiers[Tier.Gold];

        Tier new_tier = Tier.Bronze;

        if (
            (updated_points >= silver_tier_points) &&
            (updated_points < gold_tier_points)
        ) {
            Tier new_tier = Tier.Silver;
        }
        if (updated_points >= gold_tier_points) {
            Tier new_tier = Tier.Gold;
        }

        User memory updatedUser = User(
            existing_user.walletAddress,
            existing_user.username,
            existing_user.dob,
            userIDs[user_id].points + points_change,
            new_tier
        );
        userIDs[user_id] = updatedUser;
    }

    function burn(uint256 tokenId) external {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the owner of the token can burn it."
        );
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal pure {
        require(
            from == address(0) || to == address(0),
            "This a Soulbound Profile token. It cannot be transferred. It can only be burned by the token owner."
        );
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
}
