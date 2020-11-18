pragma solidity ^0.6.0;

interface ERC721_TICKETING_V3 {
    function newTicketIssuer(address ticketIssuerAddress, string memory ticketIssuerName, string memory ticketIssuerUrl) external returns(bool success);
    function registerEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory latitude, string memory longitude, uint256 startingTime, address ticketIssuer, string memory callbackUrl) external; 
    function getEventDataAll(address eventAddress) external;
    function primaryMint(address destinationAddress, address ticketIssuerAddress, address eventAddress, string memory ticketMetadata) external returns (uint256);
    function secondaryTransfer(address originAddress, address destinationAddress) external;
    function scanNFT(address originAddress) external;
}