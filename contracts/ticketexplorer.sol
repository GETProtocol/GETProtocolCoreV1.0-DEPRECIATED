// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";

// Import interfaces
import "./interfaces/IeventMetadataStorage.sol";
import "./interfaces/IgetEventFinancing.sol";
import "./interfaces/IgetNFT_ERC721.sol";
import "./interfaces/IEconomicsGET.sol";
import "./interfaces/IbaseGETNFT.sol";

import "./interfaces/IGETAccessControl.sol";

// import { baseGETNFT_V6 } from "./baseGETNFT_V6.sol";

contract ticketExplorerGET is Initializable, ContextUpgradeable {
    IGETAccessControl public GET_BOUNCER;
    IMetadataStorage public METADATA;
    IEventFinancing public FINANCE;
    IGET_ERC721 public GET_ERC721;
    IEconomicsGET public ECONOMICS;
    IbaseGETNFT public BASE;

    bytes32 public constant GET_ADMIN = keccak256("GET_ADMIN");

    // IbaseGETNFT.TicketData public ticket_data_struct;  

    function initialize_explorer(
        address address_bouncer, 
        address address_metadata, 
        address address_finance,
        address address_erc721,
        address address_economics,
        address address_base
        ) public initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            METADATA = IMetadataStorage(address_metadata);
            FINANCE = IEventFinancing(address_finance);
            GET_ERC721 = IGET_ERC721(address_erc721);
            ECONOMICS = IEconomicsGET(address_economics);
            BASE = IbaseGETNFT(address_base);
    }


    function isTicketValidAddress(
        address ownerAddress
    ) public view returns(bool) 
    {
        uint256 _nftIndex = GET_ERC721.tokenOfOwnerByIndex(ownerAddress, 0);
        IbaseGETNFT.TicketData memory data = BASE.returnStruct(_nftIndex);
        return data.valid;
    }


    function isTicketScannedAddress(
        address ownerAddress
    ) public view returns(bool) 
    {
        uint256 _nftIndex = GET_ERC721.tokenOfOwnerByIndex(ownerAddress, 0);
        IbaseGETNFT.TicketData memory data = BASE.returnStruct(_nftIndex);
        return data.scanned;
    }

    function isTicketValidIndex(
        uint256 nftIndex
    ) public view returns(bool) 
    {
        IbaseGETNFT.TicketData memory data = BASE.returnStruct(nftIndex);
        return data.valid;
    }


    function isTicketScannedIndex(
         uint256 nftIndex
    ) public view returns(bool) 
    {
        IbaseGETNFT.TicketData memory data = BASE.returnStruct(nftIndex);
        return data.scanned;
    }


    // /**
    // @param currentOwner EOA address of current owner
    // */
    // function isTicketValidAddress(
    //     address currentOwner
    // ) public pure returns (bool)
    // {
    //     return true;
    //     // instert code here
    // }
    
    // /**
    // @param nftIndex TODO
    // */
    // function isTicketValidIndex(
    //     uint256 nftIndex
    // ) external view returns(bool _isValid)
    // {    
    //     TicketDataStruct memory _dataS = BASE.returnTicketData(nftIndex);
    //     // EventStruct storage mdata =
    //     _isValid = _dataS.valid;
    //     // instert code here
    // }
}


