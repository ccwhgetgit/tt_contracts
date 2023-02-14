async function main() {
  const HelloWorld = await ethers.getContractFactory("SimpleEvent");

  // Start deployment, returning a promise that resolves to a contract object
  const hello_world = await HelloWorld.deploy(["a","b"], [1,1], [1,1], "nice", "02021200", "capitol", 1, 1, "yo");   

  //this is just a sample for the constructor 
  //to deploy -> npx hardhat run scripts/deploy.js --network polygon_mumbai
  //then go to arguments.js for instructions on how to verify this contract to interact 
  //on the explorer directly 

  console.log("Contract deployed to address:", hello_world.address);
}

main()
 .then(() => process.exit(0))
 .catch(error => {
   console.error(error);
   process.exit(1);
 });

