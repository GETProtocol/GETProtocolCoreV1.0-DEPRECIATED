# Non Fungible Tokens - General Description
The ERC721 is the most commonly used and accepted NFT in Ethereum.  In this repo documentation is provided explaining the use of NFTs (in a general sense) in the GET Protocol. Practical examples are provided using the ERC721 standard as it is the moest simple and well know NFT. This documentation is meant to convey the high level usage of NFTs - it does not contain or allude to the actual NFT contracts and usage.  

##### The ERC721 Standard
Information on ERC721 is widely available online. A few suggested starting points are listed below. In the remainder of this documuntation basic knowledge of ERC721 will be assumed.
- The 'official' website describing its usage and history: [erc721.org](http://erc721.org/)
- Example ERC721 project github: [ERC721 Dotta License](https://github.com/cryppadotta/dotta-license) 
- Deep technical walkthrough blog of ERC721 standard: https://medium.com/blockchannel/walking-through-the-erc721-full-implementation-72ad72735f3c

How an ERC721 behaves is deterimed by its smart contract code. It is possible to change the code for ERC721s. An NFT will be recognized as an ERC721(by blockexplorers) as long as it asheres to the asset template as described here: [EIP 721](https://eips.ethereum.org/EIPS/eip-721). If the changed smart contract code of the NFT factory (the name of the deployed contract issuing the NFTs) is changed to the extent it doesn't fit the standard anymore the NFT still exists and can be tracked. However it will not show up anymore in the blockexplorers. 

#### Take aways ERC721 usage in GET Protocol 
The main take aways for the usage of this type of asset(as it will be used in the GET Protocol) can be summarized as follows:
- There is 1 contract that will produce/issue NFTs for the whole protocol, this contract is referred to as the NFT Factory contract
- Each getNFT is unique (it has an unique identifier)
- Each getNFT stores metadata, pointing to data about the ticketeer, the event and the rules of 
- This metadata cannot be changed after creation (immutable)

---

## Deployed contracts of the GET Protocol NFT Factory on several blockchains

| Name | Compiler | Address |
| ------ | ------ | ------ |
| getNFT Factory V1 | 0.5.0 | [Klaytn Blockchain Main](https://ropsten.etherscan.io) |
---

### Metadata 1 - Ticketeer & Event Metadata 


### Metadata 2 - Ticket & resale market metadata 