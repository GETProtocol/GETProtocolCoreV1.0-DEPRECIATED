pragma solidity ^0.6.2;

import "./ERC721UpgradeableGET.sol";
import "./utils/CountersUpgradeable.sol";

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

contract getNFT_ERC721 is ERC721UpgradeableGET {
    IGETAccessControl public GET_BOUNCER;
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    // bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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

    function initialize_erc721(
        address address_bouncer
        ) public virtual initializer {
        __ERC721PresetMinterPauserAutoId_init();
        GET_BOUNCER = IGETAccessControl(address_bouncer);
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
    ) public returns (uint256 nftIndex) {

        // TODO Change to MINTER
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "mintERC721: ILLEGAL RELAYER");

        nftIndex = _tokenIdTracker.current(); 
        _mint(destinationAddress, nftIndex);
        _tokenIdTracker.increment();

        _setTokenURI(nftIndex, ticketURI);

        return nftIndex;
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
        uint256 nftIndex) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "relayerTransferFrom: ILLEGAL RELAYER");

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

    function editTokenURIBase(
        uint256 nftIndex,
        string memory _newTokenURI
    ) public {
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "editTokenURI: ILLEGAL RELAYER");
        _setTokenURI(nftIndex, _newTokenURI);

        emit TokenURIEdited(
            nftIndex,
            _newTokenURI,
            _msgSender()
        );
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

