const _deploy_contracts = require('../migrations/1_deploy_contracts')
const truffleAssert = require('truffle-assertions') // npm truffle-assertions
const BigNumber = require('bignumber.js') // npm install bignumber.js
var assert = require('assert')
const { profile } = require('console')

var Profile = artifacts.require('../contracts/Profile.sol')

var Event = artifacts.require('../contracts/Event.sol')

var Marketplace = artifacts.require('../contracts/Marketplace.sol')

const oneEth = new BigNumber(1000000000000000000) // 1 eth

contract('Event', function (accounts) {
  before(async () => {
    profileInstance = await Profile.deployed()
    eventInstance = await Event.deployed()
    marketplaceInstance = await Marketplace.deployed()
  })

  console.log('Testing Marketplace contract')

  it('Create Profile', async () => {
    let p1 = await profileInstance.createMember({ from: accounts[1] })
    let p2 = await profileInstance.createMember({ from: accounts[2] })

    let checkMembership1 = await profileInstance.checkMembership(accounts[1], {
      from: accounts[1],
    })
    assert.notStrictEqual(p1, undefined, 'Failed to make profile')
    assert.strictEqual(checkMembership1, true, 'Failed to make profile')
  })

  it('Mint tickets', async () => {
    let m1 = await eventInstance.mint(1, { from: accounts[1], value: oneEth })
    truffleAssert.eventEmitted(m1, 'TicketMinted')
  })

  it('Unable to mint as insufficient supply', async () => {
    truffleAssert.reverts(
      eventInstance.mint(1, { from: accounts[2], value: oneEth }),
    )
  })

  it('Create a ticket listing', async () => {
    let a1 = await eventInstance.approve(marketplaceInstance.address, 1, {
      from: accounts[1],
    })
    let l3 = await marketplaceInstance.listItem(
      eventInstance.address,
      1,
      BigNumber(1200000000000000000),
      {
        from: accounts[1],
      },
    )
    truffleAssert.eventEmitted(l3, 'ListItem')
  })

  it('Remove the ticket listing', async () => {
    let ul1 = await marketplaceInstance.unlistItem(
      eventInstance.address,
      1,
      {
        from: accounts[1],
      },
    )
    truffleAssert.eventEmitted(ul1, 'UnlistItem');
    await assert.notStrictEqual(marketplaceInstance.getListingPrice(eventInstance.address, 1), 0, "Unable to unlist a Ticket");

  })

  it('Update the ticket listing', async () => {
    let a1 = await eventInstance.approve(marketplaceInstance.address, 1, {
      from: accounts[1],
    })
    let l3 = await marketplaceInstance.listItem(
      eventInstance.address,
      1,
      BigNumber(1200000000000000000),
      {
        from: accounts[1],
      },
    )
    let u1 = await marketplaceInstance.updateListing(
      eventInstance.address,
      1,
      BigNumber(1600000000000000000),
      { from: accounts[1] },
    )
    truffleAssert.eventEmitted(u1, 'UpdateItem')
  })

  it('User b can buy the Ticket', async () => {
    let b1 = await marketplaceInstance.buy(eventInstance.address, 1, {
      from: accounts[2],
      value: new BigNumber(1800000000000000000),
    })
    let newOwner = await eventInstance.ownerOf(1)
    assert.strictEqual(
      newOwner,
      accounts[2],
      'Ticket was not transferred to the buyer',
    )
  })
})
