// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEconomicsGET {

    struct DynamicRateStruct {
        bool configured; // 0
        uint16 mint_rate; // 1
        uint16 resell_rate; // 2
        uint16 claim_rate; // 3
        uint16 crowd_rate; // 4
        uint16 scalper_fee; // 5
        uint16 extra_rate; // 6
        uint16 share_rate; // 7
        uint16 edit_rate; // 8
        uint16 max_base_price; // 9
        uint16 min_base_price; // 10
        uint16 reserve_slot_1; // 11
        uint16 reserve_slot_2; // 12
    }

    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
    ) external returns (uint256);  

    function emptyBackpackBasic(
        uint256 nftIndex
    ) external returns (uint256);

    function chargeTaxRateBasic(
        uint256 nftIndex
    ) external;

    function swipeDepotBalance() external returns(uint256);

    function topUpBuffer(
            uint256 topUpAmount,
            uint256 priceGETTopUp,
            address relayerAddress,
            address bufferAddress
    ) external returns(uint256);

    function setRelayerBuffer(
        address _relayerAddress,
        address _bufferAddressRelayer
    ) external;

    /// VIEW FUNCTIONS

    function checkRelayerConfiguration(
        address _relayerAddress
    ) external view returns (bool);

    function balanceRelayerSilo(
        address relayerAddress
    ) external view returns (uint256);

    function valueRelayerSilo(
        address _relayerAddress
    ) external view returns(uint256);

    function estimateNFTMints(
        address _relayerAddress
    ) external view returns(uint256);

    function viewRelayerFactor(
        address _relayerAddress
    ) external view returns(uint256);

    function viewRelayerGETPrice(
        address _relayerAddress 
    ) external view returns (uint256);

    function viewBackPackValue(
        uint256 _nftIndex,
        address _relayerAddress
    ) external view returns (uint256);

    function viewBackPackBalance(
        uint256 _nftIndex
    ) external view returns (uint256);

    function viewDepotBalance() external view returns(uint256);
    function viewDepotValue() external view returns(uint256);
}