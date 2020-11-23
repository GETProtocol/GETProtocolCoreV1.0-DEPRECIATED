pragma solidity ^0.6.0;

import "../interfaces/IERCAccessControlGET.sol";
pragma experimental ABIEncoderV2;

contract getNFTMetaDataIssuersEvents {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    AccessContractGET BOUNCER;

    constructor (address _bouncerAddress) public {
        BOUNCER = AccessContractGET(_bouncerAddress);
    }

    modifier onlyFactory() {
        require(BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "ACCESS DENIED - Restricted to GET Factory Contracts.");
        _;
    } 

    address public deployeraddress = msg.sender;
    uint256 public deployertime = now;

    event newEventRegistered(address indexed eventAddress, string indexed eventName, uint256 indexed _timestamp);
    event newTicketIssuerMetaData(address indexed ticketIssuerAddress, string indexed ticketIssuerName, uint256 indexed _timestamp);
    event primaryMarketNFTSold(address indexed eventAddress, uint256 indexed nftIndex, uint256 indexed pricePaid);
    event secondaryMarketNFTSold(address indexed eventAddress, uint256 indexed nftIndex, uint256 indexed pricePaid);

    struct OrdersPrimary {
        uint256 _nftIndex;
        uint256 _pricePaid;
        uint256 _orderTimeP;
    }

    struct OrdersSecondary {
        uint256 _nftIndex;
        uint256 _pricePaid;
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
  */  
  function addNftMetaPrimary(address eventAddress, uint256 nftIndex, uint256 orderTime, uint256 pricePaid) public onlyFactory() {
      EventStruct storage c = allEventStructs[eventAddress];
      c.amountNFTs++;
      c.ordersprimary[nftIndex] = OrdersPrimary({_nftIndex: nftIndex, _pricePaid: pricePaid, _orderTime: orderTime});
      c.grossRevenuePrimary += pricePaid;
      emit primaryMarketNFTSold(eventAddress, nftIndex, pricePaid);
  }

  /** 
  * @dev TODO
  */  
  function addNftMetaSecondary(address eventAddress, uint256 nftIndex, uint256 orderTime, uint256 pricePaid, _orderTime: orderTime) public onlyFactory() {
      EventStruct storage c = allEventStructs[eventAddress];
      c.orderssecondary[nftIndex] = OrdersSecondary({_nftIndex: nftIndex, _pricePaid: pricePaid});
      c.grossRevenueSecondary += pricePaid;
      emit secondaryMarketNFTSold(eventAddress, nftIndex, pricePaid);
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
  
  function fetchPrimaryOrderNFT(address eventAddress, uint256 nftIndex) public view returns(uint256 _nftIndex, uint256 _pricePaid) {
    return(
        allEventStructs[eventAddress].ordersprimary[nftIndex]._nftIndex,
        allEventStructs[eventAddress].ordersprimary[nftIndex]._pricePaid
        );
  }

  function fetchSecondaryOrderNFT(address eventAddress, uint256 nftIndex) public view returns(uint256 _nftIndex, uint256 _pricePaid) {
    return(
        allEventStructs[eventAddress].orderssecondary[nftIndex]._nftIndex,
        allEventStructs[eventAddress].orderssecondary[nftIndex]._pricePaid
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