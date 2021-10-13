//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";

import "./utils/SafeMathUpgradeable.sol";

import "./interfaces/IGETAccessControl.sol";
import "./interfaces/IBaseGET.sol";
import "./interfaces/IEventMetadataStorage.sol";
import "./interfaces/IEventFinancing.sol";
import "./interfaces/INFT_ERC721V3.sol";
import "./interfaces/IEconomicsGET.sol";
import "./interfaces/IERC20.sol";

import "./interfaces/IfoundationContract.sol";

import "./interfaces/IGETProtocolConfiguration.sol";

contract FoundationContract is Initializable, ContextUpgradeable {
    
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint128;
    using SafeMathUpgradeable for uint64;
    using SafeMathUpgradeable for uint32;

    bytes32 private GET_GOVERNANCE;
    bytes32 private GET_ADMIN; 
    bytes32 private RELAYER_ROLE;
    bytes32 private FACTORY_ROLE;

    IGETProtocolConfiguration public CONFIGURATION;

    IGETAccessControl internal GET_BOUNCER;
    IBaseGET internal BASE;
    IGET_ERC721V3 internal GET_ERC721;
    IEventMetadataStorage internal METADATA;
    IEventFinancing internal FINANCE; // reserved slot
    IEconomicsGET internal ECONOMICS;
    IERC20 internal FUELTOKEN;

    event ContractSyncCompleted();

    function __FoundationContract_init_unchained(
        address _configurationAddress
    ) internal initializer {
        CONFIGURATION = IGETProtocolConfiguration(_configurationAddress);
        GET_GOVERNANCE = 0x8f56080c0d86264195811790c4a1d310776ff2c3a02bf8a3c20af9f01a045218;
        GET_ADMIN = 0xc78a2ac81d1427bc228e4daa9ddf3163091b3dfd17f74bdd75ef0b9166a23a7e;
        RELAYER_ROLE = 0xe2b7fb3b832174769106daebcfd6d1970523240dda11281102db9363b83b0dc4;
        FACTORY_ROLE = 0xdfbefbf47cfe66b701d8cfdbce1de81c821590819cb07e71cb01b6602fb0ee27;
    }

    function __FoundationContract_init(
        address _configurationAddress
    ) public initializer {
        __Context_init();
        __FoundationContract_init_unchained(
            _configurationAddress
        );
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(GET_BOUNCER.hasRole(GET_ADMIN, msg.sender),
        "NOT_ADMIN");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender),
        "NOT_RELAYER");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyGovernance() {
        require(
            GET_BOUNCER.hasRole(GET_GOVERNANCE, msg.sender),
            "NOT_GOVERNANCE"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender),
        "NOT_FACTORY");
        _;
    }

    /**
    @dev calling this function will sync the global contract variables and instantiations with the DAO controlled configuration contract
    @notice can only be called by configurationGET contract
    TODO we could make this virtual, and then override the function in the contracts that inherit the foundation to instantiate the contracts that are relevant that particular contract
     */
    function syncConfiguration() external returns(bool) {

        // check if caller is configurationGETProxyAddress 
        require(msg.sender == address(CONFIGURATION), "CALLER_NOT_CONFIG");

        GET_BOUNCER = IGETAccessControl(
            CONFIGURATION.AccessControlGET_proxy_address()
        );

        BASE = IBaseGET(
            CONFIGURATION.baseGETNFT_proxy_address()
        );

        GET_ERC721 = IGET_ERC721V3(
            CONFIGURATION.getNFT_ERC721_proxy_address()
        );

        METADATA = IEventMetadataStorage(
            CONFIGURATION.eventMetadataStorage_proxy_address()
        );    

        FINANCE = IEventFinancing(
            CONFIGURATION.getEventFinancing_proxy_address()
        );            

        ECONOMICS = IEconomicsGET(
            CONFIGURATION.economicsGET_proxy_address()
        );        

        FUELTOKEN = IERC20(
            CONFIGURATION.fueltoken_get_address()
        );

        emit ContractSyncCompleted();
    
        return true;
    }

}
