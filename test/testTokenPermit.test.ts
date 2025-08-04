import { expect } from "chai";
import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { AntixToken } from "../typechain-types/contracts/AntixToken";
import { AntixToken__factory } from "../typechain-types/factories/contracts/AntixToken__factory";
import { getPermitSignature } from "../scripts/helper";
import { time } from "@nomicfoundation/hardhat-toolbox/network-helpers";
const parse18 = ethers.parseEther;

describe("Permit", () => {
  let alice: HardhatEthersSigner;
  let owner: HardhatEthersSigner;
  let AntixToken: AntixToken;
  before(async () => {
    [owner, alice] = await ethers.getSigners();
    AntixToken = await ethers.deployContract("AntixTokenERC677", [
      parse18("1000000000"),
    ]);
    console.log("Signers: ", owner.address, alice.address);
    console.log("Token address: ", await AntixToken.getAddress());
    const network = await ethers.provider.getNetwork();
    console.log("Current chainId:", network.chainId);
  });

  it("Should transfer with permit", async function () {
    const spender = alice.address;
    const amount = parse18("10");
    const deadline = (await time.latest()) + 1000;
    const result = await getPermitSignature(
      owner,
      AntixToken,
      spender,
      amount,
      BigInt(deadline)
    );
    await AntixToken.permit(
      owner.address,
      spender,
      amount,
      deadline,
      result.v,
      result.r,
      result.s
    );
    const oldBalance = await AntixToken.balanceOf(alice.address);
    await AntixToken.connect(alice).transferFrom(
      owner.address,
      alice.address,
      amount
    );
    const newBalance = await AntixToken.balanceOf(alice.address);
    expect(newBalance).to.be.above(oldBalance);
  });
});
