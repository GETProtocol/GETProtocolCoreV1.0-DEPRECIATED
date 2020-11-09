// File: contracts/accesscontrol/Roles.sol

pragma solidity ^0.6.0;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/accesscontrol/Context.sol

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/accesscontrol/MinterRole.sol

pragma solidity ^0.6.0;



/** 
* @title Contract that controls what addresses are able to mint new NFTs
* @notice  Only whitelisted minters can add new minters.
* @notice The first whitelisted minter is the deploying address of the contract.
 */
contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed minterAddress);
    event MinterRemoved(address indexed minterAddress);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address minterAddress) public view returns (bool) {
        return _minters.has(minterAddress);
    }

    function addMinter(address minterAddress) public onlyMinter {
        _addMinter(minterAddress);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address minterAddress) internal {
        _minters.add(minterAddress);
        emit MinterAdded(minterAddress);
    }

    function _removeMinter(address minterAddress) internal {
        _minters.remove(minterAddress);
        emit MinterRemoved(minterAddress);
    }
}

// File: contracts/accesscontrol/RelayerRole.sol

pragma solidity ^0.6.0;



/** 
* @title Contract that controls what addresses are able to move NFTs. 
* @notice A relaying address needs to be trusted as it is responsible for checking the msg.sender of the relayed contract call.
* @notice The first whitelisted minter is the deploying address of the contract.
 */
contract RelayerRole is Context {
    using Roles for Roles.Role;

    event RelayerAdded(address indexed relayerAddress);
    event RelayerRemoved(address indexed relayerAddress);

    Roles.Role private _relayers;

    constructor () internal {
        _addRelayer(_msgSender());
    }

    modifier onlyRelayer() {
        require(isRelayer(_msgSender()), "RelayerRole: caller does not have the Relayer role");
        _;
    }

    function isRelayer(address relayerAddress) public view returns (bool) {
        return _relayers.has(relayerAddress);
    }

    function addRelayer(address relayerAddress) public onlyRelayer {
        _addRelayer(relayerAddress);
    }

    function renounceRelayer() public {
        _removeRelayer(_msgSender());
    }

    function _addRelayer(address relayerAddress) internal {
        _relayers.add(relayerAddress);
        emit RelayerAdded(relayerAddress);
    }

    function _removeRelayer(address relayerAddress) internal {
        _relayers.remove(relayerAddress);
        emit RelayerRemoved(relayerAddress);
    }
}

// File: contracts/accesscontrol/AccessContractGET.sol

pragma solidity ^0.6.0;



contract AccessContractGET is MinterRole, RelayerRole { 
    constructor() public MinterRole() RelayerRole()  { }

}
