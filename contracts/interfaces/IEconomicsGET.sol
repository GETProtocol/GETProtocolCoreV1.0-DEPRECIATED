// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

interface IEconomicsGET {
    function editCoreAddresses(
        address newBouncerAddress,
        address newFuelAddress,
        address newDepotAddress
    ) external;

    function balanceOfRelayer(
        address relayerAddress
    ) external;

    function setPriceGETUSD(
        uint256 newGETPrice)
        external;
    
    function topUpGet(
        address relayerAddress,
        uint256 amountTopped
    ) external;

    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
        ) external returns(uint256);

    function calcBackpackValue(
        uint256 baseTicketPrice,
        uint256 percetageCut
    ) external view returns(uint256);

    function calcBackpackGET(
        uint256 baseTicketPrice,
        uint256 percetageCut
    ) external view returns(uint256);

    event BackpackFilled(
        uint256 indexed nftIndex,
        uint256 indexed amountPacked
    );

    event BackPackFueled(
        uint256 nftIndexFueled,
        uint256 amountToBackpack
    );

}