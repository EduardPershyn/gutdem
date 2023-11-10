// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibRebelFarm} from "../libraries/LibRebelFarm.sol";
import {LibFarmRaid} from "../libraries/LibFarmRaid.sol";
import {LibFarmCalc} from "../libraries/LibFarmCalc.sol";

contract RebelFarm is Modifiers {
    using BitMaps for BitMaps.BitMap;

    function activateFarm(
        uint256 id_,
        uint256[] calldata growerIds_,
        uint256[] calldata toddlerIds_
    ) external onlyDemRebelOwner(id_) {
        require(
            LibRebelFarm.isFarmActivated(id_) == false,
            "RebelFarm: Farm is already activated"
        );

        s.farmTier[id_] = 1;

        LibRebelFarm.addGrowers(id_, growerIds_);
        LibRebelFarm.addToddlers(id_, toddlerIds_);

        LibRebelFarm.updateHarvestTimestamp(id_);
        LibRebelFarm.addToTierIndex(id_, s.farmTier[id_]);
    }

    function isFarmActivated(uint256 id_) external view returns (bool) {
        return LibRebelFarm.isFarmActivated(id_);
    }

    function harvestAmount(uint256 id_) external view returns (uint256) {
        return LibRebelFarm.harvestAmount(id_);
    }

    function harvestFarm(uint256 id_) external onlyDemRebelOwner(id_) {
        LibRebelFarm.harvest(id_);
    }

    function getRebelFarmPeriod() external view returns (uint256) {
        return s.farmPeriod;
    }

    function setRebelFarmPeriod(uint256 period_) external onlyGameManager {
        require(period_ > 0, "RebelFarm: Period should be greater than 0");
        s.farmPeriod = period_;
    }

    function getFarmRate(uint256 id_) external view returns (uint256) {
        return LibRebelFarm.getFarmRate(id_);
    }

    function farmUpgradeCooldown(uint256 id_) external view returns (uint256) {
        return LibRebelFarm.farmUpgradeCooldown(id_);
    }

    function increaseTier(uint256 id_) external onlyDemRebelOwner(id_) {
        require(
            LibRebelFarm.isFarmActivated(id_),
            "RebelFarm: Farm is not activated"
        );
        require(s.farmTier[id_] < s.farmMaxTier, "RebelFarm: Exceeds max tier");
        require(
            LibRebelFarm.farmUpgradeCooldown(id_) == 0,
            "RebelFarm: Upgrade cooldown"
        );

        LibRebelFarm.payFromSafe(
            id_,
            LibFarmCalc.upgradeCost(s.farmTier[id_] + 1)
        );

        LibRebelFarm.updateHarvestStock(id_);
        LibRebelFarm.removeFromTierIndex(id_, s.farmTier[id_]);
        LibRebelFarm.addToTierIndex(id_, s.farmTier[id_] + 1);

        s.farmTier[id_] += 1;
        s.farmUpgradeTime[id_] = block.timestamp;
    }

    function addGrowers(uint256 id_, uint256[] calldata growerIds_) external {
        LibRebelFarm.updateHarvestStock(id_);
        LibRebelFarm.addGrowers(id_, growerIds_);
    }

    function removeGrowers(
        uint256 id_,
        uint256[] calldata growerIds_
    ) external {
        LibRebelFarm.updateHarvestStock(id_);
        LibRebelFarm.releaseGrowers(id_, growerIds_);
    }

    function addToddlers(uint256 id_, uint256[] calldata toddlerIds_) external {
        LibRebelFarm.updateHarvestStock(id_);
        LibRebelFarm.addToddlers(id_, toddlerIds_);
    }

    function removeToddlers(
        uint256 id_,
        uint256[] calldata toddlerIds_
    ) external {
        require(
            LibFarmRaid.isRaidOngoing(id_) == false,
            "RebelFarm: Farm raid is ongoing"
        );

        LibRebelFarm.updateHarvestStock(id_);
        LibRebelFarm.releaseToddlers(id_, toddlerIds_);
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
