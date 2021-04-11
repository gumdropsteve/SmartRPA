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
  const buyer = accounts[0]

  beforeEach(async () => {
    link = await LinkToken.new({ from: buyer })
    oc = await Oracle.new(link.address, { from: buyer })
    smartRPA = await SmartRPA.new(link.address, { from: buyer })
    await oc.setFulfillmentPermission(oracleNode, true, {
      from: buyer,
    })
  })

  describe('#createRequest', () => {
    context('without LINK', () => {
      it('reverts', async () => {
        await expectRevert.unspecified(
          smartRPA.submitOffer(1, "test", {
            from: buyer,
          }),
        )
      })
    })
    context('with LINK', () => {
      beforeEach(async () => {
        await link.transfer(smartRPA.address, web3.utils.toWei('1', 'ether'), {
          from: buyer,
        })
      })
      context('while no offer submitted', () => {
        it('offer count is zero ', async () => {
          var offerCountInitial = await smartRPA.getNumberOfOffers()
          assert.equal(0, offerCountInitial);
        })
      })
      context('when an offer is submitted', () => {
        beforeEach(async () => {
          await smartRPA.submitOffer(1, "test", {
            from: buyer,
          })
        })
        it('check that an offer has been submitted', async () => {
          var offerCountFinal = await smartRPA.getNumberOfOffers()
          assert.equal(1, offerCountFinal)
        })

        it('is able to retrieve a users offer details', async () => {
          var myOffer = await smartRPA.offers(0);
          assert.isNotNull(myOffer);
        })
        it('is initially an offer that hasnt been responded to by the seller yet', async () => {
          var offer = await smartRPA.offers(0);
          assert.isFalse(offer.offerRespondedTo);
        })
        it('is initially an active offer', async () => {
          var isActive = await smartRPA.isActive(0);
          assert.isTrue(isActive);
        })
        it('gets token URI', async () => {
          var tokenURI = await smartRPA.getTokenURI(0);
          assert.isNotNull(tokenURI);
        })
        it('sets token URI', async () => {
          await smartRPA.setTokenURI(0, 'test', {
            from: buyer,
          });

          var tokenURI = await smartRPA.getTokenURI(0);
          assert.equal('test', tokenURI);
        })
        context('seller rejects offer', () => { 
          beforeEach(async () => {
            await smartRPA.respondToOffer(0, 2), {
              from: seller
            }
          })
          it('is a rejected offer and is set to inactive', async () => {
            var isActive = await smartRPA.isActive(0);;
            var rejectedOffer = await smartRPA.offers(0);
            assert.isFalse(isActive);       
            assert.isTrue(rejectedOffer.offerRespondedTo);
          })
        })
        context('seller accepts offer', () => { 
          beforeEach(async () => {
            await smartRPA.respondToOffer(0, 1), {
              from: seller
            }
          })
          it('is an active offer that has been responded to', async () => {
            var isActive = await smartRPA.isActive(0); 
            var acceptedOffer = await smartRPA.offers(0); 
            assert.isTrue(isActive);  
            assert.isTrue(acceptedOffer.offerRespondedTo);
          })
        })
      })
    })
  })
})