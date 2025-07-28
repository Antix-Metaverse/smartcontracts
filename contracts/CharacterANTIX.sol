// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract CharacterANTIX is ERC721, ERC721URIStorage, Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    struct UserInfo {
        address user;
        uint64 expires;
    }

    address public trustedSigner;
    mapping(uint256 => UserInfo) private _users;
    mapping(bytes32 => bool) public usedHashes;

    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint64 expires
    );

    constructor(
        string memory name,
        string memory symbol,
        address signer
    ) ERC721(name, symbol) Ownable(msg.sender) {
        trustedSigner = signer;
    }

    function setTrustedSigner(address signer) external onlyOwner {
        trustedSigner = signer;
    }

    function mint(
        address to,
        uint256 tokenId,
        string calldata uri,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(block.timestamp <= deadline, "Signature expired");
        bytes32 hash = keccak256(abi.encodePacked(to, tokenId, uri, deadline));
        require(!usedHashes[hash], "Signature already used");
        bytes32 ethHash = hash.toEthSignedMessageHash();
        address signerRecovered = ethHash.recover(signature);
        require(signerRecovered == trustedSigner, "Invalid signature");

        usedHashes[hash] = true;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit MetadataUpdate(tokenId);
    }

    function updateTokenURI(
        uint256 tokenId,
        string calldata newUri
    ) external onlyOwner {
        _setTokenURI(tokenId, newUri);
        emit MetadataUpdate(tokenId);
    }

    function setUser(uint256 tokenId, address user, uint64 expires) external {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Not owner nor approved"
        );
        require(expires > block.timestamp, "Expiration must be in future");

        _users[tokenId] = UserInfo(user, expires);
        emit UpdateUser(tokenId, user, expires);
    }

    function userOf(uint256 tokenId) external view returns (address) {
        if (_users[tokenId].expires >= block.timestamp) {
            return _users[tokenId].user;
        }
        return address(0);
    }

    function userExpires(uint256 tokenId) external view returns (uint256) {
        return _users[tokenId].expires;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return
            interfaceId == bytes4(0xad092b5c) || // ERC-4907
            interfaceId == type(IERC4906).interfaceId || // ERC-4906
            super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }
}
