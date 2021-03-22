pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: contracts/GSN/ContextUpgradeable.sol


 

contract IGETAccessControlUpgradeable {

    function hasRole(bytes32, address) public view returns (bool) {}

}

// import "./IERC20.sol";
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IGETBase {
    // function createGETNFT(
    //     address destinationAddress, 
    //     address eventAddress, 
    //     uint256 pricepaid,
    //     uint256 orderTime,
    //     string calldata ticketURI,
    //     bytes[] calldata ticketMetadata,
    //     bool setAsideNFT
    // ) external returns(uint256);
    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) external view returns(bool);
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
        ) external view returns(uint256);
    function balanceOf(
        address owner
        ) external view returns(uint256);
    function relayerTransferFrom(
        address originAddress, 
        address destinationAddress, 
        uint256 nftIndex
        ) external;
}

contract claimGETNFT is Initializable {
    IGETAccessControlUpgradeable public gAC;
    IGETBase public getNFTBase;

    event illegalClaim(
        address indexed originAddress, 
        uint indexed timestamp)
    ;

    event nftClaimed(
        address originAddress, 
        address externalAddress
    );

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    function initialize_claim_nft(
        address _address_gAC,
        address _base_address
        ) public initializer {
        gAC = IGETAccessControlUpgradeable(_address_gAC);
        getNFTBase = IGETBase(_base_address);
        }

    // function configureBase(address baseAddress) public {
    //     require(gAC.hasRole(MINTER_ROLE, msg.sender), "configureBase: WRONG MINTER");
    //     getNFTBase = IGETBase(baseAddress);
    // }

    function claimgetNFT(
        address originAddress, 
        address externalAddress) public {

        require(gAC.hasRole(MINTER_ROLE, msg.sender), "claimgetNFT: WRONG MINTER");

        require(getNFTBase.balanceOf(originAddress) == 0, "claimgetNFT: NO BALANCE");
        // if (getNFTBase.balanceOf(originAddress) == 0) {
        //     emit illegalClaim(originAddress, block.timestamp);
        //     return; // return function as it will fail otherwise (no nft to transfer)
        // }

        uint256 nftIndex = getNFTBase.tokenOfOwnerByIndex(originAddress, 0); // fetch the index of the NFT
        bool _claimable = getNFTBase.isNFTClaimable(nftIndex, originAddress);

        require(_claimable == true, "claimgetNFT - ILLEGAL ClAIM");

        // require(_ticketInfo[nftIndex].valid == false, "claimgetNFT - NFT INVALID");
        // require(_ticketInfo[nftIndex].scanned == true, "claimgetNFT - NFT UNSCANNED");
        // require(ownerOf(nftIndex) == originAddress, "claimgetNFT - WRONG OWNER");

        /// Transfer the NFT to destinationAddress
        getNFTBase.relayerTransferFrom(
            originAddress, 
            externalAddress, 
            nftIndex
        );

        // emit event of successfull 
        emit nftClaimed(originAddress, externalAddress);

        // moveFuelToken(claimNFTfee, FUELTOKEN, GETcollector);
        }


}


