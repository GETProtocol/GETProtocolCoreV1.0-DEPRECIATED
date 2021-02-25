# Deployment scripts getNFT V4 Upgradable
Overview of the scrips, console commands and procedures needed to deploy the contracts. 

Preperations
-> Install all required packages
-> Deploy Ganache
-> Configure hardhat.config.js with the correct deployment addresses.
- Set infura secret/api


## Contracts 

#### AccessControlUpgradeableGETV2
Deploy access manager contract.
npx hardhat run --network ganache scripts/deploy_accessmanager.js 

Deploy

#### baseNFT


### Commands
npx hardhat run --network rinkeby scripts/deploy.js

