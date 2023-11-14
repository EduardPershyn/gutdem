// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import {RaidRequest} from "../libraries/LibAppStorage.sol";
import {FarmRaid} from "../facets/FarmRaid.sol";
import {LibFarmRaid} from "../libraries/LibFarmRaid.sol";

import {VRFConsumer} from "../vrfConsumer/VRFConsumer.sol";

contract FarmRaidTest is FarmRaid {
    using BitMaps for BitMaps.BitMap;

    event ScoutedTest(
        bytes32 requestId
    );
    event FarmRaidedTest(
        bytes32 requestId
    );

    function scoutTest(
        uint256 id_
    ) external onlyDemRebelOwner(id_) onlyActiveFarm(id_) {
        LibFarmRaid.initScout(id_);

        bytes32 requestId = VRFConsumer(address(this)).requestRandomNumber();
        s.scoutRequests[requestId] = id_;

        emit ScoutedTest(requestId);
    }

    function scoutCallbackTest(bytes32 requestId_) external {
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp)));

        uint256 rebelId = s.scoutRequests[requestId_];
        uint256 foundId = LibFarmRaid.pickRandomFarm(rebelId, randomness);

        bool scoutDone = (foundId != rebelId);
        if (scoutDone) {
            s.scoutedFarm[rebelId] = foundId;
        }

        s.isScoutDone.setTo(rebelId, scoutDone);
        emit ScoutPerformed(rebelId, scoutDone);

        s.scoutInProgress.unset(rebelId);
        delete s.scoutRequests[requestId_];
    }

    function raidTest(
        uint24 id_,
        uint256 toddlerQty_
    ) external onlyDemRebelOwner(id_) {
        uint256 raidChance = LibFarmRaid.initRaid(id_, toddlerQty_);
        bytes32 requestId = VRFConsumer(address(this)).requestRandomNumber();
        s.raidRequests[requestId] = RaidRequest(id_, uint232(raidChance));

        emit FarmRaidedTest(requestId);
    }

    function raidCallbackTest(bytes32 requestId_) external {
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp)));

        RaidRequest storage request = s.raidRequests[requestId_];
        bool result = randomness % 100 < request.raidSuccessChance;
        if (result) {
            LibFarmRaid.robSafe(request.pivotFarm);
        }
        emit FarmRaided(
            request.pivotFarm,
            s.scoutedFarm[request.pivotFarm],
            result
        );

        emit FarmRaided(request.pivotFarm, s.scoutedFarm[request.pivotFarm], result);
        delete s.raidRequests[requestId_];
    }
}