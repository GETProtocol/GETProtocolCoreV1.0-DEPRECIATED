# GET Protocol - Smart Contract Specification
Contract overview and definition of the GET Protocols getNFTs. Allowing P2P trading of smart tickets, lending and more. In this repo the conceptual and achritectual documentation of the GET Protocol is maintained and updated.

*This repo is still work-in-progress!*

---

### 1. getNFT Variables Specification
The getNFT contracts processes all the transactions from the getNFT engine. 

Note: integrators/ticketeers do not need to understand or study or adopt this data specification. The getNFT engine will handle all data and convert it in the right format for the getNFT smart contract to process. 

###### A. Ownership variables specification 
Data fields on ownership of getNFTs. 

| Var | Description | Type  |
| ------ | ------ | ------ |
| *destinationAddress* | The to-be/intended future owner of a getNFT asset. | address |
| *originAddress*   | The current/past owner of a getNFT asset. |   address |
| *ticketeerAddress* | The address of the ticketeer that has issued the getNFT. | address |


###### B. Metadata variables specification
Data fields on metadata storage of getNFTs. 

| Var        | Description           | Type  |
| ------ | ------ | ------ |
| *ticketMetadata* | Data field pointing to a certain ticket/asset of the issuer. | string |
| *eventAddress*   | Address of the event the getNFT asset belongs to. |   address |
| *statusNft* | Metadata field specifying if getNFT is scanned. True = scanned, False = unscanned.  |   bool |

###### C. Internal variables specification 
Data fields used internally in management of getNFTs. 

| Var        | Description           | Type  |
| ------ | ------ | ------ |
| *nftIndex*   | Internal reference/pointer to the asset in the smart contract.      |   uint256 |
| *_timestamp* | Data field pointing to a certain ticket/asset of the issuer. | string |
| *onlyRelayer* | Solidity modifier. Only addresses that are registered as a 'relayer' can access this func. |   msg.sender (address) |
| *onlyMinter* | Solidity modifier. Only addresses that are registered as a 'relaminteryer' can access this func.  |   msg.sender (address) |


---

### 2. getNFT Ownership Functions Specification
The getNFT contract manages the ownership and metadata management of event-assets on-chain. There 

**A.  primaryMint: Issuance of getNFT to address.**
This action is triggered when a ticket is sold to a fan/user. Triggering the creation of the digital twin of the ticket.

**B. secondaryTransfer: Secondary market/P2P getNFT ownership change**
This action is triggered when a ticket is resold/traded between fans.

**C. scanNFT: Validation of getNFT by scanner/issuer**
This action is triggered when a ticket is scanned validated. 

Functions A, B & C can only be called by whitelisted addresses(see section 3 of this documentation covering modifiers). If an getNFT owner wants to interact directly with their NFT, they can use the ERC721 functions. 



#### A. primaryMint
Mint a new getNFT to a destinationAddress(address of buyer of the getNFT). The function will return the nftIndex (uint256) of the issued getNFT. 
```javascript
    function primaryMint(address destinationAddress, address ticketeerAddress, string memory ticketMetadata) public onlyMinter  returns (uint256) ;
```
This function will emit the following event to the event-log of the GET Factory contract:   `txPrimaryMint(destinationAddress, ticketeerAddress, nftIndex, _timestamp)`.

The values passed in the `ticketeerAddress` and `ticketMetadata` are stored immutably in the metadata fields of the ERC721 asset. 

#### B. secondaryTransfer
If a ticket is resold to a other address this function is triggered. The getNFT custody uses a fresh wallet for each getNFT. The `originAddress` needs to be the owner of a getNFT for this function to be successful. 

```javascript
    function secondaryTransfer(address originAddress, address destinationAddress) public onlyRelayer;
```
This function will emit the following event:  `txSecondary(originAddress, destinationAddress, getAddressOfTicketeer(nftIndex), nftIndex, _timestamp)`.


#### C. scanNFT
If a ticket is scanned/validated it's digital twin needs to reflect this new state.

```javascript
    function scanNFT(address originAddress) public onlyRelayer;
```
This function will emit the following event:  `emit txScan(originAddress, destinationAddress, nftIndex, _timestamp);`. As of now validating a ticket is immutable. 

---


## 3. Contract Modifiers 
To manage acces the contract uses the RoleManager modules from open zeppelin.  
1. Minter/Admin: Set contract variables, proxy adminstration, add/remove addresses to access control etc.
2. Relayer: Mint NFFs, move NFTs, store metadata in getNFTs etc

In the first versions of the GET Protocol contracts these addresses will be managed and maintained by the GET Protoocol foundation.

---

## 4. getNFT Flexible Metadata Contracts 
The NFT factory has 2 storage contracts that handle the metadata storage and structure. In order to facilitate changes to the metadata structure the contract allows for the admin to change the metadata storage contracts by setting `address public event_metadata_TE_address;` and `address public ticket_metadata_address`.


### 4-A. getNFT ticketIssuer Metadata
Consumer purchase their tickets from a webshop or platform. The types of data passed per ticketeer integrator might vary, the table below shows several options of the data that can be passed. 


| variable              | description                                                                      |   type  | required |
|-----------------------|----------------------------------------------------------------------------------|:-------:|:--------:|
| tickeer_address       | Public key hash of the ticketeer.                                                | address |    yes   |
| ticketeer_name        | Commercial name of the ticketing company / integrator / business.                |  string |    no    |
| ticketeer_shop_url    | Website of the ticketeers ticket shop / platform (where NFT can be traded)       |  string |    no    |
| ticketeer_support_url | Website of the ticketeers support department for questions about the NFT/ticket. |  string |    no    |
| listPointerT          | internal value used to store data this data type in a smart contract efficiently |   uint  |    yes   |
| tickeer_id            | Internal unique identifier of the ticketeer                                      |   uint  |    yes   |

The `tickeer_address` is the only required field. 


### 4-B. getEvent Metadata
Meta

Storage struct name: `Eventstruct`.

| variable          | description                                                    | type    | required |
|-------------------|---------------------------------------------------------------|---------|----------|
| event_address     | Public key hash of the event.                                 | address |    yes   |
| event_name        | Event slug/name describing the event.                         |  string |    no    |
| organizer_name    | Slug name of the organizer (or identifier)                    |  string |    no    |
| event_shop_url    | URL pointing to the primary/secondary/general shop of event.  |  string |    no    |
| location_cord     | Coordinates of the location of the event.                     |  string |    no    |
| date_time_gmt     | Date/time the event is scheduled to take place on.            |   uint  |    yes   |
| ticketeer_address | Address of the ticketeer/issuer that is servicing the event.  | address |    yes   |
| TicketeerStruct   | Pointer to the storage struct with ticketeer metadat.         | mapping |     -    |

The unique identifier of the event metadata struct is the `event_address`. This public key hash is set by the getNFT custody. Similar to the ticketeer metadata, editing of previously submitted data is only possible by overriding (but using the same primary key - which is always an `address`).


### 4-C. getEvent TicketType Metadata 
Event tickets are often split up in different types (general admission, weekender, VIP).


An extension of the 


Note: Ticket Types and Ticket specific Metadata will not be implemented in the first versions/deployments of the getNFT contracts. 


Example metadata contract storage:
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
        string event_shop_url;
        string location_cord;
        uint256 start_time;
        address ticketeer_address;
        TicketeerStruct ticketeerMetaData;
        uint listPointerE;
    }
</code></pre>

The `EventStruct` has a nested reference to the `TicketeerStruct`. This means that when referring to a `EventStruct` a link to the issuer (ticketeers) metadata is included. 

---


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



**2. Ticket Metadata**

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



### getNFT Contract Events 

```javascript
    event txPrimaryMint(address indexed destinationAddress, address indexed ticketeer, uint256 indexed nftIndex, uint _timestamp);
    event txSecondary(address originAddress, address indexed destinationAddress, address indexed ticketeer, uint256 indexed nftIndex, uint _timestamp)
    event txScan(address originAddress, address indexed ticketeer, uint256 indexed nftIndex, uint _timestamp);
```

---

#### Other  
- custody_docs:
- engine_docs:
- statebox_docs:
- asset_factory_docs: Solidity contracts specifying GET Protocol assets. 

![Diagram Overview](./markdown_images/overview_layers.png)


---

### Deploying the contracts in this repository
WORK IN PROGRESS (does not work yet)


```bash
# install dependencies
$ npm install

# deploy contracts (be sure to change the 'from' account in 'truffle.js')
$ truffle migrate --reset --network ganache

# start app
$ npm run dev
```


