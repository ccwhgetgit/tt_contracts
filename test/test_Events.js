const _deploy_contracts = require("../migrations/1_deploy_contracts");
const truffleAssert = require("truffle-assertions"); // npm truffle-assertions
const BigNumber = require("bignumber.js"); // npm install bignumber.js
var assert = require("assert");
const { profile } = require("console");

var Profile = artifacts.require("../contracts/Profile.sol");
var Event = artifacts.require("../contracts/Event.sol");

const oneEth = new BigNumber(1000000000000000000); // 1 eth

contract("Event", function (accounts) {
    before(async () => {
        profileInstance = await Profile.deployed();
        eventInstance = await Event.deployed();
    });

    console.log("Testing Event contract");

    it("Create Profile", async () => {

        let p1 = await profileInstance.createMember({from:accounts[1]});
        let p2 = await profileInstance.createMember({from:accounts[2]});
        
        let checkMembership1 = await profileInstance.checkMembership(accounts[1], {from: accounts[1]});
        assert.notStrictEqual(p1, undefined, "Failed to make profile");
        assert.strictEqual(checkMembership1, true, "Failed to make profile");

    })

    it('Mint Ticket', async() => { 

        let mint1 = await eventInstance.mint(0, {from:accounts[1]}); 
    })

 


}
)