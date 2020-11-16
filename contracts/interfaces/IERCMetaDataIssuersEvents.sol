pragma solidity ^0.6.0;

interface MetaDataIssuersEvents {
    function newTicketIssuer(address ticketIssuerAddress, string calldata ticketIssuerName, string calldata ticketIssuerUrl) external returns(bool success);
    function getTicketIssuer(address ticketIssuerAddress) external view  returns(address, string memory ticketIssuerName, string memory ticketIssuerUrl);
    function registerEvent(address eventAddress, string calldata eventName, string calldata shopUrl, string calldata coordinates, uint256 startingTime, address tickeerAddress) external returns(bool success);
    function getEventDataQuick(address eventAddress) external view returns(address, string memory eventName, address ticketIssuerAddress, string memory ticketIssuerName);
    function addNftMeta(address eventAddress, uint256 nftIndex, uint256 pricePaid) external;
    function getEventDataAll(address eventAddress) external view returns(string memory eventName, string memory shopUrl, string memory locationCord, uint startTime, string memory ticketIssuerName, address, string memory ticketIssuerUrl);
    function isEvent(address eventAddress) external view returns(bool isIndeed);
    function getEventCount(address ticketIssuerAddress) external view returns(uint eventCount);
    function isTicketIssuer(address ticketIssuerAddress) external view returns(bool isIndeed);
    function getTicketIssuerCount() external view returns (uint ticketIssuerCount);

}