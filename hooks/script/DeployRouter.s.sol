// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Script} from "forge-std/Script.sol";

import {Router} from "../src/Router.sol";
import "forge-std/console.sol";
contract DeployRouter is Script {
    function run() public {
        vm.startBroadcast();
        address positionManager = 0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e; // Replace with actual PositionManager address
        address payable router = payable(0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af); // Replace with actual Router address
        address poolManager = 0x000000000004444c5dc75cB358380D2e3dE08A90; // Replace with actual PoolManager address
        address permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3; // Replace with actual Permit2 address

        Router newRouter = new Router(positionManager, router, poolManager, permit2);
        console.log("Router deployed at:", address(newRouter));
        vm.stopBroadcast();
    }
}