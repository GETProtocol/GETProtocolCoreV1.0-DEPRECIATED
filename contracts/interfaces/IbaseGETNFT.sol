pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

interface IbaseGETNFT {

    struct TicketData {
        address event_address;
        bytes32[] ticket_metadata;
        uint256[] prices_sold;
        bool set_aside;
        bool scanned;
        bool valid;
    }

    function returnStruct(
        uint256 nftIndex
    ) external view returns (TicketData memory);

    // function returnTicketData(
    //     uint256 nftIndex
    // ) external view returns(
    //     TicketData memory _data);

    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 orderTime,
        string calldata ticketURI, 
        bytes32[] calldata ticketMetadata
    ) external returns (uint256 nftIndex);

    function relayColleterizedMint(
        address destinationAddress, 
        address eventAddress, 
        uint256 pricepaid,
        uint256 orderTime,
        string calldata ticketURI,
        bytes32[] calldata ticketMetadata,
        bool setAsideNFT
    ) external returns(uint256);

    function editTokenURIbyAddress(
        address originAddress,
        string calldata _newTokenURI
        ) external;

    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) external;

    function scanNFT(
        address originAddress,
        uint256 orderTime
        ) external returns(bool);

    function invalidateAddressNFT(
        address originAddress,
        uint256 orderTime
        ) external;

    function claimgetNFT(
        address originAddress, 
        address externalAddress) external;

    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) external view returns(bool);

    function ticketMetadata(address originAddress)
      external  
      view 
      returns (
          address _eventAddress,
          bool _scanned,
          bool _valid,
          bytes32[] memory _ticketMetadata,
          bool _setAsideNFT,
          uint256[] memory _prices_sold
      );
}