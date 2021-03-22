const { ethers, upgrades } = require("hardhat");

async function main() {

    // Deploying access control 
    console.log("1 Deploying AccessControlGET...");
    const AccessControlGET = await ethers.getContractFactory("AccessControlGET");

    const _access = await upgrades.deployProxy(AccessControlGET, { initializer: '__AccessControlGET_init' });
    await _access.deployed();
    console.log("Access Control upgradeable deployed to:", _access.address);

}
    
main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});