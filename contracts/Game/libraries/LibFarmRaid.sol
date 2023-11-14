// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import {LibRebelFarm} from "../libraries/LibRebelFarm.sol";
import {LibFarmCalc} from "../libraries/LibFarmCalc.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {ISafe} from "../interfaces/ISafe.sol";

import "hardhat/console.sol";

library LibFarmRaid {
    using BitMaps for BitMaps.BitMap;

    function initScout(uint256 id_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(
            s.scoutInProgress.get(id_) == false,
            "LibFarmRaid: Scout is already initiated"
        );
        require(
            isRaidOngoing(id_) == false,
            "LibFarmRaid: Previous raid is not finished yet"
        );
        require(
            LibRebelFarm.farmToddlerQty(id_) > 0,
            "LibFarmRaid: Should have toddler to scout"
        );

        s.scoutInProgress.set(id_);
    }

    function pickRandomFarm(
        uint256 id_,
        uint256 randomness_
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        //take random id from set of farms from tier that is more or equal
        //mapping(uint256 => uint256) farmGrowersCount;
        uint256 rebelTier = s.farmTier[id_];
        uint256 idsCount = 0;
        for (; rebelTier <= s.farmMaxTier; rebelTier++) {
            idsCount += s.tierFarmIds[rebelTier].length;
        }
        uint256 randomElement = randomness_ % idsCount;

        //find the tier the random belongs to
        uint256 currentPos = 0;
        uint256 currentTier = s.farmTier[id_];
        while (
            s.tierFarmIds[currentTier].length == 0 ||
            randomElement - currentPos >= s.tierFarmIds[currentTier].length
        ) {
            currentPos += s.tierFarmIds[currentTier].length;
            currentTier += 1;
        }

        uint256 pickedId = randomElement - currentPos;

        return s.tierFarmIds[currentTier][pickedId];
    }

    function initRaid(
        uint256 id_,
        uint256 toddlerQty_
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(
            s.isScoutDone.get(id_) == true,
            "LibFarmRaid: Scouting should be performed first"
        );
        uint256 targetFarm = s.scoutedFarm[id_];

        require(
            toddlerQty_ > 0,
            "LibFarmRaid: Attacker toddlers should be above zero"
        );
        require(
            LibRebelFarm.farmToddlerQty(id_) >= toddlerQty_,
            "LibFarmRaid: Requested toddlers quantity is exceeds active toddler staff"
        );

        s.toddlerInRaidQty[id_] += toddlerQty_;
        s.farmRaidStartTime[id_] = block.timestamp;
        s.isScoutDone.unset(id_);

        return getRaidChance(toddlerQty_, id_, targetFarm);
    }

    function getRaidChance(
        uint256 attackers_,
        uint256 farmId_,
        uint256 targetFarm_
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 attackBonus = LibFarmCalc.bonusToAttack(s.farmTier[farmId_]);
        uint256 defenceBonus = LibFarmCalc.bonusToDefense(
            s.farmTier[targetFarm_]
        );
        uint256 defenders = getActiveToddlers(targetFarm_);

        uint256 raidSuccessChance = (((attackers_ * 1e18) /
            (attackers_ + defenders)) * 100) /
            1e18 +
            attackBonus -
            defenceBonus;

        console.log("raidSuccessChance", raidSuccessChance);
        assert(raidSuccessChance > 0);

        return raidSuccessChance;
    }

    function robSafe(uint256 rewardFarm_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 targetFarm = s.scoutedFarm[rewardFarm_];
        uint256 safeContent = ISafe(s.safeAddress).getSafeContent(targetFarm);
        uint256 lootShare = s.basicLootShare +
            LibFarmCalc.bonusToLoot(s.farmTier[rewardFarm_]) -
            LibFarmCalc.bonusToProtection(s.farmTier[targetFarm]);
        console.log("lootShare", lootShare);
        uint256 jackpotAmount = (safeContent / 100) * lootShare;
        if (jackpotAmount > 0) {
            ISafe(s.safeAddress).reduceSafeEntry(targetFarm, jackpotAmount);
            ISafe(s.safeAddress).increaseSafeEntry(rewardFarm_, jackpotAmount);
        }
    }

    function isRaidOngoing(uint256 id_) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.toddlerInRaidQty[id_] > 0;
    }

    function isRaidFinished(uint256 id_) internal view returns (bool) {
        require(
            isRaidOngoing(id_) == true,
            "LibFarmRaid: The raid is not started"
        );

        return timeToFinishRaid(id_) == 0;
    }

    function timeToFinishRaid(uint256 id_) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (s.farmRaidDuration < (block.timestamp - s.farmRaidStartTime[id_])) {
            return 0;
        }
        return
            s.farmRaidDuration - (block.timestamp - s.farmRaidStartTime[id_]);
    }

    function getActiveToddlers(uint256 id_) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return LibRebelFarm.farmToddlerQty(id_) - s.toddlerInRaidQty[id_];
    }
}
