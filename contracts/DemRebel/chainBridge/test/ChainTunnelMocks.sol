// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ChildTunnel} from "../ChildTunnel.sol";
import {RootTunnel} from "../RootTunnel.sol";

interface TunnelLike {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
    function receiveMessage(bytes memory data) external;
}

contract MockFxRoot {
    function sendMessageToChild(address child, bytes calldata data) external {
        TunnelLike(child).processMessageFromRoot(1, msg.sender, data);
    }
    function sendMessageToRoot(address root, bytes calldata data) external {
        TunnelLike(root).receiveMessage(data);
    }
}

contract MockChildTunnel is ChildTunnel {
    function sendMessage(bytes memory message_) override public {
        require(msg.sender == address(this), "ChildTunnel: Only diamond contract");
        MockFxRoot(s.fxChild).sendMessageToRoot(s.fxRootTunnel, message_);
        emit MessageSent(message_);
    }
}

contract MockRootTunnel is RootTunnel {
    function receiveMessage(bytes memory inputData) public override {
        _processMessageFromChild(inputData);
    }
}