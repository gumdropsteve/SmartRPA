const SmartRPA = artifacts.require('SmartRPA')

module.exports = async (deployer, network, [defaultAccount]) => {
    // deploy contract
    deployer.deploy(SmartRPA)
}
