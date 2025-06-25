// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {Vix} from "../src/Vix.sol";
import "forge-std/console.sol";

contract HookMiningSample is Script {
    // Address of PoolManager deployed on Sepolia
    PoolManager manager =
        PoolManager(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543);
    address baseToken = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // change to your base token address

    function setUp() public {
		// Set up the hook flags you wish to enable
        uint160 flags = uint160(
                    Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
                    Hooks.BEFORE_SWAP_FLAG |
                    Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG |
                    Hooks.AFTER_SWAP_FLAG);

		// Find an address + salt using HookMiner that meets our flags criteria
        address CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C; //create2 deployer address in Sepolia
        address _bondingCurve = 0xCa7FF6ad2e29cc407E399946c0E4e62cca18B730; //replace with actual BondingCurve address
        address volumeOracle = 0xDf2D6dc6598655685FF9f6f272324B8E749A3546; // Replace with actual VolumeOracle address 
        uint slope = 0.03 * 1e18;
         uint fee = 0.0003 * 1e18;
         uint basePrice = 0.1 * 1e18;
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(Vix).creationCode,
            abi.encode(address(manager),address(baseToken),_bondingCurve,volumeOracle,slope,fee,basePrice)
        );		// Deploy our hook contract with the given `salt` value
        vm.startBroadcast();
        Vix hook = new Vix{salt: salt}(manager, baseToken,_bondingCurve,volumeOracle,slope,fee,basePrice);
		// Ensure it got deployed to our pre-computed address
        require(address(hook) == hookAddress, "hook address mismatch");
        console.log(address(hook));
        vm.stopBroadcast();
    }

    function run() public {
        console.log("successfully deployed Vix hook contract");
    }
    
}
 
