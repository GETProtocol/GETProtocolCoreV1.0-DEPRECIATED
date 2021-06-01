// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";
import "./utils/ContextUpgradeable.sol";
import "./interfaces/IwrapGETNFT.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IbaseGETNFT.sol";
import "./interfaces/IeventMetadataStorage.sol";
import "./interfaces/IgetEventFinancing.sol";
import "./interfaces/IgetNFT_ERC721.sol";
import "./interfaces/IEconomicsGET.sol";
import "./interfaces/IticketFuelDepotGET.sol";

import "./interfaces/IGETAccessControl.sol";


contract getEventFinancing is Initializable, ContextUpgradeable {

    IGETAccessControl private GET_BOUNCER;
    IMetadataStorage private METADATA;
    IEconomicsGET private ECONOMICS;
    IbaseGETNFT private BASE;
    IwrapGETNFT private wrapNFT;
    IticketFuelDepotGET private DEPOT;

    string public constant contractName = "getEventFinancing";
    string public constant contractVersion = "1";

    bytes32 private constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 private constant GET_ADMIN = keccak256("GET_ADMIN");

    function _initialize_event_financing(
        address address_bouncer
        ) public virtual initializer 
        {
        GET_BOUNCER = IGETAccessControl(address_bouncer);
        }

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

    mapping(address => LoanStruct) private allProposalLoans; // all loans that are still not published (no ERC20, no pool)
    mapping(address => LoanStruct) private allActiveLoans;
    mapping(address => LoanStruct) private allFinalizedLoans;

    event fromCollaterizedInventory(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 primaryPrice,
        uint256 orderTime,
        uint timestamp
    );

    event txMintUnderwriter(
        address underwriterAddress,
        address eventAddress,
        uint256 ticketDebt,
        string ticketURI,
        uint256 orderTime,
        uint timestamp
    );

    event ticketCollaterized(
        uint256 nftIndex,
        address eventAddress
    );

    event ConfigurationChanged(
        address addressBouncer, 
        address addressMetadata, 
        address addressEconomics,
        address addressBase
    );

    // MODIFIERS 

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "CALLER_NOT_RELAYER");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "CALLER_NOT_ADMIN");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(
            GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "CALLER_NOT_FACTORY");
        _;
    }

    // CONTRACT ADMINSTRATION

    function changeConfiguration(
        address newAddressBouncer,
        address newAddressMetadata,
        address newAddressEconomics,
        address newAddressBase
    ) external onlyAdmin {
        
        GET_BOUNCER = IGETAccessControl(newAddressBouncer);
        METADATA = IMetadataStorage(newAddressMetadata);
        ECONOMICS = IEconomicsGET(newAddressEconomics);
        BASE = IbaseGETNFT(newAddressBase);

        emit ConfigurationChanged(
            newAddressBouncer,
            newAddressMetadata,
            newAddressEconomics,
            newAddressBase
        );
    }


    function addLoanInfo(
        address eventAddress,
        address loanedTokenAddress,
        address loanedTokenAmount,
        address underwriterAddress,
        uint256 collaterizedInvTotal,
        uint256 stakedUnderwriter,
        uint finalizedBy
    ) public onlyRelayer {

        LoanStruct storage ldata = allProposalLoans[eventAddress];
        ldata.event_address = eventAddress;
        ldata.loaned_token_address = loanedTokenAddress;
        ldata.loaned_amount_token = loanedTokenAmount;
        ldata.debt_token_address = address(0);
        ldata.underwriter_address = underwriterAddress;
        ldata.colleterized_inv_total = collaterizedInvTotal;
        ldata.active_nft_count = 0;
        ldata.finalized_by_block = 1000; // placeholder
        ldata.total_staked = stakedUnderwriter;
        ldata.finalized_by_block = finalizedBy;
        ldata.finalized_loan = false;
    }

    /**
    @dev function can only be called by a factory contract
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint - this is the index that is being collaterized 
    @param eventAddress unique identifier of the event, assigned by GETCustordy
    @param strikeValue value in USD of the nft when it is sold in the primary market, in the futere, ie strike value 
     */
    function registerCollaterization(
        uint256 nftIndex,
        address eventAddress,
        uint256 strikeValue
    ) external onlyFactory {


        emit ticketCollaterized(
            nftIndex,
            eventAddress
        );
    }


    // Moves NFT from collateral contract adres to user 
    function collateralizedNFTSold(
        uint256 nftIndex,
        address underwriterAddress,
        address destinationAddress,
        uint256 orderTime,
        uint256 primaryPrice
    ) external onlyFactory {

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