const { ethers, upgrades } = require("hardhat");

async function main() {

    const accessCAddress = "0xfBC2BF3DA4D12328db1857C941D631dd7D840340";

    // Normal metadata contract with proxy
    const metadataLogic = await ethers.getContractFactory("eventMetadataStorage");
    console.log("Deploying metadataLogic Proxy...");
    const _metadata = await upgrades.deployProxy(metadataLogic, [accessCAddress], { initializer: '__initialize_metadata' });
    await _metadata.deployed();
    console.log("Metadata deployed to:", _metadata.address);

}
    
main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});