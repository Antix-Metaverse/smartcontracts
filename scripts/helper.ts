import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { AntixToken } from "../typechain-types/contracts/AntixToken";

interface VRS {
  r: string;
  s: string;
  v: number;
}

export async function getPermitSignature(
  wallet: HardhatEthersSigner,
  token: AntixToken,
  spender: string,
  value = ethers.MaxUint256,
  deadline = ethers.MaxUint256,
  permitConfig?: {
    nonce?: number;
    name?: string;
    chainId?: number;
    version?: string;
  }
): Promise<VRS> {
  const [nonce, name, version, chainId] = await Promise.all([
    permitConfig?.nonce ?? token.nonces(wallet.address),
    permitConfig?.name ?? token.name(),
    permitConfig?.version ?? "1",
    permitConfig?.chainId ?? "1337",
  ]);

  console.log("Permit data:", name, version, chainId, await token.getAddress());

  return splitSignatureToVRS(
    await wallet.signTypedData(
      {
        name,
        version,
        chainId,
        verifyingContract: await token.getAddress(),
      },
      {
        Permit: [
          {
            name: "owner",
            type: "address",
          },
          {
            name: "spender",
            type: "address",
          },
          {
            name: "value",
            type: "uint256",
          },
          {
            name: "nonce",
            type: "uint256",
          },
          {
            name: "deadline",
            type: "uint256",
          },
        ],
      },
      {
        owner: wallet.address,
        spender,
        value,
        nonce,
        deadline,
      }
    )
  );
}

export function splitSignatureToVRS(signature: string): VRS {
  const r = "0x" + signature.substring(2).substring(0, 64);
  const s = "0x" + signature.substring(2).substring(64, 128);
  const v = parseInt(signature.substring(2).substring(128, 130), 16);

  return { r, s, v };
}
