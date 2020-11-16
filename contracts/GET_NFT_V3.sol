pragma solidity ^0.6.0;

import "./ERC721_TICKETING_V3.sol";

contract GET_NFT_V3 is ERC721_TICKETING_V3 {
    constructor() public ERC721_TICKETING_V3("GET PROTOCOL SMART TICKET FACTORY V3", "getNFT BSC V3") { }
    address public deployerAddress = msg.sender;
    uint public deployerTime = now;
}