// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title VaaniLicence
 * @notice Soulbound ERC-721 token representing dataset licences, compliant with ERC-5192.
 */
contract VaaniLicence is ERC721, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // ERC-5192 interface ID
    bytes4 private constant _ERC5192_INTERFACE_ID = 0xb45a3c0e;

    address public vault;
    string private _baseTokenURI;

    error Soulbound();
    error OnlyVault();
    error VaultAlreadySet();
    error ZeroAddress();
    error TokenDoesNotExist();

    /// @notice Emitted when the locking status of a token changes (ERC-5192).
    event Locked(uint256 tokenId);

    constructor(address admin) ERC721("VaaniVault Licence", "VAANI-L") {
        if (admin == address(0)) revert ZeroAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    /**
     * @notice Sets the VaaniVault contract address. Callable only once by admin.
     * @param _vault Address of the VaaniVault contract.
     */
    function setVault(address _vault) external onlyRole(ADMIN_ROLE) {
        if (_vault == address(0)) revert ZeroAddress();
        if (vault != address(0)) revert VaultAlreadySet();
        vault = _vault;
    }

    /**
     * @notice Sets the base URI for token metadata.
     * @param uri New base URI string.
     */
    function setBaseURI(string memory uri) external onlyRole(ADMIN_ROLE) {
        _baseTokenURI = uri;
    }

    /**
     * @notice Mints a new soulbound licence token. Callable only by the vault contract.
     * @param to Recipient address of the licence.
     * @param tokenId Token ID to mint (matching requestId).
     */
    function mint(address to, uint256 tokenId) external {
        if (msg.sender != vault) revert OnlyVault();
        _safeMint(to, tokenId);
        emit Locked(tokenId);
    }

    /**
     * @notice Returns whether a token is locked (soulbound). Always true for existing tokens.
     * @param tokenId Token identifier.
     */
    function locked(uint256 tokenId) external view returns (bool) {
        if (_ownerOf(tokenId) == address(0)) revert TokenDoesNotExist();
        return true;
    }

    /**
     * @dev Soulbound transfer restriction: reverts any transfer where from != 0 and to != 0.
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert Soulbound();
        }
        return super._update(to, tokenId, auth);
    }

    /**
     * @notice Returns metadata URI for a token ID.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) revert TokenDoesNotExist();
        return string.concat(_baseTokenURI, Strings.toString(tokenId));
    }

    /**
     * @notice Interface detection supporting ERC-5192 in addition to ERC721 and AccessControl.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == _ERC5192_INTERFACE_ID || super.supportsInterface(interfaceId);
    }
}
