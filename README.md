# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```


Contracts -> SimpleEvent.sol 
Scripts -> deploy.js / arguments.js 

* deploy.js : 
- deploy contract -> each time event created, call this file to deploy and fill in the constructor 
- after filling in : 
  -> npx hardhat run scripts/deploy.js --network polygon_mumbai
  then go to arguments.js for instructions on how to verify this contract to interact on the explorer directly 
  
* arguments.js : to help verify the contract 

Arguments to create a new event by posting a new contract with the parameters on chain 

Onece keyed in as a trial, 

npx hardhat verify --constructor-args scripts/arguments.js  0x9c1311eefaBF95c48B20F3BaC2Bbb9e1224D5621
=> where that is the deployed contract address 

This will get the contract verified so you can just test on chain 


  Contract deployment : https://mumbai.polygonscan.com/address/0x9c1311eefaBF95c48B20F3BaC2Bbb9e1224D5621#writeContract 
  Minted : https://mumbai.polygonscan.com/token/0x9c1311eefabf95c48b20f3bac2bbb9e1224d5621#balances
 