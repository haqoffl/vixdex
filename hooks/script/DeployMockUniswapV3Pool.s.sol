// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/MockUniswapV3Pool.sol";

contract DeployMockUniswapV3Pool is Script {
    function run() external {
        // Broadcast transactions with the deployer private key (set in .env or CLI)
        vm.startBroadcast();

        // Example values for mocking
        uint128 liquidity = 104595618824804872;
        int24 tick = 268203;
        int24 tickSpacing = 60;
        address token1 = 0xb16F35c0Ae2912430DAc15764477E179D9B9EbEa   ; // WETH address on mainnet - 18 decimals
        address token0 = 0x6085268aB3e3b414A08762b671DC38243B29621c  ; // USDT address on mainnet
        uint24 fee = 3000;
        address realPoolAddress = 0xCBCdF9626bC03E24f779434178A73a0B4bad62eD;

        // Deploy the mock contract
        MockUniswapV3Pool mockPool = new MockUniswapV3Pool(
            liquidity,
            tick,
            tickSpacing,
            token0,
            token1,
            fee,
            realPoolAddress
        );

        console.log("MockUniswapV3Pool deployed at:", address(mockPool));

        vm.stopBroadcast();
    }
}

/*

wbtc/weth - 0.3%
    "poolAddress":" 0x04dD2BaDad4c77a65D549Cd03E8CecE215a0ddF4",
    "realAddress":"0xCBCdF9626bC03E24f779434178A73a0B4bad62eD"

*/