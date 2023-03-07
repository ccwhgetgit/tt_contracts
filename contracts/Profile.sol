// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.7;

 import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
 import "@openzeppelin/contracts/utils/Counters.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";

 contract Profile is ERC721, Ownable {
     using Counters for Counters.Counter;

     Counters.Counter private _tokenIdCounter;

     // Variables
     enum Tier {Bronze, Silver, Gold}


     struct User{
         address walletAddress;
         string username;
         string dob; 
         uint points; 
         Tier tier;
     }

    mapping(Tier => uint) private tiers; 
    mapping(Tier => uint) public tierBenefits; //for discount and promo codes for each tier 
    mapping(uint256 => User) private userIDs; 
    mapping(string => uint) private usernameToIndex; 
    mapping(address => uint) private addressToIndex;


    string[] private usernames; 
    address[] private addresses;

    function usernameExists (string memory username) public view returns (bool){ 
        return (usernameToIndex[username] > 0 );
    }

    function addressExists (address userAdddress) public view returns (bool){ 
        return (addressToIndex[userAdddress] > 0 || userAdddress == addresses[0]);
    }

    
     // Events
 	  event NftMinted(uint256 indexed tokenId, address indexed minter);

     constructor(uint bronze_points, uint silver_points, uint gold_points, uint bronze_promo, uint silver_promo, uint gold_promo) ERC721("SoulBoundProfile", "SBP") {
         address owner = msg.sender; 
         //construct the tiers 
         tiers[Tier.Gold] = gold_points;
         tiers[Tier.Silver] = silver_points;
         tiers[Tier.Bronze] = bronze_points;
         tierBenefits[Tier.Gold] = gold_promo; 
         tierBenefits[Tier.Silver] = silver_promo; 
         tierBenefits[Tier.Bronze] = bronze_promo;  //for getting the promotions
         usernames.push("Admin"); 
         addresses.push(owner); 
         usernameToIndex["Admin"] = 0; 
         addressToIndex[owner] = 0 ; 
     }

     function mintProfileToken(string memory username, string memory dob) public {
         uint256 tokenId = _tokenIdCounter.current();
         require(usernameToIndex[username] == 0, "Username already exists");
         require(addressToIndex[msg.sender] == 0, "Address already exists");
         User memory newUser = User( 
            msg.sender, username, dob, 0, Tier.Bronze
        ); 
         usernames.push(username); 
         addresses.push(msg.sender); 

         addressToIndex[msg.sender] = addresses.length - 1; 
         usernameToIndex[username] = addresses.length - 1;
         userIDs[addresses.length -1] = newUser;
         _safeMint(msg.sender, tokenId);

         _tokenIdCounter.increment();
         emit NftMinted(tokenId, msg.sender);
     }

     function updateUserDetails( string memory existing_username, string memory new_username, string memory new_dob) public returns(bool success){
        require(addressToIndex[msg.sender] != 0, "Address does not exist");

        uint256 user_id = usernameToIndex[existing_username]; 
        require(msg.sender == userIDs[user_id].walletAddress, "Not authorized");
        require(usernameToIndex[new_username] == 0, "Username already exists");

        User memory updatedUser = User(
            msg.sender, new_username, new_dob,0,  userIDs[user_id].tier
        );
        userIDs[user_id] = updatedUser; 
        return true;
    }  

    function getUserCount() public view returns(uint256){
        return addresses.length;
    }

    function getDetailsOfUser(address address_1) public view returns(User memory){
        uint user_id = addressToIndex[address_1]; 
        return userIDs[user_id];
    }

    /*
    do not allow updating of pointselse need to for loop through all user tiers and update again 
    */
    function pointsUpdate(string memory username, uint points_change) public { 
        //private function to update points automatically
        require(usernameExists(username), "Username does not exist");
        uint256 user_id = usernameToIndex[username]; 
        User memory existing_user = userIDs[user_id];
        uint updated_points = userIDs[user_id].points + points_change; 
        uint silver_tier_points = tiers[Tier.Silver];
        uint gold_tier_points = tiers[Tier.Gold];
    
        Tier new_tier;
        if ((updated_points >= silver_tier_points) && (updated_points < gold_tier_points)){
            new_tier = Tier.Silver; 
        }else if (updated_points >= gold_tier_points){
            new_tier = Tier.Gold; 
        } else{
            new_tier = Tier.Bronze;
        }

        User memory updatedUser = User(
            existing_user.walletAddress, existing_user.username, existing_user.dob, updated_points,  new_tier
        );
        userIDs[user_id] = updatedUser; 

    } 


     function burn(uint256 tokenId) external {
         require(ownerOf(tokenId) == msg.sender, "Only the owner of the token can burn it.");
         _burn(tokenId);
     }

      function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        require(from == address(0), "Token not transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

     function _burn(uint256 tokenId) internal override(ERC721) {
         super._burn(tokenId);
     }

 }