pragma solidity ^0.6.2;

interface IEventFinancing {
    function mintSetAsideNFTTicket(
        address underwriterAddress, 
        address eventAddress,
        uint256 orderTime,
        uint256 ticketDebt,
        string calldata ticketURI,
        bytes32[] calldata ticketMetadata
    ) external;

    function collateralizedNFTSold(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 orderTime,
        uint256 primaryPrice
    ) external;

    event txMintUnderwriter(
        address underwriterAddress,
        address eventAddress,
        uint256 ticketDebt,
        string ticketURI,
        uint256 orderTime,
        uint _timestamp
    );

    event fromCollaterizedInventory(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 primaryPrice,
        uint256 orderTime,
        uint _timestamp
    );

    event BaseConfigured(
        address baseAddress,
        address requester
    );

} 