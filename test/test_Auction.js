const truffleAssert = require("truffle-assertions"); // npm truffle-assertions
const BigNumber = require("bignumber.js"); // npm install bignumber.js
var assert = require("assert");
const { profile } = require("console");

var Profile = artifacts.require("../contracts/Profile.sol");
var RentalAgreement = artifacts.require("../contracts/RentalAgreement.sol");
var Auction = artifacts.require("../contracts/Auction.sol");

const oneEth = new BigNumber(1000000000000000000); // 1 eth

contract("Auction", function (accounts) {
  before(async () => {
    profileInstance = await Profile.deployed();
    rentalAgreementInstance = await RentalAgreement.deployed();
    auctionInstance = await Auction.deployed();
  });

  console.log("Testing Auction contract");

  it("Create Profile", async () => {
    let p1 = await profileInstance.createMember({ from: accounts[1] });
    let p2 = await profileInstance.createMember({ from: accounts[2] });

    let checkMembership1 = await profileInstance.checkMembership(accounts[1], {
      from: accounts[1],
    });
    assert.notStrictEqual(p1, undefined, "Failed to make profile");
    assert.strictEqual(checkMembership1, true, "Failed to make profile");
  });

  it("Bid 1 on auction", async () => {});

  it("Bid 2 on auction", async () => {});

  it("End Auction", async () => {});
});
