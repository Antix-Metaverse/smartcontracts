import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import AntixTokenModule from "./Token.module";

const upgradeModule = buildModule("UpgradeModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);

  const { proxyAdmin, proxy } = m.useModule(AntixTokenModule);

  const tokenV2 = m.contract("IndxV2");

  const encodedFunctionCall = m.encodeFunctionCall(tokenV2, "initializeV2", [
    proxyAdminOwner,
  ]);

  m.call(proxyAdmin, "upgradeAndCall", [proxy, tokenV2, encodedFunctionCall], {
    from: proxyAdminOwner,
  });

  return { proxyAdmin, proxy };
});

const tokenV2Module = buildModule("TokenV2Module", (m) => {
  const { proxy } = m.useModule(upgradeModule);

  const token = m.contractAt("IndxV2", proxy);

  return { token };
});

export default tokenV2Module;
