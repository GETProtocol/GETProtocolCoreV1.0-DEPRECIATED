// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

interface IwrapGETNFT {
    function depositNFTAndMintTokens(
        address eventAddress,
        uint256 amountNFTs,
        uint256 collaterizationPrice
    ) external;
 }