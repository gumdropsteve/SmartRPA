// contracts/SmartRPA.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract SmartRPA is ERC721 {
    address payable private owner;
    string rpa;
    constructor() ERC721("SmartRPA", "SRPA") public {
        owner = msg.sender;
        }
    // store url to RPA PDF (most basic implementation)
    function store(string memory url) public {
        require(msg.sender == owner);
        rpa = url;
        }
    // display url to RPA PDF (most basic implementation)
    function retrieve() public view returns (string memory){
        return rpa;
        }
    // delete contract
    function close() public { 
        require(msg.sender == owner);
        selfdestruct(owner); 
        }
}
