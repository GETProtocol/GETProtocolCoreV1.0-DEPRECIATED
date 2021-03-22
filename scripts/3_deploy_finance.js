const { ethers, upgrades } = require("hardhat");

async function main() {

    const accessCAddress = "0xfBC2BF3DA4D12328db1857C941D631dd7D840340";

    // Normal metadata contract with proxy
    const Finance = await ethers.getContractFactory("getEventFinancing");
    console.log("Deploying financing Proxy...");
    const finance = await upgrades.deployProxy(Finance, [accessCAddress], { initializer: 'initialize_event_financing' });
    await finance.deployed();
    console.log("Finance deployed to:", finance.address);

}
    
main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});