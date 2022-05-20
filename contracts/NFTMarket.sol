//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";

// import erc721 token standard
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import security guard to protect against reentrance
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import extension to set token uri 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import Counters utility to keep track of incrementing numbers 
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarket is ReentrancyGuard, ERC721URIStorage {
    // to use Counters utility
    using Counters for Counters.Counter;
    // counter to keep track of Item Ids
    Counters.Counter private _tokenIds;
    // counter to keep track of sold items
    Counters.Counter private _itemsSold;
    
    // owner of the contract 
    address payable owner;
    // listing price of Nfts on marketplace 
    uint256 listingPrice = 0.025 ether; // This is actually Matic because the contract will be deployed to polygon

    constructor() ERC721("Metaverse Tokens", "METT") {
        owner = payable(msg.sender);
    }

    // a struct to define the properties of the market Item
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // A map from itemId to marketItem, to keep up with all the items that have been created  
    mapping(uint256 => MarketItem) private idToMarketItem;
    
    // an event to keep track of when an item is created
    event MarketItemCreated (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );
    // allow the owner of the marketplace to update the listing price 
    function updateListingPrice(uint _listingPrice) public payable {
        require(owner == msg.sender, "only marketplace owner can update the listing price");
        listingPrice = _listingPrice;
    }
    
    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    // Mint a token and list it in the marketplace 
    function createToken(string memory tokenURI, uint256 price) public payable returns(uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    } 

    // function to create market Item
    function createMarketItem(
        uint256 tokenId,
        uint256 price 
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingPrice, "Price must be equal to lisitng price ");

        // update the mapping
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        // Transfer ownership of the nft to the NFTMarket contract
        _transfer(msg.sender, address(this), tokenId);

        // emit event
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false 
        );
    }

    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(idToMarketItem[tokenId].owner == msg.sender, "only item owner can resell token");
        require(msg.value == listingPrice, "Price must be equal to listing price");
        idToMarketItem[tokenId].sold = false; 
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    function createMarketSale (
        uint256 tokenId 
    ) public payable nonReentrant {
        // use mapping to get price of item
        uint price = idToMarketItem[tokenId]. price;
        // use mapping to get token id
        address seller = idToMarketItem[tokenId].seller;
        // require that the payment for the nft is equal to the price 
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        // update owner of nft to msg sender
        idToMarketItem[tokenId].owner = payable(msg.sender);
        // update sale status of nft
        idToMarketItem[tokenId].sold = true;
        // remove seller address of nft
        idToMarketItem[tokenId].seller = payable(address(0));
        // increase number of sold items 
        _itemsSold.increment();
        // trnasfer ownership of nft to buyer
        _transfer(address(this), msg.sender, tokenId);
        // transfer payment of nft
        payable(owner).transfer(listingPrice);
        // receive payment of nft 
        payable(seller).transfer(msg.value);
    }

    // function to view all the items in the marketplace, sold and unsold 
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        // total number of items in  the marketplace
        uint itemCount = _tokenIds.current();
        // total number of unsold items in the marketplace
        uint unSoldItemCount = _tokenIds.current() - _itemsSold.current();
        // a local value to keep track of items in the array below
        uint currentIndex = 0;
        // an array to keep track of unsold items 
        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        // looping over the number of items in the markeplace, if the item hasn't been sold, we store the item in the array.
        for (uint i = 0; i < itemCount; i++) {
            // check to see if item is unsold , if item doesn't have an address linked to it, then it hasn't been sold
            if (idToMarketItem[i + 1].owner == address(this)) {
                // a reference to the Id of a market item
                uint currentId = i + 1;
                // a reference to market item
                MarketItem storage currentItem = idToMarketItem[currentId];
                // storing the local value into the array
                items[currentIndex] = currentItem;
                // increment the local value
                currentIndex += 1;
            }
        }
        // return the array
        return items;
    }
// a function to return the nfts that a user has purchased 
function fetchMyNfts() public view returns(MarketItem[] memory) {
    // total number of items in the market place 
    uint totalItemCount = _tokenIds.current();
    // number of items that belong to a user 
    uint itemCount = 0;
    uint currentIndex = 0;
    // loop to get the total number of items that belong to a user 
    for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
            itemCount += 1;
        }
    }
    // an array to keep track of items that belong to a user 
    MarketItem[] memory items = new MarketItem[] (itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
            uint currentId = i + 1;
            // reference to the current item
            MarketItem storage currentItem = idToMarketItem[currentId];
            // store current item into array
            items[currentIndex] = currentItem;
            // increment item index
            currentIndex += 1;
        }
    }
        // return the items 
        return items;
}
    // function to return all the items created by a user
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            // check to see if the item seller is the caller of the function 
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount +=1;
            }
        }
        MarketItem[] memory items = new MarketItem[] (itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items; 
    }


}

    



