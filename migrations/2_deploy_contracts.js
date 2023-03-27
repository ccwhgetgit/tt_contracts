const Profile = artifacts.require("Profile");  
const DAO = artifacts.require("DAO");
const Event = artifacts.require("Event");

module.exports = (deployer, network, accounts) => {
    deployer.deploy(Profile,3,2,1).then(function() { 
        return deployer.deploy(DAO, Profile.address)
        
    });
   
};