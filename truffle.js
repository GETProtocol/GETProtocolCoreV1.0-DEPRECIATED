var HDWalletProvider = require("@truffle/hdwallet-provider");
const MNEMONIC = 'X'; 

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  networks: {
    ropsten: {
      provider: function() {
        return new HDWalletProvider(MNEMONIC, "https://ropsten.infura.io/v3/xxx")
      },
      network_id: 3,
      gas: 39368     //make sure this gas allocation isn't over 4M, which is the max
    },  
    ganache: {
      host: "127.0.0.1",
      port: 7545,
      network_id: 5777, // match any network id
      from: "XXX",
      gas: 6621975
    },
    bsctestnet: {
      provider: function() {
        return new HDWalletProvider(MNEMONIC, "https://data-seed-prebsc-1-s1.binance.org:8545/")
      },
      network_id: 97,
      gas: 30000000,
    }    
  },
  compilers: { 
    solc: {
      version: "0.6.2",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
     }
   }
 }
};
