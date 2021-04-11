# nevada-rpa-smart-contract
Nevada Residential Purchase Agreement (RPA) smart contract template.

## Getting Started
```
git clone https://github.com/gumdropsteve/nevada-smart-rpa

cd nevada-smart-rpa

npm install

truffle compile

truffle migrate --reset --network kovan -f 2

truffle run verify SmartRPA --network kovan --license MIT
```


### Unit tests

To run the unit testing script

```
truffle test ./test/SmartRPA_test.js
```

The unit testing script will take you through each stage of the SRPA lifecycle. From initial offer creation from the buyer, to offer acceptance by the seller.
