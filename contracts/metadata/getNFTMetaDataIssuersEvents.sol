import "./interfaces/IERCAccessControlGET.sol";

pragma solidity ^0.6.0;

    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    AccessContractGET BOUNCER;

    constructor (address _bouncerAddress) public {
        BOUNCER = AccessContractGET(_bouncerAddress);
    }

    // AccessContractGET public constant BOUNCER = AccessContractGET(0xb32524007A28720dea1AC2c341E5465888B09b64);

    modifier onlyFactory() {
        require(BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "ACCESS DENIED - Restricted to factories.");
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
        uint256 _price;
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
        string location_cord;
        uint256 start_time;
        address ticketissuer_address;
        uint256 amountNFTs;
        uint256 grossRevenue;
        TicketIssuerStruct ticketIssuerMetaData;
        mapping (uint256 => Order) orders;
        uint256 listPointerE;
    }

  // Mappings for the event data storage
  mapping(address => TicketIssuerStruct) public allTicketIssuerStructs;
  address[] public ticketIssuerAddresses;

  // Mappings for the event data storage
  mapping(address => EventStruct) allEventStructs;
  address[] public eventAddresses;  
  
  
  function addnftIndex(address eventAddress, uint256 nftIndex, uint256 pricePaid) public onlyFactory() {
      EventStruct storage c = allEventStructs[eventAddress];
      c.orders[c.amountNFTs++] = Order({_nftIndex: nftIndex, _price: pricePaid});
      c.grossRevenue += pricePaid;
  }

  function newTicketIssuer(address ticketIssuerAddress, string memory ticketIssuerName, string memory ticketIssuerUrl) onlyFactory() public virtual returns(bool success) { 

    // Capture time of tx for the ticketexplorer
    uint256 _timestamp;
    _timestamp = block.timestamp;

    // if (ticketIssuerAddresses[allTicketIssuerStructs[ticketIssuerAddress].listPointerT] == ticketIssuerAddress) {
    //   // Metadata is being updated, as records of ticketissuer already are stored. Emits event for ticket explorer.
    //     emit updateOfTicketeerMetadata(ticketIssuerAddress, _timestamp);
    // }

    allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_address = ticketIssuerAddress;
    allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_name = ticketIssuerName;
    allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_url = ticketIssuerUrl;

    emit newTicketIssuerMetaData(ticketIssuerAddress, ticketIssuerName, _timestamp);
    
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

  function newEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory coordinates, uint256 startingTime, address tickeerAddress) onlyFactory() public virtual returns(bool success) {

    // Capture time of tx for the ticketexplorer
    uint256 _timestamp;
    _timestamp = block.timestamp;

    // if (eventAddresses[allEventStructs[eventAddress].listPointerE] == eventAddress) {
    //   // Metadata is being updated, as records of event was already stored. Emits event for ticket explorer.
    //     emit updateOfEventMetadata(eventAddress, _timestamp);
    // }

    allEventStructs[eventAddress].event_name = eventName;
    allEventStructs[eventAddress].shop_url = shopUrl;
    allEventStructs[eventAddress].location_cord = coordinates;
    allEventStructs[eventAddress].start_time = startingTime;
    allEventStructs[eventAddress].ticketissuer_address = tickeerAddress;
    
    TicketIssuerStruct storage t = allTicketIssuerStructs[tickeerAddress];
    allEventStructs[eventAddress].ticketIssuerMetaData = t;
    
    eventAddresses.push(eventAddress);
    allEventStructs[eventAddress].listPointerE = eventAddresses.length -1;

    emit newEventRegistered(eventAddress, eventName, _timestamp);

    return true;
  }

 
  function getEventDataAll(address eventAddress) public virtual view returns(string memory eventName, string memory shopUrl, string memory locationCord, uint256 startTime, address, uint256 amountNFTs, uint256 grossRevenue) {
    return(
        allEventStructs[eventAddress].event_name, 
        allEventStructs[eventAddress].shop_url,
        allEventStructs[eventAddress].location_cord,
        allEventStructs[eventAddress].start_time,
        allEventStructs[eventAddress].ticketIssuerMetaData.ticketissuer_address,
        allEventStructs[eventAddress].amountNFTs,
        allEventStructs[eventAddress].grossRevenue);
  }
  
  function fetchOrderNFT(address eventAddress, uint256 nftIndex) public view returns(uint256 _nftIndex, uint256 _price) {
    return(
        allEventStructs[eventAddress].orders[nftIndex]._nftIndex,
        allEventStructs[eventAddress].orders[nftIndex]._price
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