pragma solidity ^0.6.2;

import "./interfaces/IERC20.sol";
import "./utils/SafeMath.sol";
import "./utils/Address.sol";

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

contract financingSaleSimple {
    using SafeMath for uint256;
    using Address for address;

    IGETAccessControl public GET_BOUNCER;
    IERC20 public STABLE; // USDT or DAI contract address (held by the participant)
    IERC20 public USDCC; // USDC contract 
    IERC20 public FICHE; // balancer LP token derivate (held by the contract after creation)
    
    mapping(address => uint256) public USDCBalance;

    // bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    // // bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    // bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant DEFI_ROLE = keccak256("DEFI_ROLE");
    bytes32 public constant GET_TEAM_MULTISIG = keccak256("GET_TEAM_MULTISIG");
    bytes32 public constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    event FichesSold(
        address fiche_buyer,
        uint256 amount_bought
    );

    event TokenPriceChanged(
        uint256 newPrice,
        address caller
    );

    event AuctionCreated(
        uint256 _index, 
        address _creator, 
        address _asset, 
        uint256 _token
    );

    event fichesBought(
        address purchaserAddress,
        uint256 indexAuction,
        uint256 amountFPurchased,
        uint256 stablesPaid,
        uint256 fichesInventoryLeft,
        uint timestamp
    );

    struct FicheAuction {
        address eventAddress;
        address ficheAddress; // address of token that is sold
        address stableAddress; // address of stablecoin that is accepted
        address auctionCreator; // owner / admin  -> auctionAdmin
        address underwriter; // address of the 'last mile' underwriter
        uint256 startTimeAuction;
        uint256 fichePrice; // stablecoin / fiche price
        uint256 totalFicheInventory; // starting inventory LP tokens
        uint256 currentFicheInventory; // LP tokens left
        uint256 currentUSDCBalance; // how much USDC is collected to date 
        uint256 buyerCount;
        bool isFinalized;
    }

    FicheAuction[] private auctions;

    // uint256[] public indexesEvent;
    // store what auctions belong to what event eventaddress -> [1,10,15]
    mapping(address => uint256[]) public allAuctionsEvent;
    mapping(uint256 => uint256) public auctionBalance;

    constructor(
        address _bouncerAddress
    ) public {
        GET_BOUNCER = IGETAccessControl(_bouncerAddress);
    }


    /**
    @dev creates an auction for trancheTokens
    @param _ficheAddress erc20 address of tranche LP token
    @param _stableAddress erc20 address of stablecoin token
    @param _underwriter EOA address of entity that is underwriting offering
    @param _eventAddress eventaddress of the event that is financed
    @param _startTimeAuction time the auction starts 
    @param _fichePrice amount of stables(erc20) per tranche token(erc20)
    @param _totalFicheInventory amount of tranche fiches to be sold
    // TODO clean up, make this a struct
    */
    function createAuction(
                        address _ficheAddress, 
                        address _stableAddress, 
                        address _underwriter,
                        address _eventAddress,
                        uint256 _startTimeAuction,
                        uint256 _fichePrice, 
                        uint256 _totalFicheInventory
                        ) public returns (uint256) { // returns index of auction

        // check if ficheAddress is contract
        require(_ficheAddress.isContract(),
        "createAuction - _ficheAddress NOT CONTRACT");

        // check if stable address is contract
        require(_stableAddress.isContract(), "createAuction - _stableAddress NOT CONTRACT");

        // address of the LP tokens that are being sold
        FICHE = IERC20(_ficheAddress); 

        // Check if eventAddress has sufficient ficheTokens to create an auction
        require(
            FICHE.allowance(
                msg.sender, 
                address(this)
            ) >= _totalFicheInventory,
            "defi admin has too little ficheTokens"
        );

        // transfer fiche tokens to this contract
        require(
            FICHE.transferFrom(
                msg.sender, // caller / defi admin
                address(this), // contract address
                _totalFicheInventory
                ),
            "transfer of FICHE error" // total amount of fiche tokens sold
        );

        FicheAuction memory auction = FicheAuction({
            eventAddress: _eventAddress,
            ficheAddress: _ficheAddress,
            stableAddress: _stableAddress,
            auctionCreator: msg.sender,
            underwriter: _underwriter,
            startTimeAuction: _startTimeAuction,
            fichePrice: _fichePrice,
            totalFicheInventory: _totalFicheInventory,
            currentFicheInventory: _totalFicheInventory,
            currentUSDCBalance: 0,
            buyerCount: 0,
            isFinalized: false
        });

        auctions.push(auction);
        uint256 index = auctions.length -1;
        // uint256 index = 999;

        // Add index of aucion to mapping of the event, for managing multiple auctions of a single event
        allAuctionsEvent[_eventAddress].push(index);
        
        emit AuctionCreated(
            index, 
            auction.auctionCreator, 
            auction.ficheAddress, 
            auction.fichePrice
        );

        return index;
    }

    function buyFiches(
        uint256 auctionIndex,
        uint256 amountFiches
    ) public {
        FicheAuction storage auction = auctions[auctionIndex];

        uint256 _fichesLeft = auction.currentFicheInventory; // check by balanceOf()
        require(_fichesLeft >= amountFiches, "buyFiches - NOT ENOUGH FICHES");

        require(auction.auctionCreator != address(0), "buyFiches - CALLER IS ZERO ADDRESS");
        require(auction.isFinalized != true, "buyFiches - AUCTION ALREADY FINALIZED");
        
        // calc total amount of stable tokens need to be paid, to buy amountFiches 
        uint256 _stable_amount = multiply(amountFiches, auction.fichePrice);
        STABLE = IERC20(auction.stableAddress);
        FICHE = IERC20(auction.ficheAddress);

        require(
            STABLE.allowance(
                msg.sender, 
                address(this)) >= _stable_amount,
            "buyFiches - ALLOWANCE FAILED - ALLOW CONTRACT FIRST!"
        );

        require(
            STABLE.transferFrom(
                msg.sender, 
                address(this),
                _stable_amount),
            "buyFiches - TRANSFERFROM STABLES FAILED"
        );

        // UPDATE BALANCE 
        auctionBalance[auctionIndex] += _stable_amount;

        // TODO add event
        // emit stableAdded(
        //     auctionIndex,
        //     stableAddress,
        //     _stable_amount
        // );

        require(
            FICHE.balanceOf(
                address(this)) >= amountFiches,
            "buyFiches - BALANCE TOO LOW"
        );

        require(
            FICHE.approve(
                address(this), 
                amountFiches),
            "buyFiches - approval fails"
        );

        require(
            FICHE.transferFrom(
                address(this),
                msg.sender, 
                amountFiches),
            "buyFiches - TRANSFERFROM FICHES FAILED"
        );

        // change amount of fiches else
        auction.currentFicheInventory -= amountFiches;

        emit fichesBought(
            msg.sender,
            auctionIndex,
            amountFiches,
            _stable_amount,
            auction.currentFicheInventory,
            block.timestamp
        );

    }

    function getStableCollectedAuction(
        uint256 _auctionIndex
        ) public view returns (uint256) 
        {
            return auctionBalance[_auctionIndex];
        }

    function getIndexesOfEvent(
        address eventAddress
    ) public view returns (uint256[] memory)
    {
        return allAuctionsEvent[eventAddress];
    } 

    // TOOD Add modifier
    function withdrawStableAuction(
        uint256 _auctionIndex,
        address _stableAddress) public 
        {
            FicheAuction storage auction = auctions[_auctionIndex];

            // check if requested stable is the same as the collected stable
            require(
                auction.stableAddress == _stableAddress,
                "Incorrect stable address requested"
            );

            // check if the msg.sender is the admin/owner
            require(
                auction.auctionCreator == msg.sender,
                "requestor not admin"
            );

            require(
                auction.isFinalized == true,
                "Auction not finalized"
            );

            uint256 _balance = auctionBalance[_auctionIndex];
            STABLE = IERC20(_auctionIndex);

            // set balance to 0
            auctionBalance[_auctionIndex] = 0;

            require(
                STABLE.transferFrom(
                    address(this),
                    msg.sender,
                    _balance),
                "buyFiwithdrawStableAuctionches - TRANSFERFROM STABLES FAILED"
            );

            // TODO add event
        }


    // function isActive(uint256 index) public view returns (bool) { return getStatus(index) == Status.active; }

    // function getTotalAuctions() public view returns (uint256) { return auctions.length; }

    // function isFinished(uint256 index) public view returns (bool) { return getStatus(index) == Status.finished; }


    // TODO add some safemath contract import here
    function multiply(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
        return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }


}