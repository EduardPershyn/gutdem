// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LibRebelFarm} from '../libraries/LibRebelFarm.sol';
import {LibFarmCalc} from "../libraries/LibFarmCalc.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {ISafe} from "../interfaces/ISafe.sol";

import "hardhat/console.sol";

library LibFarmRaid {
//    function initScout(uint256 _rebelId) internal {
//        AppStorage storage s = LibAppStorage.diamondStorage();
//
//        require(LibRebelFarm.isFarmStarted(_rebelId) == true, 'LibFarmRaid: Farm is not started');
//        require(s.scoutInProgress[_rebelId] == false, "LibFarmRaid: Scout is already initiated");
//        require(isRaidOngoing(_rebelId) == false, "LibFarmRaid: Previous raid is not finished yet");
//        require(LibRebelFarm.farmToddlerQty(_rebelId) > 0, "LibFarmRaid: Should have toddler to scout");
//
//        s.scoutInProgress[_rebelId] = true;
//    }
//
//    function pickRandomFarm(uint256 _forRebel, uint256 _randomness) internal view returns (uint256) {
//        AppStorage storage s = LibAppStorage.diamondStorage();
//
//        //take random id from set of farms from tier that is more or equal
//        uint256 rebelTier = s.farmTier[_forRebel];
//        uint256 idsCount = 0;
//        for ( ;rebelTier <= s.farmMaxTier; rebelTier++ ) {
//            idsCount += s.tierFarmIds[rebelTier].length;
//        }
//        uint256 randomElement = _randomness % idsCount;
//
//        //find the tier the random belongs to
//        uint256 currentPos = 0;
//        uint256 currentTier = s.farmTier[_forRebel];
//        while(s.tierFarmIds[currentTier].length == 0 ||
//            randomElement - currentPos >= s.tierFarmIds[currentTier].length)
//        {
//            currentPos += s.tierFarmIds[currentTier].length;
//            currentTier += 1;
//        }
//
//        uint256 pickedId = randomElement - currentPos;
//
//        return s.tierFarmIds[currentTier][pickedId];
//    }
//
//    function initRaid(uint256 _rebelId, uint256 _toddlerQty) internal returns (uint256) {
//        AppStorage storage s = LibAppStorage.diamondStorage();
//
//        require(LibRebelFarm.isFarmStarted(_rebelId) == true, 'LibFarmRaid: Farm is not started');
//        require(s.isScoutDone[_rebelId] == true, "LibFarmRaid: Scouting should be performed first");
//
//        uint256 targetFarm = s.scoutedFarm[_rebelId];
//        require(LibRebelFarm.isFarmStarted(targetFarm) == true, 'LibFarmRaid: Target farm is not started');
//
//        require(_toddlerQty > 0, "LibFarmRaid: Attacker toddlers should be above zero");
//        require(LibRebelFarm.farmToddlerQty(_rebelId) >= _toddlerQty,
//            "LibFarmRaid: Requested toddlers quantity is exceeds active toddler staff");
//
//        s.toddlerInRaidQty[_rebelId] += _toddlerQty;
//        s.farmRaidStartTime[_rebelId] = block.timestamp;
//        s.isScoutDone[_rebelId] = false;
//
//        return getRaidChance(_toddlerQty, _rebelId, targetFarm);
//    }
//
//    function getRaidChance(uint256 _attackers, uint256 _farmId, uint256 _targetFarm) internal view returns (uint256) {
//        AppStorage storage s = LibAppStorage.diamondStorage();
//
//        uint256 attackBonus = LibFarmCalc.bonusToAttack(s.farmTier[_farmId]);
//        uint256 defenceBonus = LibFarmCalc.bonusToDefense(s.farmTier[_targetFarm]);
//        uint256 defenders = getActiveToddlers(_targetFarm);
//
//        uint256 raidSuccessChance = (_attackers*1e18) / (_attackers + defenders)
//                                    * 100 / 1e18 + attackBonus - defenceBonus;
//
//        console.log("raidSuccessChance", raidSuccessChance);
//        require(raidSuccessChance > 0, "LibFarmRaid: raidSuccessChance should be more than zero");
//
//        return raidSuccessChance;
//    }
//
//    function robSafe(uint256 _rewardFarm) internal {
//        AppStorage storage s = LibAppStorage.diamondStorage();
//
//        uint256 targetFarm = s.scoutedFarm[_rewardFarm];
//        uint256 safeContent = ISafe(s.safeAddress).getSafeContent(targetFarm);
//        uint256 lootShare = s.basicLootShare
//                             + LibFarmCalc.bonusToLoot(s.farmTier[_rewardFarm])
//                             - LibFarmCalc.bonusToProtection(s.farmTier[targetFarm]);
//        console.log("lootShare", lootShare);
//        uint256 jackpotAmount = safeContent / 100 * lootShare;
//        if (jackpotAmount > 0) {
//            ISafe(s.safeAddress).reduceSafeEntry(targetFarm, jackpotAmount);
//            ISafe(s.safeAddress).increaseSafeEntry(_rewardFarm, jackpotAmount);
//        }
//    }
//
    function isRaidOngoing(uint256 _rebelId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.toddlerInRaidQty[_rebelId] > 0;
    }
//
//    function isRaidFinished(uint256 _rebelId) internal view returns (bool) {
//        require(isRaidOngoing(_rebelId) == true, "LibFarmRaid: The raid is not started");
//
//        return timeToFinishRaid(_rebelId) == 0;
//    }
//
//    function timeToFinishRaid(uint256 _rebelId) internal view returns (uint256) {
//        AppStorage storage s = LibAppStorage.diamondStorage();
//
//        if (s.farmRaidDuration < (block.timestamp - s.farmRaidStartTime[_rebelId])) {
//            return 0;
//        }
//        return s.farmRaidDuration - (block.timestamp - s.farmRaidStartTime[_rebelId]);
//    }
//
//    function getActiveToddlers(uint256 _rebelId) internal view returns (uint256) {
//        AppStorage storage s = LibAppStorage.diamondStorage();
//        return LibRebelFarm.farmToddlerQty(_rebelId) - s.toddlerInRaidQty[_rebelId];
//    }
}