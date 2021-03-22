const { ethers, upgrades } = require("hardhat");

async function main() {

    console.log("Start of deploying all contracts.")

    // Deploying access control 
    const Access = await ethers.getContractFactory("AccessControlGET");
    console.log("1 Deploying AccessControlGET...");
    const access = await upgrades.deployProxy(Access, { initializer: '__AccessControlGET_init' });
    await access.deployed();
    console.log("Access Control upgradeable deployed to:", access.address);

    const accessCAddress = access.address
    
    // Normal metadata contract with proxy
    const Metadata = await ethers.getContractFactory("eventMetadataStorage");
    console.log("2 Deploying metadataLogic Proxy...");
    const metadata = await upgrades.deployProxy(Metadata, [accessCAddress], { initializer: '__initialize_metadata' });
    await metadata.deployed();
    console.log("Metadata deployed to:", metadata.address);

    const metaCAddress = metadata.address;

    // Normal metadata contract with proxy
    const Finance = await ethers.getContractFactory("getEventFinancing");
    console.log("3 Deploying financing Proxy...");
    const finance = await upgrades.deployProxy(Finance, [accessCAddress], { initializer: 'initialize_event_financing' });
    await finance.deployed();
    console.log("Finance deployed to:", finance.address);

    const financeCAddress = finance.address

    // Normal metadata contract
    const Base = await ethers.getContractFactory("baseGETNFT_V4");
    console.log("Deploying baseNFT...");
    const base = await upgrades.deployProxy(Base, [accessCAddress, metaCAddress, financeCAddress], { initializer: 'initialize_base' });
    await base.deployed();
    console.log("BaseNFT deployed to:", base.address);

    const baseCAddress = base.address

    // Normal metadata contract
    const Claim = await ethers.getContractFactory("claimGETNFT");
    console.log("Deploying claimGETNFT...");
    const claim = await upgrades.deployProxy(Claim, [accessCAddress, baseCAddress], { initializer: 'initialize_claim_nft' });
    await claim.deployed();
    console.log("claimGETNFT deployed to:", claim.address);

    const claimCAddress = claim.address

    console.log("Accessmanager proxy deployed at:" + accessCAddress)
    console.log("Metadata proxy deployed at:" + metaCAddress)
    console.log("Finance proxy deployed at:" + financeCAddress)
    console.log("getNFT Base proxy deployed at:" + baseCAddress)
    console.log("Claim prox deployed at:" + claimCAddress)

    const MINTER_ROLE = web3.utils.soliditySha3('MINTER_ROLE')
    // const FACTORY_ROLE = web3.utils.soliditySha3('FACTORY_ROLE')

    console.log("Start with initalizing the access control contract with the proxy contract addresses.")

    const acc_testing = "0x6058233f589DBE86f38BC64E1a77Cf16cf3c6c7e"

    // const Access = await ethers.getContractFactory("AccessControlGET")
    // const access = Access.attach(accessCAddress)

    console.log("Granting minting access to:", financeCAddress)
    await access.grantRole(MINTER_ROLE, financeCAddress)
    console.log("Completed 1/4")

    console.log("Granting minting access to:", baseCAddress)
    await access.grantRole(MINTER_ROLE, baseCAddress)
    console.log("Completed 2/4")

    console.log("Granting minting access to:", acc_testing)
    await access.grantRole(MINTER_ROLE, acc_testing)
    console.log("Completed 3/4")

    console.log("Granting minting access to:", claimCAddress)
    await access.grantRole(MINTER_ROLE, claimCAddress)
    console.log("Completed 4/4")

    // console.log("Granting minting access to:", baseCAddress)
    // const result6 = await access.grantRole(FACTORY_ROLE, baseCAddress)
    // console.log("Done")

    console.log("Initalizing the (proxy) address of baseNFT in the finance contract ", financeCAddress)
    var result = await finance.configureBase(baseCAddress);
    console.log("Done")

    // Only needed when in testnet mode (ganache)
    const accounts = await ethers.getSigners();
    console.log("Granting minting access to:", accounts[0].address)
    var result = await access.connect(accounts[0]).grantRole(MINTER_ROLE, accounts[0].address);

    console.log("  ")
    console.log("Accessmanager proxy deployed at: " + accessCAddress)
    console.log("Metadata proxy deployed at: " + metaCAddress)
    console.log("Finance proxy deployed at: " + financeCAddress)
    console.log("Base proxy deployed at: " + baseCAddress)
    console.log("Claim proxy deployed at: " + claimCAddress)


}
    
main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});