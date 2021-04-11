# SmartRPA
Neighbor to neighbor real estate transactions.

## Description
Selling a home can be a lot of fun. Selling a home can be a lot of not fun as well. Often, the difference is the ability of the most interested parties (Buyer and Seller) to know what is going on, and where they stand.

As a [ERC-721](https://docs.openzeppelin.com/contracts/2.x/api/token/erc721) Non-Fungible Token contract, SmartRPA enables secure transparency for both the Homeowner (Seller) and Potential Buyers by integrating Chainlink time enforcement ([Alarm Clock](https://docs.chain.link/docs/chainlink-alarm-clock)) with the trust of blockchain and existing document management systems (e.g. DocuSign).

It's really quite simple.
1. A Seller posts their listing on-chain by deploying a SmartRPA.
2. Potential Buyers submit the URL of their offer, and the number of days the Seller has to respond.
3. Each Potential Buyers' submission returns them a unique SRPA token that's linked to their offer. They can use this to check its status.
4. Once an offer is submitted, a Chainlink Alarm Clock is started with a clause check to see if it was accepted or countered within the offer's time limit.
   - If it was not, that offer's SRPA token is [burned](https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#ERC721-_burn-uint256-) (transfering ownership from the Potential Buyer to no one) as the offer is no longer active. 
   - If it was, a similar timer is started for the Counter Offer or for Close of Escrow and the token's offer URL becomes the SmartRPA's offer URL.

At any point, the Seller can see how many offers they have, when each expires, and securely access them through familiar standards. Listing on-chain also facilitates the use of cryptocurrencies or other digital assets as payment.

### Demo
#### Live Demo
Link to live demo here
#### Video
<p align="center">
   <a target="_blank" href="https://youtu.be/yFnXwSGstus">
    <img src="https://www.brandinginasia.com/wp-content/uploads/2017/05/YouTube-Play-Button-Before-and-After-Branding-in-Asia.png"/>
   </a>
</p>
Embedded youtube video here

### Architecture diagram
![Architecture diagram](https://lh4.googleusercontent.com/rmxWmaNei35p6Hm1zL5coNXkAVqQ3wVcd_7v4QpDv64G9YqRNo7x_RFmfDC6ilDalXj3KTjHq-kx73jynGYcY66WBo5VWmETTipeaLQnICCwqgc3DnIzbwQrDDSt6dd3-EeSkiMz)

## Getting Started
```
git clone https://github.com/gumdropsteve/nevada-smart-rpa

cd nevada-smart-rpa

npm install

truffle compile

truffle migrate --reset --network rinkeby -f 2

truffle run verify SmartRPA --network rinkeby --license MIT
```

### Using the Testnets
#### What is a testnet?
TLDR: building on blockchain for free.
> Since Ethereum is a protocol, this means there can be multiple independent "[networks](https://ethereum.org/en/developers/docs/networks)" conforming to this protocol that do not interact with each other.
> 
> Mainnet is the primary public Ethereum production blockchain, where actual-value transactions occur on the distributed ledger.
> When people and exchanges discuss ETH prices, they're talking about mainnet ETH.
> 
>  In addition to mainnet, there are public [testnets](https://ethereum.org/en/developers/docs/networks/#testnets). These are networks used by protocol developers or smart contract developers to test both protocol upgrades as well as potential smart contracts in a production-like environment before deployment to mainnet. Think of this as an analog to production versus staging servers. - [Etherium docs](https://ethereum.org/en/developers/docs/networks/)

To deploy and then interact with the contract, you'll need testnet LINK and testnet ETH tokens. We used the [Rinkeby](https://www.rinkeby.io/) testnet, which means those tokens will need to come from Rinkeby faucets.

> LINK tokens are used to pay node operators for retrieving data for smart contracts and also for deposits placed by node operators as required by contract creators. - [Chainlink docs](https://docs.chain.link/docs/link-token-contracts)

All of this info is related to your wallet. Here's a 4 minute video for setting up your wallet if you don't already have one: https://youtu.be/P7FX_1PePX0

#### Ethereum (Rinkeby)
- LINK faucet: https://rinkeby.chain.link
   - Address: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
- ETH faucet: https://faucet.rinkeby.io

### Unit tests
To run the unit testing script

```
truffle test ./test/SmartRPA_test.js
```

The unit testing script will take you through each stage of the SRPA lifecycle. From initial offer creation from the buyer, to offer acceptance by the seller.

### Front end
Front end repo: https://github.com/eserilev/smart-rpa-frontend

## Long term vision
#### DAO and Revenue Generation
   - With enough utilization, small fees can be applied to Buyers or Sellers during the SRPA process. 
   - These fees can be distributed to users holding LAND tokens.
      - LAND is an ERC20 token capped at 100,000,000 LAND and minted via a set emission schedule.
      - LAND is a governance token with time-weighted voting and value accrual mechanisms.
      - LAND value is accrued through the fees collected by the SRPA process. Holders of the token can also vote lock their LAND and begin voting on various DAO proporsals.

#### Liquidity 
   - Users can provide liquidity to SmartRPA liquidty pools and accrue APY gains. APY rewards will be paid out via newly minted LAND tokens. 
   - With enough liquidity, SmartRPA may be able to begin offering collateralized loans and other financial services.

