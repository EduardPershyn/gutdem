// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {FxBaseRootTunnel} from "./base/FxBaseRootTunnel.sol";
import {ICheckpointManager, IFxStateSender} from "./interfaces/ICheckpointManager.sol";

contract RootTunnel is FxBaseRootTunnel {
    event CallMade(address target, bool success, bytes data);

    function initializeRoot(
        address fxRoot_,
        address checkpointManager_
    ) external onlyOwner {
        s.fxRoot = IFxStateSender(fxRoot_);
        s.checkpointManager = ICheckpointManager(checkpointManager_);
    }

    function _processMessageFromChild(bytes memory data) internal override {
        (address target, bytes[] memory calls) = abi.decode(
            data,
            (address, bytes[])
        );
        for (uint256 i = 0; i < calls.length; i++) {
            (bool succ, ) = target.call(calls[i]);
            emit CallMade(target, succ, calls[i]);
        }
    }

    function sendMessage(bytes memory message_) public {
        require(
            msg.sender == address(this),
            "RootTunnel: Only diamond contract"
        );
        _sendMessageToChild(message_);
    }
}
