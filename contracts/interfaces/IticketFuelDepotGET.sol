pragma solidity ^0.6.2;

interface IticketFuelDepotGET {

    function calcNeededGET(
         uint256 dollarvalue)
         external view returns(uint256);

    function chargeProtocolTax(
        uint256 nftIndex
    ) external returns(uint256); 

    function fuelBackpack(
        uint256 nftIndex,
        uint256 amountBackpack
    ) external returns(bool);

}