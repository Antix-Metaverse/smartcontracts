import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("SpecialNFT", (m) => {
  const nft = m.contract("SpecialNFTAntix", ["SpecialNFT", "SPC", "uri"]);

  return { nft };
});
