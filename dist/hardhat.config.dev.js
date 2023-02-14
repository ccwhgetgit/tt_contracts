"use strict";

/**
* @type import('hardhat/config').HardhatUserConfig
*/
require('dotenv').config();

require("@nomiclabs/hardhat-ethers");

require("@nomiclabs/hardhat-etherscan");

var _process$env = process.env,
    API_URL = _process$env.API_URL,
    PRIVATE_KEY = _process$env.PRIVATE_KEY;
module.exports = {
  solidity: "0.8.9",
  defaultNetwork: "polygon_mumbai",
  networks: {
    hardhat: {},
    polygon_mumbai: {
      url: API_URL,
      accounts: ["0x".concat(PRIVATE_KEY)]
    }
  },
  etherscan: {
    apiKey: {
      polygonMumbai: "RRZFZGGV2K9VB7CGAT92981EAPBSSD4RZ7"
    }
  }
}; //polygonMumbai : this is the api key from polygonscan. its the same for testnet 
//private key : get from metamask so u can deploy 
// api_url : alchemy api