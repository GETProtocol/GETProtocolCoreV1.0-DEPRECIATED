pragma solidity ^0.6.2;

interface IbaseGETNFT_V4 {
    function mintGETNFT(
        address destinationAddress, 
        address eventAddress, 
        uint256 pricepaid,
        uint256 orderTime,
        string calldata ticketURI,
        bytes32[] calldata ticketMetadata,
        bool setAsideNFT
    ) external returns(uint256);
}