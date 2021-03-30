pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";
import "./interfaces/IwrapGETNFT.sol";
import "./interfaces/IERC20.sol";

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

// import "./IgetNFT_ERC721.sol";
import "./interfaces/IbaseGETNFT_V4.sol";


contract getEventFinancing is Initializable {
    IGETAccessControl public GET_BOUNCER;
    // IGET_ERC721 public GET_ERC721;
    IbaseGETNFT_V4 public BASE;
    IwrapGETNFT public wrapNFT;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");

    event fromCollaterizedInventory(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 primaryPrice,
        uint256 orderTime,
        uint _timestamp
    );

    event txMintUnderwriter(
        address underwriterAddress,
        address eventAddress,
        uint256 ticketDebt,
        string ticketURI,
        uint256 orderTime,
        uint _timestamp
    );

    event BaseConfigured(
        address baseAddress,
        address requester
    );

    function initialize_event_financing(
        address address_bouncer
        ) public initializer {
        GET_BOUNCER = IGETAccessControl(address_bouncer);
        }

    function configureBase(address baseAddress) public {
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "configureBase: WRONG RELAYER");
        BASE = IbaseGETNFT_V4(baseAddress);
        emit BaseConfigured(baseAddress, msg.sender);
    }


    /**
    @dev mints getNFT to underwriterAddress
    @dev function is called by primarySale
    @notice only called if the events ticket inventory is collaterized
    @notice this function requires an wrapping contract to be deployed
    */
    // 
    function mintSetAsideNFTTicket(
        address underwriterAddress, // equiv to destinationAddress in primarySale
        address eventAddress,
        uint256 orderTime,
        uint256 ticketDebt,
        string memory ticketURI,
        bytes32[] memory ticketMetadata
    ) public returns (uint256 nftIndex) {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "mintToUnderwriter: WRONG RELAYER");

        nftIndex = BASE.mintGETNFT(
            eventAddress,  // 'to' address destinationAddress
            eventAddress, 
            ticketDebt, // value of ticket in currency
            orderTime,
            ticketURI,
            ticketMetadata,
            true // setAsideNFT
        );

        emit txMintUnderwriter(
            underwriterAddress,
            eventAddress,
            ticketDebt,
            ticketURI,
            orderTime,
            block.timestamp
        );

        return nftIndex;

    }


    // Moves NFT from collateral contract adres to user 
    function collateralizedNFTSold(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 orderTime,
        uint256 primaryPrice
    ) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "mintToUnderwriter: WRONG RELAYER");

        // uint256 nftIndex = tokenOfOwnerByIndex(underwriterAddress, 0);
        // require(_ticketInfo[nftIndex].valid == false, "_primaryCollateralTransfer - NFT INVALIDATED");
        // require(ownerOf(nftIndex) == underwriterAddress, "_primaryCollateralTransfer - WRONG UNDERWRITER");     

        // getNFTBase.relayerTransferFrom(
        //     underwriterAddress, 
        //     destinationAddress, 
        //     nftIndex
        // );

        emit fromCollaterizedInventory(
            nftIndex,
            underwriterAddress,
            destinationAddress,
            primaryPrice,
            orderTime,
            block.timestamp
        );

    }
}