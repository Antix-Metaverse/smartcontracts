import { expect } from "chai";
import { ignition, ethers } from "hardhat";

import { Indx } from "../typechain-types/contracts/AntixToken.sol/Indx";
import DemoModule from "../ignition/modules/Token.module";
import UpgradeModule from "../ignition/modules/TokenUpgrade.module";
import { IndxV2 } from "../typechain-types/contracts/AntixTokenV2.sol/IndxV2";

describe("Demo Proxy", function () {
  describe("Proxy interaction", function () {
    it("Should be interactable via proxy", async function () {
      const [, otherAccount] = await ethers.getSigners();

      const { token } = (await ignition.deploy(DemoModule)) as unknown as {
        token: Indx;
      };

      expect(await token.connect(otherAccount).version()).to.equal("1");
    });
  });

  describe("Upgrading", function () {
    it("Should have upgraded the proxy to DemoV2", async function () {
      const [, otherAccount] = await ethers.getSigners();

      const { token } = (await ignition.deploy(UpgradeModule)) as unknown as {
        token: Indx;
      };

      expect(await token.connect(otherAccount).version()).to.equal("2");
    });

    it("Should have set the name during upgrade", async function () {
      const [, otherAccount] = await ethers.getSigners();

      const { token } = (await ignition.deploy(UpgradeModule)) as unknown as {
        token: IndxV2;
      };

      expect(await token.connect(otherAccount).test()).to.equal(11);

      console.log(`Admin role ${await token.DEFAULT_ADMIN_ROLE()}`);
      await token.initializeV2(otherAccount.address);
    });
  });
});
