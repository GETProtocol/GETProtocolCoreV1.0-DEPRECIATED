// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGET_ERC721 {
    
    function mintERC721(
        address destinationAddress,
        string calldata ticketURI
    ) external returns(uint256);
    
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns(uint256);
    
    function balanceOf(
        address owner
    ) external view returns(uint256);
    
    function relayerTransferFrom(
        address originAddress, 
        address destinationAddress, 
        uint256 nftIndex
    ) external;
    
    function editTokenURI(
        uint256 nftIndex,
        string calldata _newTokenURI
    ) external;
    
    function isNftIndex(
        uint256 nftIndex
    ) external view returns(bool);

    function ownerOf(
        uint256 tokenId
    ) external view returns (address);

    function setApprovalForAll(
        address operator, 
        bool _approved) external;

}