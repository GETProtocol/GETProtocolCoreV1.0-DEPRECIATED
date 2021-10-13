# Deployed contracts 
Contains flattened contracts of deployements of previous upgrades. U stands fo "Upgrade" and the integer for the round. If only 1 contract is upgraded this is still an upgrade round. Take note that for the storage proxy structure only the latest contract is of relevance to access if memory is overwritten. This directory is mainly kept to keep track of what was changed over time and in what sequence.

Whenever a deployment or upgrade is done make carefull 'backups' of the .openzeppelin artifact before and after the upgrade. Make sure not to overwrite old artifacts. It is a huge pain to upgrade contracts without having artifacs and it can even be impossible. To prevent overwriting zip the artifacts (before of before YOUR upgrade as well the artifacts EXACTlY after your upgrade) and add them to the appropriate folder. Make a note in the README.MD file of the upgrade with what was done, any 

## Folder and contract naming structure
The upgrade round is incremented per cycle. The contract name (both Solidity namespace as file) only increment if the contract code is changed and an upgrade is pushed. This means that it is possible that version of contracts between each other do not match. So a baseNFTV3 and an AccessControlV2, this is because the versioning is per contract not all contracts as a whole. I realize this might be slighly confusing but I don't really see alternatives. Not doing this causes even more problems as we will need to completely seperate the contracts and deployments (we have done that before). I can explain in meat space why this is but has to do with compiling of contracts in Truffle/Hardhat. 

### U0_DeployedContracts 
Original contracts deployed. No artifacts.

### U1_DeployedContracts
Upgrade of the baseNFT contract (checkNFT addition).

### U2_DeployedContracts
Upgrade of the AccessControl and ERC721 contract.

### U3_DeployedContracts
Complete refactor of the protocol. Replacing all contracts except getNFT_ERC721V2.sol (of the U2 upgrade).