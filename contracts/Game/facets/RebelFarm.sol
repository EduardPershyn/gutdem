// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibRebelFarm} from "../libraries/LibRebelFarm.sol";
import {LibFarmRaid} from "../libraries/LibFarmRaid.sol";
import {LibFarmCalc} from "../libraries/LibFarmCalc.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

contract RebelFarm is Modifiers {
    function activateFarm(uint256 id_) external {
        require(
            LibRebelFarm.isFarmActivated(id_) == false,
            "RebelFarm: Farm is already activated"
        );

        s.farmTier[id_] = 1;
    }

    function isFarmActivated(uint256 id_) external view returns (bool) {
        return LibRebelFarm.isFarmActivated(id_);
    }

    function startFarm(
        uint256 id_,
        uint256 growerQty_,
        uint256 toddlerQty_
    ) external onlyDemRebelOwner(id_) {
        require(
            LibRebelFarm.isFarmActivated(id_) == true,
            "RebelFarm: Farm is not activated"
        );

        LibRebelFarm.pullRebel(id_);
        LibRebelFarm.pullGrowers(id_, growerQty_);
        LibRebelFarm.pullToddlers(id_, toddlerQty_);

        LibRebelFarm.updateHarvestTimestamp(id_);

        LibRebelFarm.addToTierIndex(id_, s.farmTier[id_]);
    }

    function stopFarm(uint256 id_) external onlyFarmOwner(id_) {
        require(
            LibFarmRaid.isRaidOngoing(id_) == false,
            "RebelFarm: Farm raid is ongoing"
        );

        LibRebelFarm.harvest(id_);

        LibRebelFarm.releaseToddlers(id_, LibRebelFarm.farmToddlerQty(id_));
        LibRebelFarm.releaseGrowers(id_, LibRebelFarm.farmGrowerQty(id_));
        LibRebelFarm.releaseRebel(id_);

        LibRebelFarm.removeFromTierIndex(id_, s.farmTier[id_]);
    }

    function isFarmStarted(uint256 id_) external view returns (bool) {
        return LibRebelFarm.isFarmStarted(id_);
    }

    function harvestAmount(uint256 id_) external view returns (uint256) {
        return LibRebelFarm.harvestAmount(id_);
    }

    function harvestFarm(uint256 id_) external onlyFarmOwner(id_) {
        LibRebelFarm.harvest(id_);
    }

    function getRebelFarmPeriod() external view returns (uint256) {
        return s.farmPeriod;
    }

    function setRebelFarmPeriod(uint256 period_) external onlyOwner {
        require(period_ > 0, "RebelFarm: Period should be greater than 0");
        s.farmPeriod = period_;
    }

    function getFarmRate(uint256 id_) external view returns (uint256) {
        return LibRebelFarm.getFarmRate(id_);
    }

    function farmUpgradeCooldown(uint256 id_) external view returns (uint256) {
        return LibRebelFarm.farmUpgradeCooldown(id_);
    }

    function increaseTier(uint256 id_) external {
        require(
            LibRebelFarm.isFarmActivated(id_) == true,
            "RebelFarm: Farm is not activated"
        );
        require(s.farmTier[id_] < s.farmMaxTier, "RebelFarm: Exceeds max tier");
        require(
            LibRebelFarm.farmUpgradeCooldown(id_) == 0,
            "RebelFarm: Upgrade cooldown"
        );
        require(
            (s.rebelInFarmOwner[id_] == msg.sender) ||
                (IERC721(s.demRebelAddress).ownerOf(id_) == msg.sender),
            "RebelFarm: Only rebel/farm owner"
        );

        LibRebelFarm.payFromSafe(
            id_,
            LibFarmCalc.upgradeCost(s.farmTier[id_] + 1)
        );

        if (LibRebelFarm.isFarmStarted(id_)) {
            LibRebelFarm.updateHarvestStock(id_);
            LibRebelFarm.removeFromTierIndex(id_, s.farmTier[id_]);
            LibRebelFarm.addToTierIndex(id_, s.farmTier[id_] + 1);
        }

        s.farmTier[id_] += 1;
        s.farmUpgradeTime[id_] = block.timestamp;
    }

    function addGrowers(
        uint256 id_,
        uint256 count_
    ) external onlyFarmOwner(id_) {
        LibRebelFarm.updateHarvestStock(id_);
        LibRebelFarm.pullGrowers(id_, count_);
    }

    function removeGrowers(
        uint256 id_,
        uint256 count_
    ) external onlyFarmOwner(id_) {
        LibRebelFarm.updateHarvestStock(id_);
        LibRebelFarm.releaseGrowers(id_, count_);
    }

    function addToddlers(
        uint256 id_,
        uint256 count_
    ) external onlyFarmOwner(id_) {
        LibRebelFarm.updateHarvestStock(id_);
        LibRebelFarm.pullToddlers(id_, count_);
    }

    function removeToddlers(
        uint256 id_,
        uint256 count_
    ) external onlyFarmOwner(id_) {
        require(
            LibFarmRaid.isRaidOngoing(id_) == false,
            "RebelFarm: Farm raid is ongoing"
        );

        LibRebelFarm.updateHarvestStock(id_);
        LibRebelFarm.releaseToddlers(id_, count_);
    }

    function getFarmTier(uint256 id_) external view returns (uint256) {
        return s.farmTier[id_];
    }

    function toddlerCount(uint256 id_) external view returns (uint256) {
        return LibRebelFarm.farmToddlerQty(id_);
    }

    function growerCount(uint256 id_) external view returns (uint256) {
        return LibRebelFarm.farmGrowerQty(id_);
    }

    function getFarmIdsForOwner(
        address owner_
    ) external view returns (uint256[] memory farmIds_) {
        farmIds_ = s.farmIdsForOwner[owner_];
    }

    function farmOwner(uint256 id_) external view returns (address owner_) {
        owner_ = s.rebelInFarmOwner[id_];
        require(owner_ != address(0), "RebelFarm: Farm is not started!");
    }

    function tierUpgradeCost(uint256 tier_) external pure returns (uint256) {
        return LibFarmCalc.upgradeCost(tier_);
    }

    function tierUpgradeCooldown(
        uint256 tier_
    ) external pure returns (uint256) {
        return LibFarmCalc.upgradeCooldown(tier_);
    }

    function tierMaxGrowSpots(uint256 tier_) external pure returns (uint256) {
        return LibFarmCalc.maxGrowSpots(tier_);
    }

    function tierGrowerFarmRate(uint256 tier_) external pure returns (uint256) {
        return LibFarmCalc.growerFarmRate(tier_);
    }

    function tierHarvestCap(uint256 tier_) external pure returns (uint256) {
        return LibFarmCalc.harvestCap(tier_);
    }
}
