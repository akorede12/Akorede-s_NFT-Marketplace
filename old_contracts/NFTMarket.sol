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
    Counters.Counter private _itemIds;
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
        uint itemId;
        address nftContract;
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
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );
    
    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }
    // function to create market Item
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price 
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingPrice, "Price must be equal to lisitng price ");
        
        // Increase count of itemId
        _itemIds.increment();

        uint256 itemId = _itemIds.current();

        // update the mapping
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
        // Transfer ownership of this nft to the NFTMarket contract
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        // emit event
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false 
        );
    }

    function createMarketSale (
        address nftContract,
        uint256 itemId 
    ) public payable nonReentrant {
        // use mapping to get price of item
        uint price = idToMarketItem[itemId]. price;
        // use mapping to get token id
        uint tokenId = idToMarketItem[itemId].tokenId;
        // require that the payment for the nft is equal to the price 
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        // transfer payment of nft to the seller 
        idToMarketItem[itemId].seller.transfer(msg.value);
        // transfer ownership of the nft to the new buyer 
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        // update owner of the nft in the mapping 
        idToMarketItem[itemId].owner = payable(msg.sender); 
        // update mapping of the nft to be sold
        idToMarketItem[itemId].sold = true;
        // keep track of sold nft items, increase number of sold items by 1
        _itemsSold.increment();
        // pay the owner of the contract, transfer listinprice of nft to the owner of the contract/marketplace 
        payable(owner).transfer(listingPrice);

    }

    // function to view all the items in the marketplace, sold and unsold 
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        // total number of items in  the marketplace
        uint itemCount = _itemIds.current();
        // total number of unsold items in the marketplace
        uint unSoldItemCount = _itemIds.current() - _itemsSold.current();
        // a local value to keep track of items in the array below
        uint currentIndex = 0;
        // an array to keep track of unsold items 
        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        // looping over the number of items in the markeplace, if the item hasn't been sold, we store the item in the array.
        for (uint i = 0; i < itemCount; i++) {
            // check to see if item is unsold , if item doesn't have an address linked to it, then it hasn't been sold
            if (idToMarketItem[i + 1].owner == address(0)) {
                // a reference to the Id of a market item
                uint currentId = idToMarketItem[i + 1].itemId;
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
function fetchMyNfts() public view returns(MarketItem [] memory) {
    // total number of items in the market place 
    uint totalItemCount = _itemIds.current();
    // number of items that belong to a user 
    uint itemCount = 0;
    //
    uint currentIndex = 0;
    // loop to get the total number of items that belong to a user 
    for (uint i = 0; i < itemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
            itemCount += 1;
        }
    }
    // an array to keep track of items that belong to a user 
    MarketItem[] memory items = new MarketItem[] (itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
            uint currentId = idToMarketItem[i + 1].itemId;
            // reference to the current item
            MarketItem storage currentItem = idToMarketItem[currentId];
            // store current item into array
            items[currentIndex] = currentItem;
            // increment item index
            currentIndex += 1;
        }
        // return the items 
        return items;
    }
}
    // function to return all the items created by a user
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
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
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items; 
    }


}

    



