pragma solidity ^0.6.0;

import "./interfaces/IERCAccessControlGET.sol";

contract bouncerLogic {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    AccessContractGET public BOUNCER;

    // Whtielisted EOA account with "ADMIN" role
    modifier onlyAdmin() {
        require(BOUNCER.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ACCESS DENIED - Restricted to admins of GET Protocol.");
        _;
    }

    // Whtielisted EOA account with "RELAYER" role
    modifier onlyRelayer() {
        require(BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "ACCESS DENIED - Restricted to relayers of GET Protocol.");
        _;
    }

    // Whtielisted EOA account with "MINTER" role
    modifier onlyMinter() {
        require(BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "ACCESS DENIED - Restricted to minters of GET Protocol.");
        _;
    }

    /** Whitelisted Contract Address - A factory mints/issues getNFTs (the contract you are looking at). 
    * @dev after the deploy of a factory contract, the factory contract address needs to 
    */
    modifier onlyFactory() {
        require(BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "ACCESS DENIED - Restricted to registered getNFT Factory contracts.");
        _;
    }

}