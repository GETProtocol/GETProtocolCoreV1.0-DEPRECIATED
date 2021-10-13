// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721TokenVault {

    // Vault variables
    function token() external view returns(address);
    function id() external view returns(uint256);
    function auctionEnd() external view returns(uint256);
    function auctionLength() external view returns(address);
    function reserveTotal() external view returns(address);
    function livePrice() external view returns(address);
    function winning() external view returns(address);

    // VIEW & CONFIGURATION FUNCTIONS
    function reservePrice() external view returns(uint256);
    function claimFees() external;
    function updateUserPrice(uint256 _new) external;
    function start() external;
    function end() external;
    function bid() external;
    function redeem() external;
    function cash() external;

}