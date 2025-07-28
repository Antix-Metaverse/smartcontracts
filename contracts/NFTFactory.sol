// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface ICharacterNFT {
    function transferOwnership(address newOwner) external;
}

interface ICharacterAssets {
    function initialize(
        string memory baseURI,
        address signer,
        address characterNFT,
        uint256 characterId
    ) external;
}

contract AssetFactory is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public immutable character721Implementation;
    address public immutable asset1155Implementation;
    address public trustedSigner;
    mapping(bytes32 => bool) public usedHashes;

    event CharacterCreated(address indexed new721);
    event AssetContractCreated(address indexed new1155);

    constructor(address _character721, address _asset1155) Ownable(msg.sender) {
        character721Implementation = _character721;
        asset1155Implementation = _asset1155;
    }

    function createCharacterNFT() external returns (address proxy721) {
        proxy721 = Clones.clone(character721Implementation);
        emit CharacterCreated(proxy721);
    }

    function createAssetContract(
        string memory baseURI,
        address characterNFT,
        uint256 characterId,
        uint256 deadline,
        bytes calldata signature
    ) external returns (address proxy1155) {
        require(block.timestamp <= deadline, "Signature expired");
        bytes32 hash = keccak256(
            abi.encodePacked(baseURI, characterNFT, characterId, deadline)
        );
        require(!usedHashes[hash], "Signature already used");
        bytes32 ethHash = hash.toEthSignedMessageHash();
        address signerRecovered = ethHash.recover(signature);
        require(signerRecovered == trustedSigner, "Invalid signature");

        usedHashes[hash] = true;

        proxy1155 = Clones.clone(asset1155Implementation);
        ICharacterAssets(proxy1155).initialize(
            baseURI,
            trustedSigner,
            characterNFT,
            characterId
        );
        emit AssetContractCreated(proxy1155);
    }

    function setTrustedSigner(address signer_) external onlyOwner {
        trustedSigner = signer_;
    }
}
