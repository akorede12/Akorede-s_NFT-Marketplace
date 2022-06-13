require("@nomiclabs/hardhat-waffle");
require("dotenv").config({ path: ".env" });

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// const testnet_url = process.env.TESTNET_URL;
const TESTNET_PRIVATE_KEY = process.env.TESTNET_PRIVATE_KEY;
const TESTNET_URL = process.env.TESTNET_URL;

const MAINNET_URL = process.env.MAINNET_URL;
const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY;



module.exports = {
  networks: {
    hardhat: {
      chainId: 1337
    },
    mumbai: {
      url: TESTNET_URL,
      accounts: [TESTNET_PRIVATE_KEY]  
    },
  
    /*
    mainnet: {
      url: MAINNET_URL,
      accounts: [MAINNET_PRIVATE_KEY]
    }*/
  },
  solidity: {
    version: "0.8.4",
    settings: {
     optimizer: {
      enabled: true,
      runs: 200
     } 
    }
  }
};
