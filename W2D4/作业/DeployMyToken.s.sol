// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../src/W2D4/MyToken.sol";

contract DeployMyToken is Script {
    function run() external returns (MyToken) {
        // 开始记录后续的操作会被广播
        vm.startBroadcast();

        // 部署 MyToken 合约
        MyToken token = new MyToken();

        vm.stopBroadcast();
        return token;
    }
}