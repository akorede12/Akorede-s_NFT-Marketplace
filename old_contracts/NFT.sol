//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";

// import erc721 token standard
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import extension to set token uri 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import Counters utility to keep track of incrementing numbers 
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    // to use Counters utility
    using Counters for Counters.Counter;
    // counter to keep up with an incrementing value for a unique identifier which is tokenId of the NFTs 
    Counters.Counter private _tokenIds;
    // contract address of NFT market place 
    address contractAddress;

    constructor (address marketPlaceAddress) ERC721 ("Metaverse Tokens", "METT") {
        contractAddress = marketPlaceAddress;
    }
    // function for minting new tokens 
    function createToken(string memory tokenURI) public returns(uint) {
        // count and increase the value of corresponding tokens 
        _tokenIds.increment();
        // get current value of tokenId
        uint256 newItemId = _tokenIds.current();
        // mint token 
        _mint(msg.sender, newItemId);
        // set tokenUri
        _setTokenURI(newItemId, tokenURI);
        // give nft market place the ability to transact this token between users, from within another contract
        setApprovalForAll(contractAddress, true);

        return newItemId;
    }
}

