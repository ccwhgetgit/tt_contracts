// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SoulBoundProfile is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Variables
    string internal s_profileUri; // metadata for the Profile

    // Events
	  event NftMinted(uint256 indexed tokenId, address indexed minter);

    constructor(string profileUri /* TBD: parameters */) ERC721("SoulBoundProfile", "SBP") {
        s_profileUri = profileUri;
        
      // TBD: personalizing each token's metadata for the Profile owner
    }

    function mintProfileToken(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);

        string memory metadata = s_profileUri;
        _setTokenURI(tokenId, metadata);

        _tokenIdCounter.increment();
        emit NftMinted(tokenId, msg.sender);
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only the owner of the token can burn it.");
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256) pure override internal {
        require(from == address(0) || to == address(0), "This a Soulbound Profile token. It cannot be transferred. It can only be burned by the token owner.");
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
}