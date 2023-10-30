// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {FxBaseChildTunnel} from "./base/FxBaseChildTunnel.sol";

contract ChildTunnel is FxBaseChildTunnel {
    event CallMade(address target, bool success, bytes data);

    function initializeChild(address fxChild_) external onlyOwner {
        s.fxChild = fxChild_;
    }

    function _processMessageFromRoot(
        uint256,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        (address target, bytes[] memory calls) = abi.decode(
            data,
            (address, bytes[])
        );
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = target.call(calls[i]);
            emit CallMade(target, success, calls[i]);
        }
    }

    function sendMessage(bytes memory message_) public virtual {
        require(
            msg.sender == address(this),
            "ChildTunnel: Only diamond contract"
        );
        _sendMessageToRoot(message_);
    }
}
