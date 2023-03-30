const Profile = artifacts.require("Profile");  
const Event = artifacts.require("Event");
const Marketplace = artifacts.require("Marketplace");
module.exports = (deployer, network, accounts) => {
    deployer.deploy(Profile,3,2,1).then(function() { 
        return deployer.deploy(Marketplace, Profile.address)
    }).then(function(){ 
        return deployer.deploy(Event, Marketplace.address, Profile.address, ["VIP", "Normal"], [2,1], [1, 1], "NUS Presentation", "NUS")

    })
    ;
   
};