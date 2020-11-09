pragma solidity ^0.6.0;

import "./AccessControl.sol";

contract AccessContractGET is AccessControl {

    bytes32 public constant TICKETISSUER_ROLE = keccak256("TICKET_ISSUER_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event AdminRoleSet(bytes32 roleId, bytes32 adminRoleId);

    constructor () public {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(TICKETISSUER_ROLE, msg.sender);
        _setRoleAdmin(RELAYER_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, msg.sender);
    }

    // uint ticketeeronly public = 0;
    // uint relayeronly public = 0;
    // uint adminonly public = 0;

    /// @dev Restricted to members of the role passed as a parameter.
    modifier onlyMember(bytes32 _role) {
        require(hasRole(_role, msg.sender), "Restricted to members.");
        _;
    }  

    /// @dev Create a new role with the specified admin role.
    function addRole(bytes32 roleId, bytes32 adminRoleId)
        public onlyMember(adminRoleId) {
        _setRoleAdmin(roleId, adminRoleId);
        emit AdminRoleSet(roleId, adminRoleId);
    }
}