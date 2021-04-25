pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";
import "./interfaces/IwrapGETNFT.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IbaseGETNFT_V4.sol";
import "./interfaces/IeventMetadataStorage.sol";
import "./interfaces/IgetEventFinancing.sol";
import "./interfaces/IgetNFT_ERC721.sol";
import "./interfaces/IEconomicsGET.sol";

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

contract getEventFinancing is Initializable, ContextUpgradeable {
    IGETAccessControl public GET_BOUNCER;
    IMetadataStorage public METADATA;
    IEventFinancing public FINANCE;
    IGET_ERC721 public GET_ERC721;
    IEconomicsGET public ECONOMICS;

    IbaseGETNFT_V4 public BASE;
    IwrapGETNFT public wrapNFT;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant GET_TEAM_MULTISIG = keccak256("GET_TEAM_MULTISIG");
    bytes32 public constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    struct LoanStruct {
        address event_address; // address of event (primary key)
        address loaned_token_address; // ERC20 token address of loaned token
        address loaned_amount_token; // Total amound of token raised
        address debt_token_address; // er20 token address of published token
        address underwriter_address; // address of underwriter
        uint256 colleterized_inv_total; // total securitized
        uint256 active_nft_count; // current count of securitiztied
        // uint256 block_size; //  ??? 
        uint finalized_by_block;
        uint256 total_staked;
        // bool published_loan;
        bool finalized_loan; // default = false
    }

    function addLoanInfo(
        address _eventAddress,
        address _loanedTokenAddress,
        address _loanedTokenAmount,
        address _underwriterAddress,
        uint256 _collaterizedInvTotal,
        uint256 _stakedUnderwriter,
        uint _finalizedBy
    ) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "addLoanInfo: ILLEGAL RELAYER");

        // TODO if publishedLoad == True, revert
        // TODO if finalizedLoan == True, revert
        // TODO if finalizedBy > now, revert

        LoanStruct storage ldata = allProposalLoans[_eventAddress];
        ldata.event_address = _eventAddress;
        ldata.loaned_token_address = _loanedTokenAddress;
        ldata.loaned_amount_token = _loanedTokenAmount;
        ldata.debt_token_address = address(0);
        ldata.underwriter_address = _underwriterAddress;
        ldata.colleterized_inv_total = _collaterizedInvTotal;
        ldata.active_nft_count = 0;
        ldata.finalized_by_block = 1000; // placeholder
        ldata.total_staked = _stakedUnderwriter;
        ldata.finalized_by_block = _finalizedBy;
        ldata.finalized_loan = false;

        // emit something
    }

    function publishLoanOffer(
        address eventAddress
        ) public {

        require(GET_BOUNCER.hasRole(RELAYER_ROLE, _msgSender()), "addLoanInfo: ILLEGAL RELAYER");

        // require finalized = false
        // require current count = false
        // require _collaterizedInvTotal = Balance on eventAddress 

        } 

    mapping(address => LoanStruct) public allProposalLoans; // all loans that are still not published (no ERC20, no pool)
    mapping(address => LoanStruct) public allActiveLoans;
    mapping(address => LoanStruct) public allFinalizedLoans;

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
        ) public virtual initializer {
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
    function mintColleterizedNFTTicket(
        address underwriterAddress, // equiv to destinationAddress in primarySale
        address eventAddress,
        uint256 orderTime,
        uint256 ticketDebt,
        string memory ticketURI,
        bytes32[] memory ticketMetadata
    ) public returns (uint256 nftIndex) {

        // TODO Should only be callable by relayer of an underwriter
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "mintToUnderwriter: WRONG RELAYER");

        nftIndex = BASE.relayColleterizedMint(
            eventAddress,  // 'to' address destinationAddress
            eventAddress,  // eventAddress (the nft belongs to this adres)
            ticketDebt, // value of ticket in currency
            orderTime,
            ticketURI,
            ticketMetadata,
            true // setAsideNFT is set to true
        );

        // TODO Add colleterization logic / wrapping logic

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

        // TODO insert logic that creates debt for underwriter

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