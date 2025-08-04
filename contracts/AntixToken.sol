// SPDX-License-Identifier: GPL-3.0-or-later
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @title Indx
 * @dev Implementation of a capped, burnable, permit-enabled, and voting-enabled ERC20 token.
 * Inherits from Initializable and several OpenZeppelin upgradeable token contracts.
 */
contract Indx is
    Initializable,
    ERC20Upgradeable,
    ERC20CappedUpgradeable,
    ERC20BurnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
    /**
     * @dev Constructor that disables initializers to prevent the implementation contract from being used.
     * This is required by OpenZeppelin's upgradeable contract pattern.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the token with a name, symbol, cap, and initial supply.
     * Also sets up permit and voting extensions.
     * Mints the initial supply to the deployer's address.
     */
    function initialize() public virtual initializer {
        __ERC20_init("ANTIX", "ANTIX");
        __ERC20Capped_init(1_000_000_000 * 10 ** decimals());
        __ERC20Permit_init("ANTIX");
        __ERC20Votes_init();

        _mint(_msgSender(), 1_000_000_000 * 10 ** decimals());
    }

    /**
     * @dev Returns the version of the token contract.
     * This can be useful for identifying the deployed version of the contract, especially after upgrades.
     * @return The version string of the contract.
     */
    function version() external view virtual returns (string memory) {
        return "1";
    }

    /**
     * @dev Returns the proxy version, admin, and implementation addresses.
     * This function reads from the storage slots defined by the ERC1967 standard.
     * @return initializedVersion The initialized version of the contract.
     * @return admin The address of the admin.
     * @return implementation The address of the implementation contract.
     */
    function proxy()
        external
        view
        returns (
            uint64 initializedVersion,
            address admin,
            address implementation
        )
    {
        // @openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol
        bytes32 ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        bytes32 IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        return (
            _getInitializedVersion(),
            StorageSlot.getAddressSlot(ADMIN_SLOT).value,
            StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value
        );
    }

    /**
     * @dev Returns the current timestamp.
     * Required override for compatibility with ERC20VotesUpgradeable.
     * @return The current timestamp as a uint48.
     */
    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    /**
     * @dev Returns the clock mode as a string.
     * Required override for compatibility with ERC20VotesUpgradeable.
     * @return The clock mode.
     */
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    /**
     * @dev Overrides the _update function to handle updates from multiple inherited contracts.
     * @param from The address tokens are transferred from.
     * @param to The address tokens are transferred to.
     * @param value The amount of tokens transferred.
     */
    function _update(
        address from,
        address to,
        uint256 value
    )
        internal
        override(
            ERC20Upgradeable,
            ERC20CappedUpgradeable,
            ERC20VotesUpgradeable
        )
    {
        super._update(from, to, value);
    }

    /**
     * @dev Returns the current nonce for an owner address.
     * Required override for compatibility with ERC20PermitUpgradeable and NoncesUpgradeable.
     * @param owner The address to query the nonce for.
     * @return The current nonce for the owner address.
     */
    function nonces(
        address owner
    )
        public
        view
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
