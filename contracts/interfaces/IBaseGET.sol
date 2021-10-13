// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseGET {

    enum TicketStates { UNSCANNED, SCANNED, CLAIMABLE, INVALIDATED }

    struct TicketData {
        address eventAddress;
        bytes32[] ticketMetadata;
        uint256[2] salePrices;
        TicketStates state;
    }

    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 basePrice,
        uint256 orderTime,
        bytes32[] calldata ticketMetadata
    ) external;

    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice
    ) external;

    function collateralMint(
        address basketAddress,
        address eventAddress, 
        uint256 primaryPrice,
        bytes32[] calldata ticketMetadata
    ) external returns(uint256);

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
        address externalAddress
     ) external;

    function setOnChainSwitch(
        bool _switchState
    ) external;
    
    /// VIEW FUNCTIONS

    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) external view returns(bool);

    function returnStruct(
        uint256 nftIndex
    ) external view returns (TicketData memory);

    function addressToIndex(
        address ownerAddress
    ) external view returns (uint256);

    function viewPrimaryPrice(
        uint256 nftIndex
    ) external view returns (uint32);

    function viewLatestResalePrice(
        uint256 nftIndex
    ) external view returns (uint32);

    function viewEventOfIndex(
        uint256 nftIndex
    ) external view returns (address);

    function viewTicketMetadata(
        uint256 nftIndex
    ) external view returns (bytes32[] memory);

    function viewTicketState(
        uint256 nftIndex
    ) external view returns(uint);

}