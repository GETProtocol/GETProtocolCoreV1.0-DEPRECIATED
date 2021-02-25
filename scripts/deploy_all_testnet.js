const { ethers, upgrades } = require("hardhat");

const NUM_CREATURES1 = 5;
const NUM_CREATURES2 = 10;

async function main() {
    // We get the contract to deploy
    const AccessControlGET = await ethers.getContractFactory("AccessControlUpgradeableGET");
    console.log("Deploying AccessControlGET...");
    const _access = await upgrades.deployProxy(AccessControlGET, { initializer: '__AccessControlGET_init' });
    await _access.deployed();
    console.log("Access Control upgradeable deployed to:", _access.address);

    const MINTER_ROLE = web3.utils.soliditySha3('MINTER_ROLE');
    const FACTORY_ROLE = web3.utils.soliditySha3('FACTORY_ROLE');
    const PAUSER_ROLE = web3.utils.soliditySha3('PAUSER_ROLE');
    const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';

    // const accounts = await ethers.getSigners();

    // minter0 = await _access.getRoleMemberCount(MINTER_ROLE);
    // console.log("Amount of MINTER roles is: ", minter0.toString());

    // admin0 = await _access.hasRole(DEFAULT_ADMIN_ROLE, accounts[1].address);
    // console.log("Account 0 is the admin (true): ", admin0.toString());

    // factory0 = await _access.getRoleMemberCount(FACTORY_ROLE);
    // console.log("Amount of Factory roles is: ", factory0.toString());

    // admin1 = await _access.hasRole(MINTER_ROLE, accounts[1].address);
    // console.log("Account 1 is the minter (false): ", admin1.toString());

    // const result = await _access.connect(accounts[0]).grantRole(MINTER_ROLE, accounts[1].address);

    // admin2 = await _access.hasRole(MINTER_ROLE, accounts[1].address);
    // console.log("Account 1 is the minter (true): ", admin2.toString());

    // Normal metadata contract
    const metadataLogic = await ethers.getContractFactory("metadataLogic");
    console.log("Deploying metadataLogic Proxy...");
    const _metadata = await upgrades.deployProxy(metadataLogic, [_access.address], { initializer: '__initialize_metadata' });
    await _metadata.deployed();
    console.log("Metadata deployed to:", _metadata.address);


  // Normal metadata contract
    const Base = await ethers.getContractFactory("baseNFT");
    console.log("Deploying baseNFT...");
    const base = await upgrades.deployProxy(Base, [_access.address, _metadata.address], { initializer: 'initialize_base' });
    await base.deployed();
    console.log("BaseNFT deployed to:", base.address);


    const accounts = await ethers.getSigners();

    const result = await _access.connect(accounts[0]).grantRole(FACTORY_ROLE, base.address);

    var amount_nfts = await base.totalSupply();
    console.log("Total amount_nfts of events:" + amount_nfts); 

    // Creatures issued directly to the owner.
    for (var i = 0; i < NUM_CREATURES1; i++) {
      var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
      // const result = await _contract.connect().registerEvent(accounts[i].address, "eventname", "whatever.nl", bytedata, bytedata, bytedata, i, bytedata);
      const result = await base.connect(accounts[0]).primaryMint(accounts[i].address, accounts[0].address, 321, bytedata);
      console.log("Minted. Transaction: " + result.hash + "   " + i);
    }

    var amount_nfts = await base.totalSupply();
    console.log("Total amount_nfts of events dadf:" + amount_nfts); 

    // Creatures issued directly to the owner.
    for (var i = 0; i < NUM_CREATURES2; i++) {
      var bytedata = ethers.utils.formatBytes32String("DATA  " + i);
      // const result = await _contract.connect().registerEvent(accounts[i].address, "eventname", "whatever.nl", bytedata, bytedata, bytedata, i, bytedata);
      const result = await base.connect(accounts[0]).registerEvent(accounts[i].address, "eventname", "whatever.nl", bytedata, bytedata, bytedata, i, bytedata, bytedata);
      console.log("Event metadata registered. Transaction: " + result.hash + "   " + i);
    }

    var amount_events = await base.getEventCount();
    console.log("Total amount of events:" + amount_events);

    // Creatures issued directly to the owner.
    for (var i = 0; i < NUM_CREATURES1; i++) {
      const called = await base.getEventDataAll(accounts[i].address);
      console.log("Event metadata: " + i + called);
    }

    // const result = await _access.connect(accounts[0]).grantRole(FACTORY_ROLE, accounts[1].address);
    
    // factory0 = await _access.getRoleMemberCount(FACTORY_ROLE);
    // console.log("Amount of Factory roles is: ", factory0.toString());

  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });



