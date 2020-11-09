pragma solidity ^0.6.0;

import "./Roles.sol";
import "./Context.sol";

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