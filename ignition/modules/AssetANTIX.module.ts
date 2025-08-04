import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const AssetANTIX = buildModule("AssetANTIXModule", (m) => {
  const assetContract = m.contract("CharacterAssets", []);
  return { assetContract };
});

export default AssetANTIX;
