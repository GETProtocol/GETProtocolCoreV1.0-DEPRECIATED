pragma solidity ^0.6.0;

import "./AccessControl.sol";

contract AccessContractGET is AccessControl {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor () public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x6774CB231c63efAd9115d8a60DdD7Daed418d4B5);
        _setupRole(RELAYER_ROLE, 0x6774CB231c63efAd9115d8a60DdD7Daed418d4B5);
        _setupRole(RELAYER_ROLE, 0x0D5BF3570ddf4c5b72aFc014F4b728B67e44Ea7f);
        _setupRole(MINTER_ROLE, 0x6774CB231c63efAd9115d8a60DdD7Daed418d4B5);
        _setupRole(MINTER_ROLE, 0x0D5BF3570ddf4c5b72aFc014F4b728B67e44Ea7f);
        grantRole(RELAYER_ROLE, 0x6774CB231c63efAd9115d8a60DdD7Daed418d4B5);
        grantRole(MINTER_ROLE, 0x6774CB231c63efAd9115d8a60DdD7Daed418d4B5);
    }
}