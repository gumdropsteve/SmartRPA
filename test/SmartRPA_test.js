/* eslint-disable @typescript-eslint/no-var-requires */
const { oracle } = require('@chainlink/test-helpers')
const { expectRevert, time } = require('@openzeppelin/test-helpers')
const { assert } = require('chai')


contract('SmartRPA', accounts => {
    const { LinkToken } = require('@chainlink/contracts/truffle/v0.4/LinkToken')
    const { Oracle } = require('@chainlink/contracts/truffle/v0.6/Oracle')
    const SmartRPA = artifacts.require('SmartRPA')
    const seller = accounts[0]
    const oracleNode = accounts[1]
    const buyer = accounts[2]

    beforeEach(async () => {
    

      link = await LinkToken.new({ from: buyer })
      oc = await Oracle.new(link.address, { from: seller })
      smartRPA = await SmartRPA.new(link.address, { from: seller })
      await oc.setFulfillmentPermission(oracleNode, true, {
        from: seller,
      })
    })

    describe('#createRequest', () => {
        context('without LINK', () => {
          it('reverts', async () => {
            await expectRevert.unspecified(
              smartRPA.submitOffer(1, "test", oc.address, {
                from: buyer,
              }),
            )})
        })
        context('with LINK', () => {
          beforeEach(async () => {
            await link.transfer(smartRPA.address, web3.utils.toWei('1', 'ether'), {
              from: buyer,
            })
          })

          context('activate a non active smartRPA', () => {
            it('buyer submits an initial offer to the smartRPA', async () => {             
              // check that initially this is a non active smartRPA
              assert.isFalse(await smartRPA.activeOffer()) 
              
              await smartRPA.submitOffer(1, "test", oc.address, {
                from: buyer,
              })

              // check that the smartRPA is now set to active
              assert.isTrue(await smartRPA.activeOffer())
            })
          })
        })
    })
})