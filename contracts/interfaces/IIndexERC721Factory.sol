// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIndexERC721Factory {

    function baskets() external returns(address);

    function createBasket() external returns(address);

}