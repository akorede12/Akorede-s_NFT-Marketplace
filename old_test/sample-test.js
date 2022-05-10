// const { expect } = require("chai");
// const { ethers } = require("hardhat");

describe("NFTMarket", function () {
  it("should create and execute market sales", async function () {  
    const Market = await ethers.getContractFactory("NFTMarket")
    const market = await Market.deploy()
    await market.deployed()
    // get NFTMarket address 
    const marketAddress = market.adddress
    
    

    const NFT = await ethers.getContractFactory("NFT")
    // pass in NFTMarket address into the NFT contract
    const nft = await NFT.deploy(marketAddress)
    await nft.deployed()
    const nftContractAddress = nft.address 
    
    // get nft listing price
    let listingPrice = await market.getListingPrice()
    // convert listing price to string
    listingPrice = listingPrice.toString()

    // get selling price
    const auctionPrice = ethers.utils.parseUnits("100", "ether")


    /*
    // create NFTS
    // function to create an nft takes an input, whuch is the token uri
    await nft.createToken("https:www.mytokenlocation.com")
    await nft.createToken("https:www.mytokenlocation2.com")
    */

    await nft.createToken("https:www.mytokenlocation.com")
    await nft.createToken("https:www.mytokenlocation2.com")



    // list the token on the NFTMarket place
    // pass in nft address, token id, selling price, 
    // and also the price it would take to list the nft on the market
    await market.createMarketItem(nftContractAddress, 1, auctionPrice, {value: listingPrice })
    await market.createMarketItem(nftContractAddress, 2, auctionPrice, {value: listingPrice })

    // get addresses from different users, using ethers library
    // _ is the first address that is used to deploy the contract, aka the seller 
    // the buyer address is the second address, we want to use this address to buy nfts
    const [_, buyerAddress] = await ethers.getSigners()

    // selling an item on the market place 
    // {value:} is the msg.value, the fee that is sent from a user for the function to take place 
    await market.connect(buyerAddress).createMarketSale(nftContractAddress, 1, {value: auctionPrice})

    // get the nft that a user has purchased
    const items = await market.fetchMarketItems()

    // log items 
    console.log('items: ', items )



  });
});
