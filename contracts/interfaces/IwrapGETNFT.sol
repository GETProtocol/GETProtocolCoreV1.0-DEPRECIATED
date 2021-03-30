pragma solidity ^0.6.2;

interface IwrapGETNFT {
    function depositNFTAndMintTokens(
        address eventAddress,
        uint256 amountNFTs,
        uint256 collaterizationPrice
    ) external;
 }