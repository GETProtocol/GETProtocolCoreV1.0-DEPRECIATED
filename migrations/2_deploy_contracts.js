var GET_NFT_V2 = artifacts.require('./GET_NFT_V2.sol');
var MetaDataTE = artifacts.require('./MetaDataTE.sol');
// var BUYER_ORDERBOOK = artifacts.require('./secondarymarket/OrderbookBuyers.sol');
// var SELLER_ORDERBOOK = artifacts.require('./secondarymarket/OrderbookSellers.sol');

let _ = '        '

module.exports = async function(deployer) {
  
  await deployer.deploy(MetaDataTE);
  let metadata = await MetaDataTE.deployed();
  console.log(_ + 'MetaDataTE deployed at: ' + MetaDataTE.address);

  await deployer.deploy(GET_NFT_V2);
  let main = await GET_NFT_V2.deployed();
  console.log(_ + 'GET_NFT_V2 deployed at: ' + GET_NFT_V2.address);
  let huh = await main.updateMetadataManagerContract(MetaDataTE.address);

  let set =  await main.metadata_address();
  console.log(_ + 'Metadata address stored in contract: ' + set);
};
