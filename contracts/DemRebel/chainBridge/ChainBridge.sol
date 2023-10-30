// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LibDemRebel} from "../libraries/LibDemRebel.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {ITunnel} from "./interfaces/ITunnel.sol";

contract ChainBridge is Modifiers {
    function setReflection(
        address key_,
        address reflection_
    ) external onlyOwner {
        s.reflection[key_] = reflection_;
        s.reflection[reflection_] = key_;
    }

    function transition(uint256[] calldata rebelIds) external {
        address target = s.reflection[address(this)];

        uint256 rebelsLen = rebelIds.length;
        if (rebelsLen > 0) {
            _pullIds(rebelIds);

            // This will create rebels exactly as they exist in this chain
            bytes[] memory calls = new bytes[](rebelsLen);
            for (uint256 i = 0; i < rebelsLen; i++) {
                calls[i] = _buildData(rebelIds[i]);
            }

            ITunnel(address(this)).sendMessage(abi.encode(target, calls));
        }
    }

    function buildRebels(
        uint256 id,
        string memory name,
        address owner
    ) external {
        require(
            msg.sender == address(this),
            "ChainBridge: Only diamond contract"
        );

        s.demRebels[id].name = name;
        LibDemRebel.setOwner(id, owner);
    }

    function _buildData(uint256 id) internal view returns (bytes memory data) {
        data = abi.encodeWithSelector(
            this.buildRebels.selector,
            id,
            s.demRebels[id].name,
            msg.sender
        );
        return data;
    }

    function _pullIds(uint256[] calldata ids) internal {
        for (uint256 index = 0; index < ids.length; index++) {
            uint256 id = ids[index];
            require(
                msg.sender == s.demRebels[id].owner,
                "ChainBridge: Only DemRebel owner can transfer"
            );
            LibDemRebel.transfer(msg.sender, address(this), id);
        }
    }
}
