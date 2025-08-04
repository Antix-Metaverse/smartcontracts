import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const proxyModule = buildModule("ProxyModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);

  const token = m.contract("Indx");

  const proxy = m.contract("TransparentUpgradeableProxy", [
    token,
    proxyAdminOwner,
    "0x",
  ]);

  const proxyAdminAddress = m.readEventArgument(
    proxy,
    "AdminChanged",
    "newAdmin"
  );

  const proxyAdmin = m.contractAt("ProxyAdmin", proxyAdminAddress);

  return { proxyAdmin, proxy };
});

const tokenModule = buildModule("TokenModule", (m) => {
  const { proxy, proxyAdmin } = m.useModule(proxyModule);

  const token = m.contractAt("Indx", proxy);
  m.call(token, "initialize", []);

  return { token, proxy, proxyAdmin };
});

export default tokenModule;
