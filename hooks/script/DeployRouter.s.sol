// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Script} from "forge-std/Script.sol";

import {Router} from "../src/Router.sol";
import "forge-std/console.sol";
contract DeployRouter is Script {
    function run() public {
        vm.startBroadcast();
        address positionManager = 0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4; // Replace with actual PositionManager address
        address payable router = payable(0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b); // Replace with actual Router address
        address poolManager = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543; // Replace with actual PoolManager address
        address permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3; // Replace with actual Permit2 address

        Router newRouter = new Router(positionManager, router, poolManager, permit2);
        console.log("Router deployed at:", address(newRouter));
        vm.stopBroadcast();
    }
} 


