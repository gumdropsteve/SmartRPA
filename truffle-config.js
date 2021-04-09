const HDWalletProvider = require('@truffle/hdwallet-provider')
require('dotenv').config()

const key = process.env.PRIVATE_KEY
const url = "https://kovan.infura.io/v3/ed9ce0ecf3864867a69d0be7ed84727a"
module.exports = {
  networks: {
    cldev: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
    },
    ganache: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '*',
    },
    kovan: {
      provider: () => {
        return new HDWalletProvider(key, url)
      },
      network_id: '42',
      skipDryRun: true
    },
    rinkeby: {
      provider: () => {
        return new HDWalletProvider(key, url)
      },
      network_id: '4',
      skipDryRun: true
    },
  },
  compilers: {
    solc: {
      version: '0.6.6',
    },
  },
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  },
  plugins: [
  'truffle-plugin-verify'
  ]
}
