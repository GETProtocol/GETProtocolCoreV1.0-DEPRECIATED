// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

import "./utils/Initializable.sol";
import "./ERC721UpgradeableGET.sol";
import "./utils/CountersUpgradeable.sol";
import "./interfaces/IGETAccessControl.sol";

contract getNFT_ERC721 is Initializable, ERC721UpgradeableGET {
    IGETAccessControl public GET_BOUNCER;
    bytes32 private constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 private constant GET_ADMIN = keccak256("GET_ADMIN");

    string public constant contractName = "getNFT_ERC721";
    string public constant contractVersion = "1";

    function _initialize_erc721(
        address address_bouncer
        ) public virtual initializer {
        __ERC721PresetMinterPauserAutoId_init();
        GET_BOUNCER = IGETAccessControl(address_bouncer);
    }

    event RelayerTransferFrom(
        uint256 nftIndex,
        address originAddress,
        address destinationAddress,
        address requester
    );

    event TokenURIEdited(
        uint256 nftIndex,
        string newTokenURI,
        address requester
    );

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(
            GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "CALLER_NOT_FACTORY");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(
            GET_BOUNCER.hasRole(GET_ADMIN, msg.sender), "CALLER_NOT_ADMIN");
        _;
    }

    function __ERC721PresetMinterPauserAutoId_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained("GET Protocol ticketFactory", "getNFT");
        __ERC721PresetMinterPauserAutoId_init_unchained();
    }

    function __ERC721PresetMinterPauserAutoId_init_unchained() internal initializer {
        _setBaseURI("www.get-protocol.io");
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdTracker;   

    function mintERC721(
        address destinationAddress,
        string memory ticketURI
    ) public onlyFactory returns (uint256 nftIndexE) {

        nftIndexE = _tokenIdTracker.current(); 
        _mint(destinationAddress, nftIndexE);
        _setTokenURI(nftIndexE, ticketURI);
        _tokenIdTracker.increment();

        return nftIndexE;
    }

    /**  
    * @dev Only used/called by GET Protocol relayer 
    * @notice The function assumes that the originAddress has signed the tx. 
    * @param originAddress the address the NFT will be extracted from
    * @param destinationAddress the address of the ticketeer that will receive the NFT
    * @param nftIndex the index of the NFT that will be returned to the tickeer
    */
    function relayerTransferFrom(
        address originAddress, 
        address destinationAddress, 
        uint256 nftIndex) public onlyFactory {

        _beforeTokenTransfer(originAddress, destinationAddress, nftIndex);

        _tokenApprovals[nftIndex] = destinationAddress;
        // emit Approval(ownerOf(nftIndex), destinationAddress, nftIndex);

        _relayerHelper(originAddress, destinationAddress, nftIndex);
        
        emit RelayerTransferFrom(
            nftIndex,
            originAddress,
            destinationAddress,
            _msgSender()
        );

        // emit Transfer(originAddress, destinationAddress, nftIndex);
    }

    function editTokenURI(
        uint256 nftIndex,
        string memory _newTokenURI
    ) public onlyFactory {

        _setTokenURI(nftIndex, _newTokenURI);

        emit TokenURIEdited(
            nftIndex,
            _newTokenURI,
            _msgSender()
        );
    }

    function editBase(
        string memory newBaseURL
    ) public onlyAdmin {

        _setBaseURI(newBaseURL);
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId
        ) internal virtual override(ERC721UpgradeableGET) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    uint256[49] private __gap;

}

