
describe("NFTMarket", function () {
  it("should create and execute market sales", async function () {  
    const Market = await ethers.getContractFactory("NFTMarket")
    const market = await Market.deploy()
    await market.deployed()

    
    // get nft listing price
    let listingPrice = await market.getListingPrice()
    // convert listing price to string
    listingPrice = listingPrice.toString()

    // get selling price
    const auctionPrice = ethers.utils.parseUnits("1", "ether")



    // create NFTS
    await market.createToken("https:www.mytokenlocation.com", auctionPrice, {value : listingPrice} )
    await market.createToken("https:www.mytokenlocation2.com", auctionPrice, {value : listingPrice} )


    // get addresses from different users, using ethers library
    // _ is the first address that is used to deploy the contract, aka the seller 
    // the buyer address is the second address, we want to use this address to buy nfts
    const [_, buyerAddress] = await ethers.getSigners()

    // selling an item on the market place 
    // {value:} is the msg.value, the fee that is sent from a user for the function to take place 
    await market.connect(buyerAddress).createMarketSale( 1, {value: auctionPrice})

   // resell a token 
   await market.connect(buyerAddress).resellToken(1, auctionPrice, {value: listingPrice})

   // query for and return the unsold items 
   items = await market.fetchMarketItems()
   items = await Promise.all(items.map(async i => {
     const tokenUri = await market.tokenURI(i.tokenId)
     let item = {
       price : i.price.toString(),
       tokenId: i.tokenId.toString(),
       seller: i.seller,
       owner: i.owner,
       tokenUri
     }
     return item 
   }))
    // log items 
    console.log('items: ', items )



  })
})
