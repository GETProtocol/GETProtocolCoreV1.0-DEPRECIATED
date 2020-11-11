pragma solidity ^0.6.0;

import "./AccessControl.sol";

contract BouncerGET is AccessControl {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    constructor () public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, 0x6774CB231c63efAd9115d8a60DdD7Daed418d4B5);
        
        _setupRole(RELAYER_ROLE, msg.sender);
        _setupRole(FACTORY_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        
        grantRole(RELAYER_ROLE, 0x6774CB231c63efAd9115d8a60DdD7Daed418d4B5);
        grantRole(FACTORY_ROLE, 0x6774CB231c63efAd9115d8a60DdD7Daed418d4B5);
        grantRole(MINTER_ROLE, 0x6774CB231c63efAd9115d8a60DdD7Daed418d4B5);
    }
}