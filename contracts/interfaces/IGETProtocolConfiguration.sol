// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGETProtocolConfiguration {

    function GETgovernanceAddress() external view returns(address);
    function feeCollectorAddress() external view returns(address);
    function treasuryDAOAddress() external view returns(address);
    function stakingContractAddress() external view returns(address);
    function emergencyAddress() external view returns(address);
    function bufferAddress() external view returns(address);

    function AccessControlGET_proxy_address() external view returns(address);
    function baseGETNFT_proxy_address() external view returns(address);
    function getNFT_ERC721_proxy_address() external view returns(address);
    function eventMetadataStorage_proxy_address() external view returns(address);
    function getEventFinancing_proxy_address() external view returns(address);
    function economicsGET_proxy_address() external view returns(address);
    function fueltoken_get_address() external view returns(address);

    function basicTaxRate() external view returns(uint256);
    function priceGETUSD() external view returns(uint256);

    function setAllContractsStorageProxies(
        address _access_control_proxy,
        address _base_proxy,
        address _erc721_proxy,
        address _metadata_proxy,
        address _financing_proxy,
        address _economics_proxy
    ) external;

} 