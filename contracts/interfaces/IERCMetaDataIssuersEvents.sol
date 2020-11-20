pragma solidity ^0.6.0;

interface MetaDataIssuersEvents {
    function newTicketIssuer(address ticketIssuerAddress, string calldata ticketIssuerName, string calldata ticketIssuerUrl) external returns(bool success);
    function getTicketIssuer(address ticketIssuerAddress) external view  returns(address, string memory ticketIssuerName, string memory ticketIssuerUrl);
    function registerEvent(address eventAddress, string calldata eventName, string calldata shopUrl, string calldata latitude, string calldata longitude, uint256 startingTime, address ticketIssuer, string calldata callbackUrl) external returns(bool success);
    function addNftMetaPrimary(address eventAddress, uint256 nftIndex, uint256 pricePaid) external;
    function addNftMetaSecondary(address eventAddress, uint256 nftIndex, uint256 pricePaid) external;
    function getEventDataAll(address eventAddress) external view returns(string memory eventName, string memory shopUrl, uint startTime, string memory ticketIssuerName, address, string memory ticketIssuerUrl);
    function isEvent(address eventAddress) external view returns(bool isIndeed);
    function getEventCount(address ticketIssuerAddress) external view returns(uint eventCount);
    function isTicketIssuer(address ticketIssuerAddress) external view returns(bool isIndeed);
    function getTicketIssuerCount() external view returns (uint ticketIssuerCount);
    function fetchPrimaryOrderNFT(address eventAddress, uint256 nftIndex) external view returns(uint256 _nftIndex, uint256 _pricePaid);
    function fetchSecondaryOrderNFT(address eventAddress, uint256 nftIndex) external view returns(uint256 _nftIndex, uint256 _pricePaid);
    function getNFTByAddress(address originAddress) external view returns(uint256 nftIndex, bool _scanState, address _ticketIssuerA, address _eventAddress, string calldata _metadata);
    function getNFTByIndex(uint256 nftIndex) external view returns(address _originAddress, bool _scanState, address _ticketIssuerA, address _eventAddress, string calldata _metadata);
}