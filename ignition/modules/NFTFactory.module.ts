import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const FactoryANTIX = buildModule("FactoryNFTModule", (m) => {
  const factoryContract = m.contract("AssetFactory", [
    m.getParameter("address721"),
    m.getParameter("address1155"),
  ]);
  return { factoryContract };
});

export default FactoryANTIX;
