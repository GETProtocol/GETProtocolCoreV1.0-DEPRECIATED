pragma solidity ^0.6.0;

// import "./RelayerRole.sol";

contract MetaDataManagerTicketeerEvent {

    address public manageraddress = msg.sender;
    // uint public creationTime = now;

    function changeManager(address _newManager)
        public
        onlyBy(manageraddress)
    {
        manageraddress = _newManager;
    }

    modifier onlyBy(address _account)
    {
        require(
            msg.sender == _account,
            "Sender not authorized."
        );
        _;
    }

    struct TicketeerStruct {
        address tickeer_address;
        string ticketeer_name;
        string ticketeer_url;
        uint listPointerT;
    }

    struct EventStruct {
        address event_address;
        string event_name;
        string shop_url;
        string location_cord;
        uint256 start_time;
        address ticketeer_address;
        TicketeerStruct ticketeerMetaData;
        uint listPointerE;
    }

  // Mappings for the event data storage
  mapping(address => TicketeerStruct) public allTicketeerStructs;
  address[] public ticketeerAddresses;

  // Mappings for the event data storage
  mapping(address => EventStruct) allEventStructs;
  address[] public eventAddresses;  


  function newTicketeer(address ticketeerAddress, string memory ticketeerName, string memory ticketeerUrl) onlyBy(manageraddress) public virtual returns(bool success) { 
    allTicketeerStructs[ticketeerAddress].tickeer_address = ticketeerAddress;
    allTicketeerStructs[ticketeerAddress].ticketeer_name = ticketeerName;
    allTicketeerStructs[ticketeerAddress].ticketeer_url = ticketeerUrl;
    
    ticketeerAddresses.push(ticketeerAddress);
    allTicketeerStructs[ticketeerAddress].listPointerT = ticketeerAddresses.length - 1;
    return true;
  }

  function getTicketeer(address ticketeerAddress) public virtual view returns(address, string memory ticketeerName, string memory ticketeerUrl) {
    return(
      allTicketeerStructs[ticketeerAddress].tickeer_address,
      allTicketeerStructs[ticketeerAddress].ticketeer_name,
      allTicketeerStructs[ticketeerAddress].ticketeer_url);
  }

  function newEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory coordinates, uint256 startingTime, address tickeerAddress) onlyBy(manageraddress) public virtual returns(bool success) {
    allEventStructs[eventAddress].event_name = eventName;
    allEventStructs[eventAddress].shop_url = shopUrl;
    allEventStructs[eventAddress].location_cord = coordinates;
    allEventStructs[eventAddress].start_time = startingTime;
    allEventStructs[eventAddress].ticketeer_address = tickeerAddress;
    
    TicketeerStruct storage t = allTicketeerStructs[tickeerAddress];
    allEventStructs[eventAddress].ticketeerMetaData = t;
    
    eventAddresses.push(eventAddress);
    allEventStructs[eventAddress].listPointerE = eventAddresses.length -1;
    return true;
  }

  function getEventDataQuick(address eventAddress) public virtual view returns(address, string memory eventName, address ticketeerAddress, string memory ticketeerName) {
    return(
        allEventStructs[eventAddress].event_address,
        allEventStructs[eventAddress].event_name, 
        allEventStructs[eventAddress].ticketeerMetaData.tickeer_address, 
        allEventStructs[eventAddress].ticketeerMetaData.ticketeer_name);
  }
  

  function getEventDataAll(address eventAddress) public virtual view returns(string memory eventName, string memory shopUrl, string memory locationCord, uint startTime, string memory ticketeerName, address, string memory ticketeerUrl) {
    return(
        allEventStructs[eventAddress].event_name, 
        allEventStructs[eventAddress].shop_url,
        allEventStructs[eventAddress].location_cord,
        allEventStructs[eventAddress].start_time,
        allEventStructs[eventAddress].ticketeerMetaData.ticketeer_name,
        allEventStructs[eventAddress].ticketeerMetaData.tickeer_address,
        allEventStructs[eventAddress].ticketeerMetaData.ticketeer_url);
  }

  function isEvent(address eventAddress) public view returns(bool isIndeed) {
    if(eventAddresses.length == 0) return false;
    return (eventAddresses[allEventStructs[eventAddress].listPointerE] == eventAddress);
  }

  function getEventCount() public view returns(uint eventCount) {
    return eventAddresses.length;
  }

  function isTicketeer(address ticketeerAddress) public view returns(bool isIndeed) {
    if(ticketeerAddresses.length == 0) return false;
    return (ticketeerAddresses[allTicketeerStructs[ticketeerAddress].listPointerT] == ticketeerAddress);
  }

  function getTicketeerCount() public view returns(uint ticketeerCount) {
    return ticketeerAddresses.length;
  }
}