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

  console.log("Testing Auction and Rental Agreeement contract");

  it("Create Profile", async () => {
    let pOwner = await profileInstance.createMember({ from: accounts[0] });
    let p1 = await profileInstance.createMember({ from: accounts[1] });
    let p2 = await profileInstance.createMember({ from: accounts[2] });

    let checkMembership1 = await profileInstance.checkMembership(accounts[1], {
      from: accounts[1],
    });
    assert.notStrictEqual(p1, undefined, "Failed to make profile");
    assert.strictEqual(checkMembership1, true, "Failed to make profile");
  });

  it("Ensure bidder is a member", async () => {
    await truffleAssert.reverts(
      auctionInstance.placeBid({ from: accounts[3], value: oneEth.dividedBy(10) }),
      "Not authorized to place a bid. Sign up on Profile"
    );
  });

  it("Bid 1 on auction", async () => {
    let bidOne = await auctionInstance.placeBid({
      from: accounts[1],
      value: oneEth.dividedBy(10),
    }); //.1 eth

    truffleAssert.eventEmitted(bidOne, "BidReceived");
    await assert(
      new BigNumber(await auctionInstance.getHighestBid()).isEqualTo(oneEth.dividedBy(10))
    );
  });

  it("Bid 2 on auction", async () => {
    let bidTwo = await auctionInstance.placeBid({
      from: accounts[2],
      value: oneEth.dividedBy(5),
    }); //.2 eth

    truffleAssert.eventEmitted(bidTwo, "BidReceived");
    await assert(
      new BigNumber(await auctionInstance.getHighestBid()).isEqualTo(oneEth.dividedBy(5))
    );
  });

  it("End Auction", async () => {
    let endAuction = await auctionInstance.endAuction({ from: accounts[0] });
    truffleAssert.eventEmitted(endAuction, "AuctionEnded");
    await assert(auctionInstance.endedSuccessfully);
  });

  it("Test ended auction: non-winner withdraw funds", async () => {
    let initial = new BigNumber(await web3.eth.getBalance(accounts[1]));
    let withdrawFund = await auctionInstance.withdraw({ from: accounts[1] });
    let afterWithdrawal = new BigNumber(await web3.eth.getBalance(accounts[1]));

    truffleAssert.eventEmitted(withdrawFund, "WithdrawalDone");
    await assert(afterWithdrawal.isGreaterThan(initial));
  });

  it("Test ended auction: owner withdraw and start rental contract", async () => {
    let initial = new BigNumber(await web3.eth.getBalance(accounts[0]));
    let withdrawFund = await auctionInstance.withdraw({ from: accounts[0] });
    let afterWithdrawal = new BigNumber(await web3.eth.getBalance(accounts[0]));

    truffleAssert.eventEmitted(withdrawFund, "WithdrawalDone");
    await assert(auctionInstance.ownerHasWithdrawn);
    await assert(afterWithdrawal.isGreaterThan(initial));
  });

  it("Test ended auction: winner withdraw excess funds from highest binding bid", async () => {
    let initial = new BigNumber(await web3.eth.getBalance(accounts[2]));
    let withdrawFund = await auctionInstance.withdraw({ from: accounts[2] });
    let afterWithdrawal = new BigNumber(await web3.eth.getBalance(accounts[2]));

    truffleAssert.eventEmitted(withdrawFund, "WithdrawalDone");
    await assert(afterWithdrawal.isGreaterThan(initial));
  });

  // Rental Agreement Tests
  it("Test check Rental Agreement owner and renter address", async () => {
    // Check rental agreement
    await assert((await rentalAgreementInstance.getRenter(1)) == accounts[2]);
    await assert((await rentalAgreementInstance.getOwner(1)) == accounts[0]);
  });

  it("Test complete rental agreement and check points earned", async () => {
    let initialPoints = new BigNumber(await profileInstance.checkPoints(accounts[2]));
    // Check rental agreement
    let result = await rentalAgreementInstance.completeAgreement(1, { from: accounts[2] });
    truffleAssert.eventEmitted(result, "RentCompleted");

    let afterPoints = new BigNumber(await profileInstance.checkPoints(accounts[2]));

    // Check that renter gained 3 points
    await assert(afterPoints.minus(initialPoints).eq(3));
  });
});