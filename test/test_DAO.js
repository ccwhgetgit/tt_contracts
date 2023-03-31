const _deploy_contracts = require('../migrations/2_deploy_contracts')
const truffleAssert = require('truffle-assertions') // npm truffle-assertions
const BigNumber = require('bignumber.js') // npm install bignumber.js
var assert = require('assert')
const { profile } = require('console')

var Profile = artifacts.require('../contracts/Profile.sol')
var DAO = artifacts.require('../contracts/DAO.sol')

const oneEth = new BigNumber(1000000000000000000) // 1 eth

contract('DAO', function (accounts) {
  before(async () => {
    profileInstance = await Profile.deployed()
    daoInstance = await DAO.deployed()
  })

  console.log('Testing DAO contract')

  it('Create Profile', async () => {
    let p1 = await profileInstance.createMember({ from: accounts[1] })
    let p2 = await profileInstance.createMember({ from: accounts[2] })

    let checkMembership1 = await profileInstance.checkMembership(accounts[1], {
      from: accounts[1],
    })
    assert.notStrictEqual(p1, undefined, 'Failed to make profile')
    assert.strictEqual(checkMembership1, true, 'Failed to make profile')
  })

  it('Create Proposal', async () => {
    let proposal1 = await daoInstance.createProposal('This is my proposal', {
      from: accounts[1],
    })
    truffleAssert.eventEmitted(proposal1, 'ProposalAdded')
  })

  it('Ensure Voter is a member', async () => {
    await truffleAssert.reverts(
      daoInstance.vote(0, true, { from: accounts[3] }),
      'Not authorized to vote for a proposal. Sign up on Profile',
    )
  })

  it('Ensure Proposal Number is valid', async () => {
    await truffleAssert.reverts(
      daoInstance.vote(10, true, { from: accounts[1] }),
      'Invalid proposal',
    )
  })

  it('Ensure Proposal reaches minimum Quorum', async () => {
    let vote1 = await daoInstance.vote(0, true, { from: accounts[1] })
    truffleAssert.eventEmitted(vote1, 'Voted')
    await truffleAssert.reverts(
      daoInstance.endProposal(0, { from: accounts[0] }),
      'Quorum not reached',
    )
  })

  it('Vote pass for Proposal 1', async () => {
    let initialPoints = new BigNumber(
      await profileInstance.checkPoints(accounts[2]),
    )
    let vote2 = await daoInstance.vote(0, true, { from: accounts[2] })
    truffleAssert.eventEmitted(vote2, 'Voted')

    let afterPoints = new BigNumber(
      await profileInstance.checkPoints(accounts[2]),
    )
    await assert(afterPoints.minus(initialPoints).eq(2))
  })

  it('Ensure Proposal can only closed by Owner', async () => {
    await truffleAssert.reverts(
      daoInstance.endProposal(0, { from: accounts[1] }),
      'Not authorized',
    )
  })
})
