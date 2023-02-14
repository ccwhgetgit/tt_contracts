/**
* @type import('hardhat/config').HardhatUserConfig
*/

require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

const { API_URL, PRIVATE_KEY } = process.env;

module.exports = {
   solidity: "0.8.9",
   defaultNetwork: "polygon_mumbai",
   networks: {
      hardhat: {},
      polygon_mumbai: {
         url: API_URL,
         accounts: [`0x${PRIVATE_KEY}`], 
      }

   },
   etherscan:{
      apiKey:
      {
         polygonMumbai: "RRZFZGGV2K9VB7CGAT92981EAPBSSD4RZ7"
      }
   }

}

//polygonMumbai : this is the api key from polygonscan. its the same for testnet 
//private key : get from metamask so u can deploy 
// api_url : alchemy api 