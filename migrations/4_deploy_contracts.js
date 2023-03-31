const Profile = artifacts.require("Profile");
const DAO = artifacts.require("DAO");
const Auction = artifacts.require("Auction");
const RentalAgreement = artifacts.require("RentalAgreement");

module.exports = (deployer, network, accounts) => {
  deployer
    .deploy(Profile, 3, 2, 1)
    .then(function () {
      return deployer.deploy(DAO, Profile.address);
    })
    .then(function () {
      return deployer.deploy(RentalAgreement, Profile.address);
    })
    .then(function () {
      // Deploys auction contract with auction of logistics item "1", min increment of 5 and lasting 3 days
      return deployer.deploy(Auction, Profile.address, RentalAgreement.address, 1, 5, 3);
    });
};
