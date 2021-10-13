// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIndexERC721 {

    function depositERC721(address _token, uint256 _tokenId) external;
    function withdrawERC721(address _token, uint256 _tokenId) external;
    function withdrawETH() external;
    function withdrawERC20(address _token) external;

}