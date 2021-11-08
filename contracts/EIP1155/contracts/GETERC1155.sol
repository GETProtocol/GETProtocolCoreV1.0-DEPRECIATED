// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./interfaces/IGETAccessControl.sol";

contract GETERC1155 is Initializable, ERC1155Upgradeable {
    IGETAccessControl public GET_BOUNCER;
    bytes32 private constant FACTORY_ROLE =
        0xdfbefbf47cfe66b701d8cfdbce1de81c821590819cb07e71cb01b6602fb0ee27;
    bytes32 private constant GET_ADMIN = keccak256("GET_ADMIN");

    function __GETERC1155_init_unchainded(address address_bouncer) internal initializer {
        GET_BOUNCER = IGETAccessControl(address_bouncer);
    }

    function __GETERC1155_init(
        string memory uri,
        uint256 individualTokenIdAmount,
        address bouncer
    ) external initializer {
        __ERC1155_init(uri, individualTokenIdAmount);
        __GETERC1155_init_unchainded(bouncer);
    }

    mapping(uint256 => address) ticketToEvent;
    mapping(address => address) eventToRelayer;

    event EventCreated(
        address indexed eventAddress,
        address indexed relayerAddress,
        uint256 indexed timeCreated
    );

    /**
     * @dev this function should be called from the EventMetadata contract when an event is created
     */

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "CALLER_NOT_FACTORY");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(GET_BOUNCER.hasRole(GET_ADMIN, msg.sender), "CALLER_NOT_ADMIN");
        _;
    }

    function createEvent(address eventAddress) external {
        eventToRelayer[eventAddress] = _msgSender();
        emit EventCreated(eventAddress, _msgSender(), block.timestamp);
    }

    /**
     * @notice all tickets are minted into their respective eventAddresses
     * @param _eventAddress - address the token would be minted to.
     * @param id - token id.
     * @param data - any arbitrary data.
     * @notice the tokens minted by this contract are all non-fungible hence there would only exist one token per type (per id)
     */

    function mint(
        address _eventAddress,
        uint256 id,
        bytes memory data
    ) external onlyFactory {
        // ticketToEvent[id] = _eventAddress;
        super._mint(_eventAddress, id, 1, data);
    }

    function mintBatch(
        address _eventAddress,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyFactory {
        // for (uint256 i = 0; i < ids.length; i++) {
        //     ticketToEvent[ids[i]] = _eventAddress;
        // }
        super._mintBatch(_eventAddress, ids, amounts, data);
    }

    function relayerTransferFrom(
        uint256 id,
        address eventAddress,
        address destinationAddress,
        bytes memory data
    ) external onlyFactory {
        super._safeTransferFrom(eventAddress, destinationAddress, id, 1, data);
    }

    function mintBatch2(
        address _eventAddress,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyFactory {
        // for (uint256 i = 0; i < ids.length; i++) {
        //     ticketToEvent[ids[i]] = _eventAddress;
        // }
        super._mintBatch2(_eventAddress, ids, amounts, data);
    }

    function getMintBatch(
        address _eventAddress,
        uint256 start,
        uint256 end
    ) external onlyFactory {
        // for (uint256 i = 0; i < ids.length; i++) {
        //     ticketToEvent[ids[i]] = _eventAddress;
        // }
        super._getMintBatch(_eventAddress, start, end);
    }
}
