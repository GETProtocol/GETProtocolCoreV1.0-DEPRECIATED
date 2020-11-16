pragma solidity ^0.6.0;

import "../interfaces/IERCAccessControlGET.sol";

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
    // event updateOfEventMetadata(address indexed eventAddress, uint256 indexed _timestamp);
    // event updateOfTicketeerMetadata(address indexed ticketIssuerAddress, uint256 indexed _timestamp);

    struct Order {
        uint256 _nftIndex;
        uint256 _pricePaid;
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
        uint256 grossRevenue;
        TicketIssuerStruct ticketIssuerMetaData;
        mapping (uint256 => Order) orders;
        uint256 listPointerE;
    }

    // struct EventStruct {
    //     address event_address;
    //     string event_name;
    //     string shop_url;
    //     string location_cord;
    //     uint256 start_time;
    //     address ticketissuer_address;
    //     uint256 amountNFTs;
    //     uint256 grossRevenue;
    //     TicketIssuerStruct ticketIssuerMetaData;
    //     mapping (uint256 => Order) orders;
    //     uint256 listPointerE;
    // }

  // Mappings for the ticketIsuer data storage
  mapping(address => TicketIssuerStruct) public allTicketIssuerStructs;
  address[] public ticketIssuerAddresses;

  // Mappings for the event data storage
  mapping(address => EventStruct) allEventStructs;
  address[] public eventAddresses;  
  
  
  function addNftMeta(address eventAddress, uint256 nftIndex, uint256 pricePaid) public onlyFactory() {
      EventStruct storage c = allEventStructs[eventAddress];
      c.amountNFTs++;
      c.orders[nftIndex] = Order({_nftIndex: nftIndex, _pricePaid: pricePaid});
      // c.orders[c.amountNFTs++] = Order({_nftIndex: nftIndex, _price: pricePaid});
      c.grossRevenue += pricePaid;
  }

  // function editNftMeta(address eventAddress, uint256 nftIndex, uint256 pricePaid) public onlyFactory() {
  //     EventStruct storage c = allEventStructs[eventAddress];
  //     c.orders[nftIndex] = Order({_nftIndex: nftIndex, _pricePaid: pricePaid});
  //     // c.orders[c.amountNFTs++] = Order({_nftIndex: nftIndex, _price: pricePaid});
  //     c.grossRevenue += pricePaid;
  // }

  function newTicketIssuer(address ticketIssuerAddress, string memory ticketIssuerName, string memory ticketIssuerUrl) onlyFactory() public virtual returns(bool success) { 

    // if (ticketIssuerAddresses[allTicketIssuerStructs[ticketIssuerAddress].listPointerT] == ticketIssuerAddress) {
    //   // Metadata is being updated, as records of ticketissuer already are stored. Emits event for ticket explorer.
    //     emit updateOfTicketeerMetadata(ticketIssuerAddress, _timestamp);
    // }

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

  function registerEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory latitude, string memory longitude, uint256 startingTime, address tickeerAddress) onlyFactory() public virtual returns(bool success) {

    // if (eventAddresses[allEventStructs[eventAddress].listPointerE] == eventAddress) {
    //   // Metadata is being updated, as records of event was already stored. Emits event for ticket explorer.
    //     emit updateOfEventMetadata(eventAddress, _timestamp);
    // }

    allEventStructs[eventAddress].event_name = eventName;
    allEventStructs[eventAddress].shop_url = shopUrl;
    // allEventStructs[eventAddress].location_cord = coordinates;
    allEventStructs[eventAddress].latitude = latitude;
    allEventStructs[eventAddress].longitude = longitude;

    allEventStructs[eventAddress].start_time = startingTime;
    allEventStructs[eventAddress].ticketissuer_address = tickeerAddress;
    
    TicketIssuerStruct storage t = allTicketIssuerStructs[tickeerAddress];
    allEventStructs[eventAddress].ticketIssuerMetaData = t;
    
    eventAddresses.push(eventAddress);
    allEventStructs[eventAddress].listPointerE = eventAddresses.length -1;

    emit newEventRegistered(eventAddress, eventName, block.timestamp);

    return true;
  }

 
  function getEventDataAll(address eventAddress) public virtual view returns(string memory eventName, string memory shopUrl, uint256 startTime, address, uint256 amountNFTs, uint256 grossRevenue) {
    return(
        allEventStructs[eventAddress].event_name, 
        allEventStructs[eventAddress].shop_url,
        // allEventStructs[eventAddress].latitude,
        // allEventStructs[eventAddress].longitude,

        allEventStructs[eventAddress].start_time,
        allEventStructs[eventAddress].ticketissuer_address,
        // allEventStructs[eventAddress].ticketIssuerMetaData.ticketissuer_address,
        allEventStructs[eventAddress].amountNFTs,
        allEventStructs[eventAddress].grossRevenue);
  }
  
  function fetchOrderNFT(address eventAddress, uint256 nftIndex) public view returns(uint256 _nftIndex, uint256 _pricePaid) {
    return(
        allEventStructs[eventAddress].orders[nftIndex]._nftIndex,
        allEventStructs[eventAddress].orders[nftIndex]._pricePaid
        );
  }

  function isEvent(address eventAddress) public view returns(bool isIndeed) {
    if(eventAddresses.length == 0) return false;
    return (eventAddresses[allEventStructs[eventAddress].listPointerE] == eventAddress);
  }

  function getEventCount() public view returns(uint256 eventCount) {
    return eventAddresses.length;
  }

  function isTicketIssuer(address ticketIssuerAddress) public view returns(bool isIndeed) {
    if(ticketIssuerAddresses.length == 0) return false;
    return (ticketIssuerAddresses[allTicketIssuerStructs[ticketIssuerAddress].listPointerT] == ticketIssuerAddress);
  }

  function getTicketIssuerCount() public view returns(uint256 ticketIssuerCount) {
    return ticketIssuerAddresses.length;
  }
}