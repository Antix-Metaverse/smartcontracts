import { expect } from "chai";
import { ethers, ignition } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import AssetANTIX from "../ignition/modules/AssetANTIX.module";
import { CharacterAssets } from "../typechain-types/contracts/AssetANTIX.sol/CharacterAssets";
import { CharacterANTIX } from "../typechain-types/contracts/CharacterANTIX";
import Character721ANTIX from "../ignition/modules/CharacterANTIX.module";
import { AssetFactory } from "../typechain-types/contracts/NFTFactory.sol/AssetFactory";
import FactoryANTIX from "../ignition/modules/NFTFactory.module";

describe("Antix NFT", function () {
  let owner: HardhatEthersSigner;
  let addr1: HardhatEthersSigner;
  let addr2: HardhatEthersSigner;
  let signer: HardhatEthersSigner;
  let NFT1155Implementation: CharacterAssets;
  let Character721NFT: CharacterANTIX;
  let NFTFactory: AssetFactory;
  beforeEach(async function () {
    [owner, addr1, addr2, signer] = await ethers.getSigners();
    //nft1155 implementation deployment
    const { assetContract } = await ignition.deploy(AssetANTIX, {});
    NFT1155Implementation = assetContract as unknown as CharacterAssets;

    //nft721 deployment
    const { characterContract } = await ignition.deploy(Character721ANTIX, {
      parameters: {
        CharacterANTIXModule: {
          name: "mock",
          symbol: "MCK",
          signer: signer.address,
        },
      },
    });
    Character721NFT = characterContract as unknown as CharacterANTIX;

    //NFT factory deployment
    const { factoryContract } = await ignition.deploy(FactoryANTIX, {
      parameters: {
        FactoryNFTModule: {
          address721: await characterContract.getAddress(),
          address1155: await assetContract.getAddress(),
        },
      },
    });
    NFTFactory = factoryContract as unknown as AssetFactory;
  });
  it("Should deploy asset ERC1155 implementation", async function () {
    expect(await NFT1155Implementation.owner()).to.be.equal(owner.address);
  });

  it("Should deploy character ERC721", async function () {
    expect(await Character721NFT.name()).to.be.equal("mock");
  });

  it("Should deploy NFT factory", async function () {
    expect(await NFTFactory.character721Implementation()).to.be.equal(
      await Character721NFT.getAddress()
    );
    expect(await NFTFactory.asset1155Implementation()).to.be.equal(
      await NFT1155Implementation.getAddress()
    );
  });

  it("Should mint character NFT with valid signature from trusted signer", async function () {
    const to = addr1.address;
    const tokenId = 1;
    const uri = "ipfs://example-uri";
    const deadline = Math.floor(Date.now() / 1000) + 60; // 1 минута вперёд

    const encoded = ethers.solidityPackedKeccak256(
      ["address", "uint256", "string", "uint256"],
      [to, tokenId, uri, deadline]
    );
    const signature = await signer.signMessage(ethers.getBytes(encoded));

    await expect(
      Character721NFT.connect(addr1).mint(to, tokenId, uri, deadline, signature)
    )
      .to.emit(Character721NFT, "MetadataUpdate")
      .withArgs(tokenId);

    expect(await Character721NFT.ownerOf(tokenId)).to.equal(to);
    expect(await Character721NFT.tokenURI(tokenId)).to.equal(uri);
  });

  it("Should deploy 721, mint NFT, then deploy 1155 asset via factory with signature", async function () {
    const to = addr1.address;
    const tokenId = 42;
    const uri = "ipfs://example-uri";
    const deadline = Math.floor(Date.now() / 1000) + 300;

    const packedHash721 = ethers.solidityPackedKeccak256(
      ["address", "uint256", "string", "uint256"],
      [to, tokenId, uri, deadline]
    );
    const signature721 = await signer.signMessage(
      ethers.getBytes(packedHash721)
    );

    await Character721NFT.connect(addr1).mint(
      to,
      tokenId,
      uri,
      deadline,
      signature721
    );
    expect(await Character721NFT.ownerOf(tokenId)).to.equal(to);

    const baseURI = "ipfs://assets/";
    const characterNFT = await Character721NFT.getAddress();
    const characterId = tokenId;

    const packedHash1155 = ethers.solidityPackedKeccak256(
      ["string", "address", "uint256", "uint256"],
      [baseURI, characterNFT, characterId, deadline]
    );
    const signature1155 = await signer.signMessage(
      ethers.getBytes(packedHash1155)
    );
    await NFTFactory.setTrustedSigner(signer.address);
    expect(await NFTFactory.trustedSigner()).to.be.equal(signer.address);
    const tx = await NFTFactory.createAssetContract(
      baseURI,
      characterNFT,
      characterId,
      deadline,
      signature1155
    );
    const receipt = await tx.wait();
    const events = receipt!.logs.filter(
      (event: any) => event.fragment?.name === "AssetContractCreated"
    );
    const assetContractAddress = events[0]!.args[0];
    expect(assetContractAddress).to.properAddress;
  });

  it("Should mint two character NFTs with different URIs", async function () {
    const deadline = Math.floor(Date.now() / 1000) + 300;

    const tokenId1 = 100;
    const uri1 = "ipfs://character-100";
    const hash1 = ethers.solidityPackedKeccak256(
      ["address", "uint256", "string", "uint256"],
      [addr1.address, tokenId1, uri1, deadline]
    );
    const sig1 = await signer.signMessage(ethers.getBytes(hash1));
    await Character721NFT.connect(addr1).mint(
      addr1.address,
      tokenId1,
      uri1,
      deadline,
      sig1
    );

    const tokenId2 = 101;
    const uri2 = "ipfs://character-101";
    const hash2 = ethers.solidityPackedKeccak256(
      ["address", "uint256", "string", "uint256"],
      [addr2.address, tokenId2, uri2, deadline]
    );
    const sig2 = await signer.signMessage(ethers.getBytes(hash2));
    await Character721NFT.connect(addr2).mint(
      addr2.address,
      tokenId2,
      uri2,
      deadline,
      sig2
    );

    expect(await Character721NFT.tokenURI(tokenId1)).to.equal(uri1);
    expect(await Character721NFT.tokenURI(tokenId2)).to.equal(uri2);
    expect(uri1).to.not.equal(uri2);
  });

  it("Should allow transferred owner of character NFT to deploy asset", async function () {
    const tokenId = 77;
    const uri = "ipfs://char-77";
    const deadline = Math.floor(Date.now() / 1000) + 300;

    const hash = ethers.solidityPackedKeccak256(
      ["address", "uint256", "string", "uint256"],
      [addr1.address, tokenId, uri, deadline]
    );
    const sig = await signer.signMessage(ethers.getBytes(hash));
    await Character721NFT.connect(addr1).mint(
      addr1.address,
      tokenId,
      uri,
      deadline,
      sig
    );

    await Character721NFT.connect(addr1).transferFrom(
      addr1.address,
      addr2.address,
      tokenId
    );
    expect(await Character721NFT.ownerOf(tokenId)).to.equal(addr2.address);

    const baseURI = "ipfs://after-transfer/";
    const packedHash = ethers.solidityPackedKeccak256(
      ["string", "address", "uint256", "uint256"],
      [baseURI, await Character721NFT.getAddress(), tokenId, deadline]
    );
    const signature = await signer.signMessage(ethers.getBytes(packedHash));
    await NFTFactory.setTrustedSigner(signer.address);

    const tx = await NFTFactory.connect(addr2).createAssetContract(
      baseURI,
      await Character721NFT.getAddress(),
      tokenId,
      deadline,
      signature
    );
    const receipt = await tx.wait();
    const event = receipt!.logs.find(
      (log: any) => log.fragment?.name === "AssetContractCreated"
    );
    expect((event as any).args[0]).to.properAddress;
  });

  it("Should mint 3 different assets for one character and verify unique URIs", async function () {
    const tokenId = 123;
    const uri721 = "ipfs://char-123";
    const deadline = Math.floor(Date.now() / 1000) + 300;

    // 1. Mint ERC-721 Character
    const hash721 = ethers.solidityPackedKeccak256(
      ["address", "uint256", "string", "uint256"],
      [addr1.address, tokenId, uri721, deadline]
    );
    const sig721 = await signer.signMessage(ethers.getBytes(hash721));
    await Character721NFT.connect(addr1).mint(
      addr1.address,
      tokenId,
      uri721,
      deadline,
      sig721
    );

    // 2. Deploy ERC-1155 Asset Contract
    const baseURI = "ipfs://assets-123/";
    const characterAddr = await Character721NFT.getAddress();

    const hash1155Factory = ethers.solidityPackedKeccak256(
      ["string", "address", "uint256", "uint256"],
      [baseURI, characterAddr, tokenId, deadline]
    );
    const sigFactory = await signer.signMessage(
      ethers.getBytes(hash1155Factory)
    );

    await NFTFactory.setTrustedSigner(signer.address);
    const tx = await NFTFactory.connect(addr1).createAssetContract(
      baseURI,
      characterAddr,
      tokenId,
      deadline,
      sigFactory
    );
    const receipt = await tx.wait();
    const event = receipt!.logs.find(
      (log: any) => log.fragment?.name === "AssetContractCreated"
    );
    const assetAddress = (event as any).args[0];

    const assetContract = await ethers.getContractAt(
      "CharacterAssets",
      assetAddress
    );

    // 3. Mint 3 assets
    const uris = [
      "ipfs://assets-123/item1",
      "ipfs://assets-123/item2",
      "ipfs://assets-123/item3",
    ];
    const assetIds = [1, 2, 3];
    const amount = 1;

    for (let i = 0; i < 3; i++) {
      const hashMint = ethers.solidityPackedKeccak256(
        ["address", "uint256", "uint256", "string", "uint256", "uint256"],
        [addr1.address, tokenId, assetIds[i], uris[i], amount, deadline]
      );
      const sigMint = await signer.signMessage(ethers.getBytes(hashMint));

      expect(await assetContract.trustedSigner()).to.be.equal(signer.address);

      await assetContract
        .connect(addr1)
        .mintAsset(
          addr1.address,
          assetIds[i],
          uris[i],
          amount,
          deadline,
          sigMint
        );
    }

    // 4. Assert all URIs are unique and correct
    const fetchedUris = await Promise.all([
      assetContract.uri(assetIds[0]),
      assetContract.uri(assetIds[1]),
      assetContract.uri(assetIds[2]),
    ]);

    expect(fetchedUris[0]).to.equal(uris[0]);
    expect(fetchedUris[1]).to.equal(uris[1]);
    expect(fetchedUris[2]).to.equal(uris[2]);
    expect(fetchedUris[0]).to.not.equal(fetchedUris[1]);
    expect(fetchedUris[1]).to.not.equal(fetchedUris[2]);
    expect(fetchedUris[0]).to.not.equal(fetchedUris[2]);
  });

  it("Should correctly set and expire character NFT rental", async function () {
    const tokenId = 55;
    const uri = "ipfs://char-rent";
    const deadline = Math.floor(Date.now() / 1000) + 300;

    const hash = ethers.solidityPackedKeccak256(
      ["address", "uint256", "string", "uint256"],
      [addr1.address, tokenId, uri, deadline]
    );
    const sig = await signer.signMessage(ethers.getBytes(hash));
    await Character721NFT.connect(addr1).mint(
      addr1.address,
      tokenId,
      uri,
      deadline,
      sig
    );

    const now = Math.floor(Date.now() / 1000);
    const expires = now + 1000;

    await Character721NFT.connect(addr1).setUser(
      tokenId,
      addr2.address,
      expires
    );
    expect(await Character721NFT.userOf(tokenId)).to.equal(addr2.address);

    await ethers.provider.send("evm_increaseTime", [15000]);
    await ethers.provider.send("evm_mine", []);

    expect(await Character721NFT.userOf(tokenId)).to.equal(ethers.ZeroAddress);
  });
});
