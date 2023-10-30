import { expect } from "chai";
import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";
import { helpers } from "./shared/helpers";
import { deployConfig as testCfg } from "../deploy-test.config";

import * as utils from "../scripts/deploy";

describe("ChainBridge test", async () => {
  let demRebelRoot: Contract;
  let saleFacetRoot: Contract;
  let bridgeRoot: Contract;
  let rootTunnel: Contract;

  let demRebelChild: Contract;
  let saleFacetChild: Contract;
  let bridgeChild: Contract;
  let childTunnel: Contract;

  let accounts: Signer[];
  let ownerRoot: Signer;
  let ownerChild: Signer;

  let demRebelAddressRoot: string;
  let demRebelAddressChild: string;

  before(async () => {
    const deployRootOutput = await utils.main(true, true);
    demRebelAddressRoot = deployRootOutput.demRebel;
    const deployChildOutput = await utils.main(false, true);
    demRebelAddressChild = deployChildOutput.demRebel;

    accounts = await ethers.getSigners();

    demRebelRoot = await ethers.getContractAt(
      "DemRebel",
      demRebelAddressRoot,
      accounts[0],
    );
    saleFacetRoot = await ethers.getContractAt(
      "PreSaleFacet",
      demRebelAddressRoot,
      accounts[0],
    );
    bridgeRoot = await ethers.getContractAt(
      "ChainBridge",
      demRebelAddressRoot,
      accounts[0],
    );
    rootTunnel = await ethers.getContractAt(
      "RootTunnel",
      demRebelAddressRoot,
      accounts[0],
    );

    demRebelChild = await ethers.getContractAt(
      "DemRebel",
      demRebelAddressChild,
      accounts[0],
    );
    saleFacetChild = await ethers.getContractAt(
      "PreSaleFacet",
      demRebelAddressChild,
      accounts[0],
    );
    bridgeChild = await ethers.getContractAt(
      "ChainBridge",
      demRebelAddressChild,
      accounts[0],
    );
    childTunnel = await ethers.getContractAt(
      "ChildTunnel",
      demRebelAddressChild,
      accounts[0],
    );

    {
      let tx = await rootTunnel.setFxChildTunnel(childTunnel.target);
      expect((await tx.wait()).status).to.equal(1);
    }
    {
      let tx = await childTunnel.setFxRootTunnel(rootTunnel.target);
      expect((await tx.wait()).status).to.equal(1);
    }
    {
      let tx = await bridgeRoot.setReflection(
        demRebelAddressRoot,
        demRebelAddressChild,
      );
      expect((await tx.wait()).status).to.equal(1);
    }
    {
      let tx = await bridgeChild.setReflection(
        demRebelAddressRoot,
        demRebelAddressChild,
      );
      expect((await tx.wait()).status).to.equal(1);
    }

    let MockFxAddress;
    {
      const factory = await ethers.getContractFactory("MockFxRoot");
      const facetInstance = await factory.deploy();
      await facetInstance.waitForDeployment();
      const receipt = await facetInstance.deploymentTransaction().wait();

      expect(receipt.status).to.be.eq(1, "MockFxRoot deploy error");
      MockFxAddress = receipt.contractAddress;
    }
    {
      let tx = await rootTunnel
        .connect(accounts[0])
        .initializeRoot(
          MockFxAddress,
          "0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA",
        );
      let receipt = await tx.wait();
      expect(receipt.status).to.be.eq(1, "rootTunnel init fail");
    }
    {
      let tx = await childTunnel
        .connect(accounts[0])
        .initializeChild(MockFxAddress);
      let receipt = await tx.wait();
      expect(receipt.status).to.be.eq(1, "childTunnel init fail");
    }
  });

  it("L1 to L2 test", async () => {
    let user1 = accounts[1];
    let address1 = await user1.getAddress();

    let status = await helpers.purchaseRebels(saleFacetRoot, user1, 2);

    {
      const tokenIds = await demRebelRoot
        .connect(user1)
        .tokenIdsOfOwner(address1);
      expect(tokenIds.length).to.be.eq(2, "tokenIds length before transition");
    }
    {
      const tokenIds = await demRebelChild
        .connect(user1)
        .tokenIdsOfOwner(address1);
      expect(tokenIds.length).to.be.eq(0, "tokenIds length before transition");
    }

    {
      const tx = await bridgeRoot.connect(user1).transition([0, 1]);
      expect((await tx.wait()).status).to.equal(1, "transition should be made");
    }

    {
      const tokenIds = await demRebelRoot
        .connect(user1)
        .tokenIdsOfOwner(address1);
      expect(tokenIds.length).to.be.eq(0, "tokenIds length after transition");
    }
    {
      const tokenIds = await demRebelChild
        .connect(user1)
        .tokenIdsOfOwner(address1);
      expect(tokenIds.length).to.be.eq(2, "tokenIds length after transition");
    }
  });

  it("L2 to L1 test", async () => {
    let user1 = accounts[1];
    let address1 = await user1.getAddress();

    {
      const tokenIds = await demRebelRoot
        .connect(user1)
        .tokenIdsOfOwner(address1);
      expect(tokenIds.length).to.be.eq(0, "tokenIds length before transition");
    }
    {
      const tokenIds = await demRebelChild
        .connect(user1)
        .tokenIdsOfOwner(address1);
      expect(tokenIds.length).to.be.eq(2, "tokenIds length before transition");
    }

    {
      const tx = await bridgeChild.connect(user1).transition([0, 1]);
      expect((await tx.wait()).status).to.equal(1, "transition should be made");
    }

    {
      const tokenIds = await demRebelRoot
        .connect(user1)
        .tokenIdsOfOwner(address1);
      expect(tokenIds.length).to.be.eq(2, "tokenIds length after transition");
    }
    {
      const tokenIds = await demRebelChild
        .connect(user1)
        .tokenIdsOfOwner(address1);
      expect(tokenIds.length).to.be.eq(0, "tokenIds length after transition");
    }
  });
});
