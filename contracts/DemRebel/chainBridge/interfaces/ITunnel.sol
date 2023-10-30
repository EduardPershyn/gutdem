// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ITunnel {
    function sendMessage(bytes calldata message_) external;
}
