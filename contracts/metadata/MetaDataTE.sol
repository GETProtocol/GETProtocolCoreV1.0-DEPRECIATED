pragma solidity ^0.6.0;

contract MetaDataTE {

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

    struct TicketIssuerStruct {
        address ticketissuer_address;
        string ticketissuer_name;
        string ticketissuer_url;
        uint listPointerT;
    }

    struct EventStruct {
        address event_address;
        string event_name;
        string shop_url;
        string location_cord;
        uint256 start_time;
        address ticketissuer_address;
        TicketIssuerStruct ticketIssuerMetaData;
        uint listPointerE;
    }

  // Mappings for the event data storage
  mapping(address => TicketIssuerStruct) public allTicketIssuerStructs;
  address[] public ticketIssuerAddresses;

  // Mappings for the event data storage
  mapping(address => EventStruct) allEventStructs;
  address[] public eventAddresses;  


  function newTicketIssuer(address ticketIssuerAddress, string memory ticketIssuerName, string memory ticketIssuerUrl) onlyBy(manageraddress) public virtual returns(bool success) { 
    allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_address = ticketIssuerAddress;
    allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_name = ticketIssuerName;
    allTicketIssuerStructs[ticketIssuerAddress].ticketissuer_url = ticketIssuerUrl;
    
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

  function newEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory coordinates, uint256 startingTime, address tickeerAddress) onlyBy(manageraddress) public virtual returns(bool success) {
    allEventStructs[eventAddress].event_name = eventName;
    allEventStructs[eventAddress].shop_url = shopUrl;
    allEventStructs[eventAddress].location_cord = coordinates;
    allEventStructs[eventAddress].start_time = startingTime;
    allEventStructs[eventAddress].ticketissuer_address = tickeerAddress;
    
    TicketIssuerStruct storage t = allTicketIssuerStructs[tickeerAddress];
    allEventStructs[eventAddress].ticketIssuerMetaData = t;
    
    eventAddresses.push(eventAddress);
    allEventStructs[eventAddress].listPointerE = eventAddresses.length -1;
    return true;
  }

  function getEventDataQuick(address eventAddress) public virtual view returns(address, string memory eventName, address ticketIssuerAddress, string memory ticketIssuerName) {
    return(
        allEventStructs[eventAddress].event_address,
        allEventStructs[eventAddress].event_name, 
        allEventStructs[eventAddress].ticketIssuerMetaData.ticketissuer_address, 
        allEventStructs[eventAddress].ticketIssuerMetaData.ticketissuer_name);
  }
  

  function getEventDataAll(address eventAddress) public virtual view returns(string memory eventName, string memory shopUrl, string memory locationCord, uint startTime, string memory ticketIssuerName, address, string memory ticketIssuerUrl) {
    return(
        allEventStructs[eventAddress].event_name, 
        allEventStructs[eventAddress].shop_url,
        allEventStructs[eventAddress].location_cord,
        allEventStructs[eventAddress].start_time,
        allEventStructs[eventAddress].ticketIssuerMetaData.ticketissuer_name,
        allEventStructs[eventAddress].ticketIssuerMetaData.ticketissuer_address,
        allEventStructs[eventAddress].ticketIssuerMetaData.ticketissuer_url);
  }

  function isEvent(address eventAddress) public view returns(bool isIndeed) {
    if(eventAddresses.length == 0) return false;
    return (eventAddresses[allEventStructs[eventAddress].listPointerE] == eventAddress);
  }

  function getEventCount() public view returns(uint eventCount) {
    return eventAddresses.length;
  }

  function isTicketIssuer(address ticketIssuerAddress) public view returns(bool isIndeed) {
    if(ticketIssuerAddresses.length == 0) return false;
    return (ticketIssuerAddresses[allTicketIssuerStructs[ticketIssuerAddress].listPointerT] == ticketIssuerAddress);
  }

  function geTicketIssuerCount() public view returns(uint ticketIssuerCount) {
    return ticketIssuerAddresses.length;
  }
}