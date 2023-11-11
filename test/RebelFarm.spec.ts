import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";
import { helpers } from "./shared/helpers";
import { deployConfig as testCfg } from "../deploy-test.config";

import * as utils from "../scripts/deploy";

describe("RebelFarm test", async () => {
  let demBacon: Contract;
  let rebelFarm: Contract;
  let growerNft: Contract;
  let toddlerNft: Contract;
  let safeFacet: Contract;

  let accounts: Signer[];
  let owner: Signer;

  let demBaconAddress: string;
  let demRebelAddress: string;
  let gameAddress: string;
  let growerAddress: string;
  let toddlerAddress: string;

  let rootDemRebelAddress: string;

  before(async () => {
    const deployOutput = await utils.main(false, true);
    demBaconAddress = deployOutput.demBacon;
    demRebelAddress = deployOutput.demRebel;
    gameAddress = deployOutput.game;
    growerAddress = deployOutput.growerDemNft;
    toddlerAddress = deployOutput.toddlerDemNft;

    rootDemRebelAddress = await helpers.deployL1(demRebelAddress);

    accounts = await ethers.getSigners();
    owner = accounts[0];

    demBacon = await ethers.getContractAt(
      "DbnToken",
      demBaconAddress,
      accounts[0],
    );
    rebelFarm = await ethers.getContractAt(
      "RebelFarm",
      gameAddress,
      accounts[0],
    );
    growerNft = await ethers.getContractAt(
      "DemNft",
      growerAddress,
      accounts[0],
    );
    toddlerNft = await ethers.getContractAt(
      "DemNft",
      toddlerAddress,
      accounts[0],
    );
  });

  it("Farm params calc test", async () => {
    const tierValue = 5;

    let value = await rebelFarm.tierUpgradeCost(tierValue);
    let wei = ethers.parseEther("8600");
    expect(value).to.be.equal(wei);

    value = await rebelFarm.tierUpgradeCooldown(tierValue);
    expect(value).to.be.equal(118800);

    value = await rebelFarm.tierMaxGrowSpots(tierValue);
    expect(value).to.be.equal(7);

    value = await rebelFarm.tierGrowerFarmRate(tierValue);
    wei = ethers.parseEther("24");
    expect(value).to.be.equal(wei);

    value = await rebelFarm.tierHarvestCap(tierValue);
    wei = ethers.parseEther("1650");
    expect(value).to.be.equal(wei);

    //         value = await farmRaidFacet.tierBonusToAttack(tierValue);
    //         expect(value).to.be.equal(6);
    //
    //         value = await farmRaidFacet.tierBonusToDefense(tierValue);
    //         expect(value).to.be.equal(5);
    //
    //         value = await farmRaidFacet.tierBonusToLoot(tierValue);
    //         expect(value).to.be.equal(6);
    //
    //         value = await farmRaidFacet.tierBonusToProtection(tierValue);
    //         expect(value).to.be.equal(5);

    //         res1, res2 = await rebelFarm.getTokenDbnSwapPair(0);
    //         console.log(res1, res2);

    //         let res1;
    //         let res2;
    //         res1, res2 = await rebelFarm.getTokenDbnSwapPair(0);
    //         console.log(res1);
    //         console.log(res2);
  });

  it("Farm start test", async () => {
    const user = accounts[1];
    const userAddress = await user.getAddress();
    const tokenId = 1;

    await helpers.bridgeL1toL2(rootDemRebelAddress, demRebelAddress, user, 2);

    {
      //Check for invalid starts
      const tx = rebelFarm.connect(user).activateFarm(tokenId, [0], [0]);
      await helpers.expectTxError(
        tx,
        "LibRebelFarm: sender is not grower owner",
      );
    }

    await helpers.buyGrowers(owner, user, 2, demBacon, growerNft);

    {
      const tx = rebelFarm.connect(user).activateFarm(tokenId, [0], [0]);
      await helpers.expectTxError(
        tx,
        "LibRebelFarm: sender is not toddler owner",
      );
    }

    await helpers.buyToddlers(owner, user, 2, demBacon, toddlerNft);

    {
      const tx = rebelFarm.connect(user).activateFarm(tokenId, [0], [0, 1, 2]);
      await helpers.expectTxError(
        tx,
        "LibRebelFarm: sender is not toddler owner",
      );
    }

    {
      //Successful farm start
      const value = await rebelFarm.connect(user).isFarmActivated(tokenId);
      expect(value).to.be.equal(false);
    }
    {
      const tx = await rebelFarm.connect(user).activateFarm(tokenId, [0, 1], [0]);
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should Activate Farm");
    }
    {
      const tx = rebelFarm.connect(accounts[0]).activateFarm(tokenId, [0], [0]);
      await helpers.expectTxError(tx, "LibAppStorage: Only DemRebel owner");
    }
    {
      const tx = rebelFarm.connect(user).activateFarm(tokenId, [0], [0]);
      await helpers.expectTxError(tx, "RebelFarm: Farm is already activated");
    }
    {
      const value = await rebelFarm.connect(user).isFarmActivated(tokenId);
      expect(value).to.be.equal(true);
    }
    {
      const value = await rebelFarm.connect(user).growerCount(tokenId);
      expect(value).to.be.equal(2);
    }
    {
      const value = await rebelFarm.connect(user).toddlerCount(tokenId);
      expect(value).to.be.equal(1);
    }
  });

  it("Modify grower/toddler count, tier checks", async () => {
    const user = accounts[2];
    const userAddress = await user.getAddress();
    const tokenId = 2;

    await helpers.bridgeL1toL2(rootDemRebelAddress, demRebelAddress, user, 1);

    {
      const tx = await rebelFarm.connect(user).activateFarm(tokenId, [], []);
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should Activate Farm");
    }
    {
      //Farm without growers/toddlers
      const value = await rebelFarm.connect(user).getFarmTier(tokenId);
      expect(value).to.be.equal(1);
    }
    {
      const value = await rebelFarm.connect(user).isFarmActivated(tokenId);
      expect(value).to.be.equal(true);
    }
    {
      const value = await rebelFarm.connect(user).growerCount(tokenId);
      expect(value).to.be.equal(0);
    }
    {
      const value = await rebelFarm.connect(user).toddlerCount(tokenId);
      expect(value).to.be.equal(0);
    }

    await helpers.buyGrowers(owner, user, 4, demBacon, growerNft);
    await helpers.buyToddlers(owner, user, 5, demBacon, toddlerNft);

    {
      //Add growers/toddlers to farm
      const tx = await rebelFarm.connect(user).addGrowers(tokenId, [2, 3, 4]);
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should add growers");
    }
    {
      const tx = await rebelFarm.connect(user).addToddlers(tokenId, [2, 3]);
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should add toddlers");
    }
    {
      const tx = rebelFarm.connect(user).addGrowers(tokenId, [5]);
      await helpers.expectTxError(tx, "LibRebelFarm: Insufficient farm tier");
    }
    await helpers.increaseFarmTier(
      accounts[0],
      user,
      tokenId,
      2,
      safeFacet,
      rebelFarm,
    );
    {
      //Check CD Fail Increase tier
      const tx = rebelFarm.connect(user).increaseTier(tokenId);
      await helpers.expectTxError(tx, "RebelFarm: Upgrade cooldown");
    }
    {
      const tx = rebelFarm.connect(user).addGrowers(tokenId, [6]);
      await helpers.expectTxError(
        tx,
        "LibRebelFarm: sender is not grower owner",
      );
    }
    {
      const tx = await rebelFarm.connect(user).addGrowers(tokenId, [5]);
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should add growers");
    }

    {
      //Remove growers/toddlers from farm
      const tx = rebelFarm.connect(user).removeToddlers(tokenId, [0, 2, 3, 4]);
      await helpers.expectTxError(
        tx,
        "LibRebelFarm: Not enough toddlers in farm",
      );
    }
    {
      const tx = await rebelFarm.connect(user).removeGrowers(tokenId, [2]);
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should remove growers");
    }
    {
      const tx = await rebelFarm.connect(user).removeToddlers(tokenId, [2, 3]);
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should remove growers");
    }

    {
      //Final check count
      const value = await rebelFarm.connect(user).growerCount(tokenId);
      expect(value).to.be.equal(3);
    }
    {
      const value = await rebelFarm.connect(user).toddlerCount(tokenId);
      expect(value).to.be.equal(0);
    }
  });

  it("Farm rate and harvest", async () => {
    const user = accounts[3];
    const userAddress = await user.getAddress();
    const tokenId = 3;
    const growCount = 4;
    const todlCount = 2;

    await helpers.bridgeL1toL2(rootDemRebelAddress, demRebelAddress, user, 1);
    await helpers.buyGrowers(accounts[0], user, growCount, demBacon, growerNft);
    await helpers.buyToddlers(
      accounts[0],
      user,
      todlCount,
      demBacon,
      toddlerNft,
    );

    {
      const tx = await rebelFarm.connect(user).activateFarm(tokenId, [], []);
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should Activate Farm");
    }
    await helpers.increaseFarmTier(
      accounts[0],
      user,
      tokenId,
      2,
      safeFacet,
      rebelFarm,
    );
    {
      //Add growers/toddlers to farm
      const growerIds = await growerNft
        .connect(user)
        .tokenIdsOfOwner(userAddress);
      const tx = await rebelFarm
        .connect(user)
        .addGrowers(tokenId, growerIds.toArray());
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should add growers");
    }
    {
      const toddlerIds = await toddlerNft
        .connect(user)
        .tokenIdsOfOwner(userAddress);
      const tx = await rebelFarm
        .connect(user)
        .addToddlers(tokenId, toddlerIds.toArray());
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1, "Should add toddlers");
    }

    await time.increase(60 * 60);

    //checks
    {
      const amountWei = await rebelFarm.connect(user).harvestAmount(tokenId);
      //console.log(amountWei);
      const amountStr = ethers.formatEther(amountWei);
      const amount = parseInt(amountStr, 10);
      expect(amount).to.be.equal(84);
    }
    {
      const tx = await rebelFarm.connect(user).harvestFarm(tokenId);
      const receipt = await tx.wait();
      expect(receipt.status).to.be.equal(1);
    }
    //           {
    //               let safeContent = await safeFacet.connect(user).getSafeContent(tokenId);
    //               //console.log(safeContent);
    //               let amountStr = ethers.utils.formatEther(safeContent);
    //               let amount = parseInt(amountStr, 10);
    //               expect(amount).to.be.equal(84);
    //           }
    {
      const amountWei = await rebelFarm.connect(user).harvestAmount(tokenId);
      const amountStr = ethers.formatEther(amountWei);
      const amount = parseInt(amountStr, 10);
      expect(amount).to.be.equal(0);
    }
  });

  //       it('Farm swap to Dbn test', async () => {
  //           let user = accounts[0];
  //           let userAddress = await user.getAddress();
  //           let farmId = 3;
  //
  //           let tokensMass = new BigNumber.from(0);
  //           for (let tokenId = 1; tokenId <= 3; tokenId++) {
  //               let amountWei = await rebelFarm.connect(user).harvestAmount(tokenId);
  //               let safeContent = await safeFacet.connect(user).getSafeContent(tokenId);
  //
  //               tokensMass = tokensMass.add(amountWei);
  //               tokensMass = tokensMass.add(safeContent);
  //               console.log(amountWei);
  //               console.log(safeContent);
  //           }
  //           console.log(tokensMass);
  //
  //           //Test init values
  //           await rebelFarm.startNewCashOutEpoch(tokensMass, ethers.utils.parseEther("5"));
  //           {
  //               let value;
  //               value = await rebelFarm.getInitEpochPool();
  //               console.log(value);
  //               expect(value).to.be.equal(ethers.utils.parseEther("995000"));
  //           }
  //           {
  //               let value;
  //               value = await rebelFarm.getPoolShareFactor();
  //               expect(value).to.be.equal(ethers.utils.parseEther("1.5"));
  //           }
  //
  //           //Test Swap Pair
  //           {
  //               let value = await rebelFarm.getTokenDbnSwapPair(farmId);
  //               expect(value.dbnAmount).to.be.equal(ethers.utils.parseEther("16.8"));
  //               expect(value.tokenToSpend).to.be.equal(ethers.utils.parseEther("84"));
  //           }
  //
  //
  //           //Cash out
  //           //Test Before
  //           let tokensAmount = ethers.utils.parseEther("84");
  //           let dbnAmount = ethers.utils.parseEther("16.8");
  //           {
  //               let safeContent = await safeFacet.connect(user).getSafeContent(farmId);
  //               expect(safeContent).to.be.equal(tokensAmount);
  //           }
  //           {
  //               let dbnBalance = await dbnFacet.balanceOf(userAddress);
  //               expect(dbnBalance).to.be.equal(0);
  //           }
  //           //Test cash out
  //           { //Mint demBacon
  //               let ownerAccount = accounts[0];
  //               let tx = await dbnFacet.connect(ownerAccount)
  //                   .mint(safeFacet.address, dbnAmount);
  //               let receipt = await tx.wait();
  //               expect(receipt.status).to.be.equal(1, "Should mint demBacon");
  //           }
  //           {
  //               let farmOwner = accounts[3];
  //               await rebelFarm.connect(farmOwner).cashOut(farmId);
  //           }
  //           //Test After
  //           {
  //               let safeContent = await safeFacet.connect(user).getSafeContent(farmId);
  //               expect(safeContent).to.be.equal(0);
  //           }
  //           {
  //               let farmOwnerAddress = accounts[3].getAddress();
  //               let dbnBalance = await dbnFacet.balanceOf(farmOwnerAddress);
  //               expect(dbnBalance).to.be.equal(dbnAmount);
  //           }
  //       })
  //
  //     it('Dbn to Farm tokens swap test', async () => {
  //         let tokensAmount = ethers.utils.parseEther("84");
  //         let dbnAmount = ethers.utils.parseEther("16.8");
  //         let user = accounts[3];
  //         let userAddress = await user.getAddress();
  //         let farmId = 3;
  //
  //         {
  //             let value = await rebelFarm.getFarmTokensAmountFromDbn(dbnAmount);
  //             expect(value).to.be.equal(tokensAmount);
  //         }
  //
  //         //Test Before
  //         {
  //             let safeContent = await safeFacet.connect(user).getSafeContent(farmId);
  //             expect(safeContent).to.be.equal(0);
  //         }
  //         {
  //             let dbnBalance = await dbnFacet.balanceOf(userAddress);
  //             expect(dbnBalance).to.be.equal(dbnAmount);
  //         }
  //         //Test Buy
  //         { //Approve demBacon
  //             let tx = await dbnFacet.connect(user)
  //                 .approve(rebelFarm.address, dbnAmount);
  //             let receipt = await tx.wait();
  //             expect(receipt.status).to.be.equal(1, "Should approve demBacon");
  //         }
  //         {
  //             await rebelFarm.connect(user).buyFarmTokens(farmId, dbnAmount);
  //         }
  //         //Test After
  //         {
  //             let safeContent = await safeFacet.connect(user).getSafeContent(farmId);
  //             expect(safeContent).to.be.equal(tokensAmount);
  //         }
  //         {
  //             let dbnBalance = await dbnFacet.balanceOf(userAddress);
  //             expect(dbnBalance).to.be.equal(0);
  //         }
  // })
});
