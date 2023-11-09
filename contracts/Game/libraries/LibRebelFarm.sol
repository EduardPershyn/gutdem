// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LibFarmCalc} from "./LibFarmCalc.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC721TokenIds} from "../../shared/interfaces/IERC721TokenIds.sol";
import {ISafe} from "../interfaces/ISafe.sol";

library LibRebelFarm {
    function isFarmActivated(uint256 id_) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.farmTier[id_] != 0;
    }

    function isFarmStarted(uint256 id_) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.rebelInFarmOwner[id_] != address(0);
    }

    function pullRebel(uint256 id_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        IERC721(s.demRebelAddress).transferFrom(msg.sender, address(this), id_);
        s.rebelInFarmOwner[id_] = msg.sender;

        //Add to address FarmIds cache
        s.farmIdsForOwnerIndexes[msg.sender][id_] = s
            .farmIdsForOwner[msg.sender]
            .length;
        s.farmIdsForOwner[msg.sender].push(id_);
    }

    function releaseRebel(uint256 id_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        address owner = s.rebelInFarmOwner[id_];
        IERC721(s.demRebelAddress).transferFrom(address(this), owner, id_);
        delete s.rebelInFarmOwner[id_];

        //Clear from address FarmIds cache
        uint256 index = s.farmIdsForOwnerIndexes[owner][id_];
        uint256 lastIndex = s.farmIdsForOwner[owner].length - 1;
        if (index != lastIndex) {
            uint256 lastTokenId = s.farmIdsForOwner[owner][lastIndex];
            s.farmIdsForOwner[owner][index] = lastTokenId;
            s.farmIdsForOwnerIndexes[owner][lastTokenId] = index;
        }
        s.farmIdsForOwner[owner].pop();
        delete s.farmIdsForOwnerIndexes[owner][id_];
    }

    function pullGrowers(uint256 id_, uint256 growerQty_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256[] memory growerIds = IERC721TokenIds(s.demGrowerAddress)
            .tokenIdsOfOwner(msg.sender);
        require(
            growerIds.length >= growerQty_,
            "LibRebelFarm: Not enough growers on account!"
        );

        require(
            LibFarmCalc.maxGrowSpots(s.farmTier[id_]) >=
                farmGrowerQty(id_) + growerQty_,
            "LibRebelFarm: Insufficient farm tier"
        );

        for (uint256 index = 0; index < growerQty_; index++) {
            uint256 growerId = growerIds[index];
            IERC721(s.demGrowerAddress).transferFrom(
                msg.sender,
                address(this),
                growerId
            );
            s.rebelFarmGrowers[id_].push(growerId);
        }
    }

    function releaseGrowers(uint256 id_, uint256 growerQty_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(
            farmGrowerQty(id_) >= growerQty_,
            "LibRebelFarm: Pulled growers count under requested value!"
        );

        address owner = s.rebelInFarmOwner[id_];
        for (int256 i = int256(growerQty_) - 1; i >= 0; --i) {
            uint256 index = uint256(i);
            uint256 growerId = s.rebelFarmGrowers[id_][index];
            IERC721(s.demGrowerAddress).transferFrom(
                address(this),
                owner,
                growerId
            );

            uint256 lastIndex = s.rebelFarmGrowers[id_].length - 1;
            s.rebelFarmGrowers[id_][index] = s.rebelFarmGrowers[id_][lastIndex];
            s.rebelFarmGrowers[id_].pop();
        }
    }

    function pullToddlers(uint256 id_, uint256 toddlerQty_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256[] memory toddlerIds = IERC721TokenIds(s.demToddlerAddress)
            .tokenIdsOfOwner(msg.sender);
        require(
            toddlerIds.length >= toddlerQty_,
            "LibRebelFarm: Not enough toddlers on account!"
        );

        require(
            farmToddlerQty(id_) + toddlerQty_ <= s.toddlerMaxCount,
            "LibRebelFarm: Above toddlers limit"
        );

        for (uint256 index = 0; index < toddlerQty_; index++) {
            uint256 toddlerId = toddlerIds[index];
            IERC721(s.demToddlerAddress).transferFrom(
                msg.sender,
                address(this),
                toddlerId
            );
            s.rebelFarmToddlers[id_].push(toddlerId);
        }
    }

    function releaseToddlers(uint256 id_, uint256 toddlerQty_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(
            farmToddlerQty(id_) >= toddlerQty_,
            "LibRebelFarm: Pulled toddlers count under requested value!"
        );

        address owner = s.rebelInFarmOwner[id_];
        for (int256 i = int256(toddlerQty_) - 1; i >= 0; --i) {
            uint256 index = uint256(i);
            uint256 toddlerId = s.rebelFarmToddlers[id_][index];
            IERC721(s.demToddlerAddress).transferFrom(
                address(this),
                owner,
                toddlerId
            );

            uint256 lastIndex = s.rebelFarmToddlers[id_].length - 1;
            s.rebelFarmToddlers[id_][index] = s.rebelFarmToddlers[id_][
                lastIndex
            ];
            s.rebelFarmToddlers[id_].pop();
        }
    }

    function farmToddlerQty(uint256 id_) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.rebelFarmToddlers[id_].length;
    }

    function farmGrowerQty(uint256 id_) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.rebelFarmGrowers[id_].length;
    }

    function harvest(uint256 id_) internal {
        require(isFarmStarted(id_), "LibRebelFarm: Rebel Farm not started!");

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 amount = harvestAmount(id_);
        if (amount > 0) {
            transferToSafe(id_, amount);
            s.farmStockHarvest[id_] = 0;
            updateHarvestTimestamp(id_);
        }
    }

    function transferToSafe(uint256 id_, uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        ISafe(s.safeAddress).increaseSafeEntry(id_, amount);
    }

    function payFromSafe(uint256 id_, uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        ISafe(s.safeAddress).reduceSafeEntry(id_, amount);
    }

    function updateHarvestTimestamp(uint256 id_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.farmHarvestedTime[id_] = block.timestamp;
    }

    function updateHarvestStock(uint256 id_) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.farmStockHarvest[id_] = harvestAmount(id_);
        updateHarvestTimestamp(id_);
    }

    function harvestAmount(uint256 id_) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 amount = s.farmStockHarvest[id_] +
            ((block.timestamp - s.farmHarvestedTime[id_]) / s.farmPeriod) *
            getFarmRate(id_);

        uint256 capacity = LibFarmCalc.harvestCap(s.farmTier[id_]);
        return amount > capacity ? capacity : amount;
    }

    function getFarmRate(uint256 id_) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return farmGrowerQty(id_) * LibFarmCalc.growerFarmRate(s.farmTier[id_]);
    }

    function farmUpgradeCooldown(uint256 id_) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 cdTime = LibFarmCalc.upgradeCooldown(s.farmTier[id_]);
        if (cdTime < (block.timestamp - s.farmUpgradeTime[id_])) {
            return 0;
        }
        return cdTime - (block.timestamp - s.farmUpgradeTime[id_]);
    }

    function removeFromTierIndex(uint256 rebelId, uint256 tier) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 index = s.tierFarmIdIndexes[tier][rebelId];
        uint256 lastIndex = s.tierFarmIds[tier].length - 1;
        if (index != lastIndex) {
            uint256 lastTokenId = s.tierFarmIds[tier][lastIndex];
            s.tierFarmIds[tier][index] = lastTokenId;
            s.tierFarmIdIndexes[tier][lastTokenId] = index;
        }
        s.tierFarmIds[tier].pop();
        delete s.tierFarmIdIndexes[tier][rebelId];
    }

    function addToTierIndex(uint256 rebelId, uint256 tier) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.tierFarmIdIndexes[tier][rebelId] = s.tierFarmIds[tier].length;
        s.tierFarmIds[tier].push(rebelId);
    }
}
