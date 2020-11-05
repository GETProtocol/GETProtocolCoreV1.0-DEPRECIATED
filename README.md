# GET Protocol - General Smart Contract Specification - getNFT
Contract overview and definition of the GET Protocols getNFTs. Allowing P2P trading of smart tickets, lending and more. In this repo the conceptual and achritectual documentation of the GET Protocol is maintained and updated.

*This repo is still work-in-progress!*




### 1. getNFT Asset Specification
The getNFT contracts processes all the transactions from the getNFT engine. The primary rol of the getNFT engine & its contracts is to manage the exchange/trading of getNFTs as instructed by the ticketissuer. 

Note: integrators/ticketissuers do not need to understand or study or adopt this data specification. The getNFT engine will handle all data and convert it in the right format for the getNFT smart contract to process. 

###### 1 A. Identity variables specification 
Data fields on ownership of getNFTs. 

| Var | Description | Type  |
| ------ | ------ | ------ |
| *destinationAddress* | The to-be/intended future owner of a getNFT asset. | address |
| *originAddress*   | The current/past owner of a getNFT asset. |   address |
| *ticketIssuerAddress* | The address of the ticketissuer that has issued the getNFT. | address |


###### 1 B. Metadata variables specification
Data fields describing metadata of getNFTs. 

| Var        | Description           | Type  |
| ------ | ------ | ------ |
| *ticketMetadata* | Data field pointing/reference set by ticketissuer (no rules set by protocol). | string |
| *eventAddress*   | Address of the event the getNFT asset belongs to set by custody. |   address |
| *statusNft* | Metadata field specifying if getNFT is scanned. True = scanned, False = unscanned.  |   bool |

###### 1 C. Internal variables specification 
Variables that are used internally in the getNFT contact.

| Var        | Description           | Type  |
| ------ | ------ | ------ |
| *nftIndex*   | Internal reference/pointer to the asset in the smart contract.      |   uint256 |
| *_timestamp* | Data field pointing to a certain ticket/asset of the issuer. | string |
| *onlyRelayer* | Solidity modifier. Only addresses that are registered as a 'relayer' can access this func. |   msg.sender (address) |
| *onlyMinter* | Solidity modifier. Only addresses that are registered as a 'relaminteryer' can access this func.  |   msg.sender (address) |


---

### 2. getNFT Ownership Functions Specification
The getNFT contract manages the ownership and metadata management of event-assets on-chain. The getNFT engine (and its blockchain nodes) are  

**A.  primaryMint: Issuance of getNFT to address.**
This action is triggered when a ticket is sold to a fan/user. Triggering the creation of the digital twin of the ticket.

**B. secondaryTransfer: Secondary market/P2P getNFT ownership change**
This action is triggered when a ticket is resold/traded between fans.

**C. scanNFT: Validation of getNFT by scanner/issuer**
This action is triggered when a ticket is scanned validated. 

Functions A, B & C can only be called by whitelisted addresses(see section 3 of this documentation covering modifiers). If an getNFT owner wants to interact directly with their NFT, they can use the ERC721 functions (meaning, `safeTransferFrom`, `approve`, `ownerOf` etc). The getNFT is still completely compatable with the ERC271 standard, what makes a getNFT different is that it includes several 'custom' functions that allow ticketIssuers to move getNFTs as the data-base twin of the ticket changes state/hands.  

#### A1. primaryMint (OLD V0)
Mint a new getNFT to a destinationAddress(address of buyer of the getNFT). The function will return the nftIndex (uint256) of the issued getNFT. 
```javascript
    function primaryMint(address destinationAddress, address ticketIssuerAddress, address eventAddress, string memory ticketMetadata) public onlyMinter returns (uint256) {
```

This function will emit the following event to the event-log of the GET Factory contract:   `txPrimaryMint(destinationAddress, ticketIssuerAddress, nftIndex, _timestamp)`.

The values passed in the `ticketIssuerAddress`, `eventAddress` and `ticketMetadata` are stored immutably in the metadata fields of the ERC721 asset.

#### B. secondaryTransfer
If a ticket is resold to a other address this function is triggered. The getNFT custody uses a fresh wallet for each getNFT. The `originAddress` needs to be the owner of a getNFT for this function to be successful. 

```javascript
    function secondaryTransfer(address originAddress, address destinationAddress) public onlyRelayer;
```
This function will emit the following event:  `txSecondary(originAddress, destinationAddress, getAddressOfticketIssuer(nftIndex), nftIndex, _timestamp)`.

#### C. scanNFT
Function that sets the `_nftScanned` metadata field to `true` in the getNFT. This is an immutable action. The getNFT remains transferrable after this action.

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


## 4. getNFT Contract Events 

```javascript
    event txPrimaryMint(address indexed destinationAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
    event txSecondary(address originAddress, address indexed destinationAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp)
    event txScan(address originAddress, address indexed ticketIssuer, uint256 indexed nftIndex, uint _timestamp);
```

---

## Other components of the getNFT system

![Diagram Overview](./markdown_images/overview_layers.png)

- custody_docs:
- engine_docs:
- asset_factory_docs: Solidity contracts specifying GET Protocol assets. 

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


