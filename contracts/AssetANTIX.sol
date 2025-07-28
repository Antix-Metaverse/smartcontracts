// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface ICharacterNFT {
    function userOf(uint256 tokenId) external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract CharacterAssets is Initializable, ERC1155, Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public trustedSigner;
    address public characterNFT;
    uint256 public characterId;
    mapping(bytes32 => bool) public usedHashes;
    mapping(uint256 => string) private _tokenURIs;

    event AssetMinted(
        address indexed to,
        uint256 indexed assetId,
        uint256 amount,
        string uri
    );

    constructor() Ownable(msg.sender) ERC1155("") {}

    function initialize(
        string memory baseURI,
        address signer_,
        address characterNFT_,
        uint256 characterId_
    ) public initializer {
        _setURI(baseURI);
        trustedSigner = signer_;
        characterNFT = characterNFT_;
        characterId = characterId_;
        _transferOwnership(msg.sender);
    }

    function setTrustedSigner(address signer_) external onlyOwner {
        trustedSigner = signer_;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        if (bytes(tokenURI).length > 0) {
            return tokenURI;
        } else {
            return super.uri(tokenId);
        }
    }

    function mintAsset(
        address to,
        uint256 assetId,
        string memory assetURI,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external {
        require(block.timestamp <= deadline, "Signature expired");
        require(
            ICharacterNFT(characterNFT).userOf(characterId) == msg.sender ||
                ICharacterNFT(characterNFT).ownerOf(characterId) == msg.sender,
            "Not an owner or renter"
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                to,
                characterId,
                assetId,
                assetURI,
                amount,
                deadline
            )
        );
        require(!usedHashes[hash], "Signature already used");

        bytes32 ethHash = hash.toEthSignedMessageHash();
        address signerRecovered = ethHash.recover(signature);
        require(signerRecovered == trustedSigner, "Invalid signature");

        usedHashes[hash] = true;

        _mint(to, assetId, amount, "");
        _tokenURIs[assetId] = assetURI;

        emit AssetMinted(to, assetId, amount, assetURI);
    }
    function testHash(
        address to,
        uint256 assetId,
        string memory assetURI,
        uint256 amount,
        uint256 deadline
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    to,
                    characterId,
                    assetId,
                    assetURI,
                    amount,
                    deadline
                )
            );
    }
    function setTokenURI(
        uint256 tokenId,
        string calldata newUri
    ) external onlyOwner {
        _tokenURIs[tokenId] = newUri;
    }
}
