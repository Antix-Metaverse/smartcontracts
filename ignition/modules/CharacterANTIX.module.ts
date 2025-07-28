import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const Character721ANTIX = buildModule("CharacterANTIXModule", (m) => {
  const characterContract = m.contract("CharacterANTIX", [
    m.getParameter("name"),
    m.getParameter("symbol"),
    m.getParameter("signer"),
  ]);
  return { characterContract };
});

export default Character721ANTIX;
