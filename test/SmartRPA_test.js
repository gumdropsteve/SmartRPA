/* eslint-disable @typescript-eslint/no-var-requires */
const { oracle } = require('@chainlink/test-helpers')
const { expectRevert, time } = require('@openzeppelin/test-helpers')


contract('SmartRPA', accounts => {
    const { LinkToken } = require('@chainlink/contracts/truffle/v0.4/LinkToken')
    const { Oracle } = require('@chainlink/contracts/truffle/v0.6/Oracle')
    const SmartRPA = artifacts.require('SmartRPA')

    beforeEach(async () => {
        link = await LinkToken.new({ from: defaultAccount })
        oc = await Oracle.new(link.address, { from: defaultAccount })
        cc = await SmartRPA.new(link.address, { from: consumer })
        await oc.setFulfillmentPermission(oracleNode, true, {
          from: defaultAccount,
        });
    });

    describe('#createRequest', () => {
        context('without LINK', () => {
          it('reverts', async () => {
            await expectRevert.unspecified(
              cc.createRequestTo(oc.address, jobId, payment, url, path, times, {
                from: consumer,
              }),
            )});
        });
    })
})