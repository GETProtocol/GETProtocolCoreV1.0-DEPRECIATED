pragma solidity ^0.6.0;

import "../interfaces/IERCAccessControlGET.sol";
import "../Initializable.sol";

pragma experimental ABIEncoderV2;

contract getNFTMetaDataIssuersEvents is Initializable {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    AccessContractGET BOUNCER;

    function initialize() public payable initializer {
      BOUNCER = AccessContractGET(0xaC2D9016b846b09f441AbC2756b0895e529971CD);
    }

    modifier onlyFactory() {
        require(BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "ACCESS DENIED - Restricted to GET Factory Contracts.");
        _;
    } 

    address public deployeraddress = msg.sender;
    uint256 public deployertime = now;

    event newEventRegistered(address indexed eventAddress, string indexed eventName, uint256 indexed _timestamp);
    event newTicketIssuerMetaData(address indexed ticketIssuerAddress, string indexed ticketIssuerName, uint256 indexed _timestamp);
    event primaryMarketNFTSold(address indexed eventAddress, uint256 indexed nftIndex, uint256 indexed pricePaidP);
    event secondaryMarketNFTSold(address indexed eventAddress, uint256 indexed nftIndex, uint256 indexed pricePaidS);

    struct OrdersPrimary {
        uint256 _nftIndex;
        uint256 _pricePaidP;
        uint256 _orderTimeP;
    }

    struct OrdersSecondary {
        uint256 _nftIndex;
        uint256 _pricePaidS;
        uint256 _orderTimeS;
    }  

    struct TicketIssuerStruct {
        address ticketissuer_address;
        string ticketissuer_name;
        string ticketissuer_url;
        uint256 listPointerT;
    }


    struct EventStruct {
        address event_address;
        string event_name;
        string shop_url;
        string latitude;
        string longitude;
        uint256 start_time;
        address ticketissuer_address;
        uint256 amountNFTs;
        uint256 grossRevenuePrimary;
        uint256 grossRevenueSecondary;
        string callback_url;
        mapping (uint256 => OrdersPrimary) ordersprimary;
        mapping (uint256 => OrdersSecondary) orderssecondary;
        uint256 listPointerE;
    }

  // Mappings for the ticketIsuer data storage
  mapping(address => TicketIssuerStruct) public allTicketIssuerStructs;
  address[] public ticketIssuerAddresses;

  // Mappings for the event data storage
  mapping(address => EventStruct) public allEventStructs;
  address[] public eventAddresses;  
  
  /** 
  * @dev TODO
  * @param eventAddress address of event controlling getNFT 
  * @param nftIndex unique index of getNFT
  * @param orderTimeP timestamp passed on by ticket issuer of order time of database ticket twin (primary market getNFT)
  * @param pricePaidP price of primary sale as passed on by ticket issuer
  */  
  function addNftMetaPrimary(address eventAddress, uint256 nftIndex, uint256 orderTimeP, uint256 pricePaidP) public onlyFactory() {
      EventStruct storage c = allEventStructs[eventAddress];
      c.amountNFTs++;
      c.ordersprimary[nftIndex] = OrdersPrimary({_nftIndex: nftIndex, _pricePaidP: pricePaidP, _orderTimeP: orderTimeP});
      c.grossRevenuePrimary += pricePaidP;
      emit primaryMarketNFTSold(eventAddress, nftIndex, pricePaidP);
  }

  /** 
  * @dev TODO
  * @param eventAddress address of event controlling getNFT 
  * @param nftIndex unique index of getNFT
  * @param orderTimeS timestamp passed on by ticket issuer of order time of database ticket twin (secondary market getNFT)
  * @param pricePaidS price of secondary sale as passed on by ticket issuer
  */   
  function addNftMetaSecondary(address eventAddress, uint256 nftIndex, uint256 orderTimeS, uint256 pricePaidS) public onlyFactory() {
      EventStruct storage c = allEventStructs[eventAddress];
      c.orderssecondary[nftIndex] = OrdersSecondary({_nftIndex: nftIndex, _pricePaidS: pricePaidS, _orderTimeS: orderTimeS});
      c.grossRevenueSecondary += pricePaidS;
      emit secondaryMarketNFTSold(eventAddress, nftIndex, pricePaidS);
  }

  function newTicketIssuer(address ticketIssuerAddress, string memory ticketIssuerName, string memory ticketIssuerUrl) onlyFactory() public virtual returns(bool success) { 

    allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_address = ticketIssuerAddress;
    allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_name = ticketIssuerName;
    allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_url = ticketIssuerUrl;

    emit newTicketIssuerMetaData(ticketIssuerAddress, ticketIssuerName, block.timestamp);
    
    ticketIssuerAddresses.push(ticketIssuerAddress);
    allTicketIssuerStructs[ticketIssuerAddress].listPointerT = ticketIssuerAddresses.length - 1;
    return true;
  }

  function getTicketIssuer(address ticketIssuerAddress) public virtual view returns(address, string memory ticketIssuerName, string memory ticketIssuerUrl) {
    return(
      allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_address,
      allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_name,
      allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_url);
  }

  function registerEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory latitude, string memory longitude, uint256 startingTime, address ticketIssuer, string memory callbackUrl) onlyFactory() public virtual returns(bool success) {

    allEventStructs[eventAddress].event_name = eventName;
    allEventStructs[eventAddress].shop_url = shopUrl;
    allEventStructs[eventAddress].latitude = latitude;
    allEventStructs[eventAddress].longitude = longitude;

    allEventStructs[eventAddress].start_time = startingTime;
    allEventStructs[eventAddress].ticketissuer_address = ticketIssuer;

    allEventStructs[eventAddress].callback_url = callbackUrl;
    eventAddresses.push(eventAddress);
    allEventStructs[eventAddress].listPointerE = eventAddresses.length -1;

    emit newEventRegistered(eventAddress, eventName, block.timestamp);

    return true;
  }

 
  function getEventDataAll(address eventAddress) public virtual view returns(string memory eventName, string memory shopUrl, uint256 startTime, address, uint256 amountNFTs, uint256 grossRevenuePrimary) {
    return(
        allEventStructs[eventAddress].event_name, 
        allEventStructs[eventAddress].shop_url,
        allEventStructs[eventAddress].start_time,
        allEventStructs[eventAddress].ticketissuer_address,
        allEventStructs[eventAddress].amountNFTs,
        allEventStructs[eventAddress].grossRevenuePrimary);
  }
  
  function fetchPrimaryOrderNFT(address eventAddress, uint256 nftIndex) public view returns(uint256 _nftIndex, uint256 _pricePaidP) {
    return(
        allEventStructs[eventAddress].ordersprimary[nftIndex]._nftIndex,
        allEventStructs[eventAddress].ordersprimary[nftIndex]._pricePaidP
        );
  }

  function fetchSecondaryOrderNFT(address eventAddress, uint256 nftIndex) public view returns(uint256 _nftIndex, uint256 _pricePaidS) {
    return(
        allEventStructs[eventAddress].orderssecondary[nftIndex]._nftIndex,
        allEventStructs[eventAddress].orderssecondary[nftIndex]._pricePaidS
        );
  }

  function isEvent(address eventAddress) public view returns(bool isIndeed) {
    if(eventAddresses.length == 0) return false;
    return (eventAddresses[allEventStructs[eventAddress].listPointerE] == eventAddress);
  }

  function getEventCount() public view returns(uint256 eventCount) {
    return eventAddresses.length;
  }

    /**
    * @dev TD
    */
  function isTicketIssuer(address ticketIssuerAddress) public view returns(bool isIndeed) {
    if(ticketIssuerAddresses.length == 0) return false;
    return (ticketIssuerAddresses[allTicketIssuerStructs[ticketIssuerAddress].listPointerT] == ticketIssuerAddress);
  }

    /**
    * @dev TD
    */
  function getTicketIssuerCount() public view returns(uint256 ticketIssuerCount) {
    return ticketIssuerAddresses.length;
  }
}