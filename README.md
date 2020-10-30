# GET Protocol ERC721 -> Smart Ticket Smart Contract Standard
Contract overview and definition of the GET Protocols getNFTs. Allowing P2P trading of smart tickets, lending and more.  

In this repo the conceptual and achritectual documentation of the GET Protocol is maintained and updated.

This repo is still work-in-progress!

#### Directoires Documentation legenda  
- custody_docs
- engine_docs
- statebox_docs
- asset_factory_docs

![Diagram Overview](./markdown_images/overview_layers.png)

# GET NFT FACTORY CONTRACT POC V01
Description of the capabilities of the GET Protocol POC V01 contract. 

## 1. NFT - Initialization of contract
Information about the fields that need to be set and checked when deploying the contract. 

---
## 2. NFT - Transfer functions of smart ticketing standard

#### 2-A. Relayer transfer funcitons 

#### 2-B. Standard ERC721 transfer functions  

---
## 3. Modifiers 
To manage acces the smart ticketing standard contract uses a RoleManager from open zeppelin. This module allows admins to control whom is allowed to access certain functions in the contract. In V0 there are 2 roles. 


#### 3-A. OnlyMinter

#### 3-B. OnlyRelayer
 
---
## 4. NFT Metadata 
The V0 contract uses 2 data structs to store metadata in the factory contract. 
<pre><code>
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
</code></pre>
The EventStruct has a nested reference to a ticketeer. This means that each EventStruct is linked to a ticketeerAddress. 

#### 4-A. Storing & Updating Metadata

**1. Ticketeer MetaData**
Basic information about the ticketeer that has issued the ticket. It is the ticketeer that is reponsible for passing on the instructions. The primary key of the ticketeer is their ticketeerAddress. This is a rather static address meaning that it rarely if ever changes. 

Function: newTicketeer stores data of the ticketeer in the contract. The primary key of the struct is the publickeyhash of the ticketeer (ticketeerAddress).

<pre><code>
    function newTicketeer(address ticketeerAddress, string memory ticketeerName, string memory ticketeerUrl) public onlyRelayer returns(bool success)
</code></pre>

Variables Ticketeer (subject to change/discussion):
- ticketeerAddress
- ticketeerName
- ticketeerUrl 

**2. Event Metadata**

<pre><code>
  function newEvent(address eventAddress, string memory eventName, string memory shopUrl, string memory coordinates, uint256 startingTime, address tickeerAddress) public onlyRelayer returns(bool success)
</code></pre>

Variables Event (subject to change/discussion):
- eventAddress
- eventName
- shopUrl
- coordinates
- startingTime
- tickeerAddress


#### 4-B. Reading Metadata 

**1. Function getEventDataAll**
Fetches all the metadata of both the event & ticketeer struct. 

<pre><code>
    getEventDataAll(address eventAddress) public view returns(string memory eventName, string memory shopUrl, string memory locationCord, uint startTime, string memory ticketeerName, address, string memory ticketeerUrl)
</code></pre>

**2. Function getEventDataQuick**
Fetches only minally required metadata from the event & ticketeer struct (faster). 

<pre><code>
  function getEventDataQuick(address eventAddress) public view returns(address, string memory eventName, address ticketeerAddress, string memory ticketeerName)
</code></pre>