pragma solidity ^0.6.0;

import "./interfaces/IERCAccessControlGET.sol";

contract getNFTMetaDataTicketType {
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

    address public manageraddress = msg.sender;
    uint public creationTime = now;

    struct TicketTypeStruct {
        uint tickettype_id;
        string tickettype_name;
        string ticket_price;
        uint listPointerT;
    }

    struct EventResaleRules {
        address event_address;
        uint max_sale_topup;
        uint min_sale_discount;
        uint cut_for_issuer:
        TicketTypeStruct ticketTypeMetadata;
        uint listPointerE;
    }

  // Mappings for the event data storage
  mapping(address => TicketTypeStruct) public allTicketTypeStructs;
  address[] public ticketIssuerAddresses;

  // Mappings for the event data storage
  mapping(address => EventResaleRules) allEventStructs;
  address[] public eventAddresses;  


  function newTicketIssuer(address ticketIssuerAddress, string memory ticketIssuerName, string memory ticketIssuerUrl) onlyFactory() public virtual returns(bool success) { 
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

  function newEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory coordinates, uint256 startingTime, address tickeerAddress) onlyFactory() public virtual returns(bool success) {
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