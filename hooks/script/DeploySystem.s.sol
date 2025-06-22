// script/DeploySystem.s.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

// --- Standard Imports ---
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "v4-core/src/interfaces/IPoolManager.sol";
import "v4-periphery/src/interfaces/IPositionManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";

// --- Custom Contract Imports ---
import {Vix, IBondingCurve, IVolumeOracle} from "../src/Vix.sol";
import {Router, IPermit2} from "../src/Router.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract DeploySystem is Script {
    // --- UNISWAP V4 CORE CONTRACTS (SEPOLIA) ---
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    address payable constant UNIVERSAL_ROUTER =
        payable(0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b);
    address constant POSITION_MANAGER =
        0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address constant CREATE2_DEPLOYER =
        0x4e59b44847b379578588920cA78FbF26c0B4956C;

    // --- USER'S PRE-DEPLOYED LOGIC (SEPOLIA) ---
    address constant BONDING_CURVE_ADDRESS =
        0x434b002AEa2D9721104bCAb8eAE8576FE884Ffe4;
    address constant VOLUME_ORACLE_ADDRESS =
        0xEe5ED5Ebc40eaA7aDEa3ab92dF5B33f20E380E7c;

    // --- DATA SOURCE POOL (SEPOLIA) ---
    address constant HOOK_DATA_SOURCE_POOL =
        0x07A9C6b321e507AD6eb853A313aFb06286b60B8c; // Example: Sepolia WETH/USDC pool

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployer);

        // 1. Deploy the MockERC20 to use as our base token
        MockERC20 mockBaseToken = new MockERC20("Mock Base Token", "MBT", 6);
        mockBaseToken.mint(deployer, 1_000_000 * (10 ** 6));

        // 2. Prepare for Vix Hook Deployment
        uint160 flags = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
                Hooks.BEFORE_SWAP_FLAG |
                Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG |
                Hooks.AFTER_SWAP_FLAG
        );

        uint256 slope = 3 * 1e15;
        uint256 fee = 3 * 1e15;
        uint256 basePrice = 1 * 1e17;

        bytes memory constructorArgs = abi.encode(
            POOL_MANAGER,
            address(mockBaseToken),
            BONDING_CURVE_ADDRESS,
            VOLUME_ORACLE_ADDRESS,
            slope,
            fee,
            basePrice
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(Vix).creationCode,
            constructorArgs
        );

        // 3. Deploy the Vix Hook using CREATE2
        Vix vixHook = new Vix{salt: salt}(
            IPoolManager(POOL_MANAGER),
            address(mockBaseToken),
            BONDING_CURVE_ADDRESS,
            VOLUME_ORACLE_ADDRESS,
            slope,
            fee,
            basePrice
        );
        require(address(vixHook) == hookAddress, "Hook address mismatch");

        // 4. Deploy your custom Router
        Router router = new Router(
            POSITION_MANAGER,
            UNIVERSAL_ROUTER,
            POOL_MANAGER,
            PERMIT2
        );

        // 5. Define names and symbols for the new VPTs
        string[2] memory tokenNames = ["Vix High IV Token", "Vix Low IV Token"];
        string[2] memory tokenSymbols = ["VixH", "VixL"];

        // 6. Trigger the creation of VPTs, providing all necessary arguments
        vixHook.deploy2Currency(
            HOOK_DATA_SOURCE_POOL,
            tokenNames,
            tokenSymbols,
            HOOK_DATA_SOURCE_POOL
        );

        // 7. NOW fetch the VPT addresses, which will be valid.
        (address highVpt, address lowVpt, , , , , , , ) = vixHook.getVixData(
            HOOK_DATA_SOURCE_POOL
        );

        // 8. Perform the one-time Permit2 setup for the router with the valid token addresses
        mockBaseToken.approve(address(router), type(uint256).max);
        router.approveTokenWithPermit2(
            address(mockBaseToken),
            1_000_000 * (10 ** 6),
            uint48(block.timestamp + 365 days)
        );

        IERC20(highVpt).approve(address(router), type(uint256).max);
        router.approveTokenWithPermit2(
            highVpt,
            type(uint160).max,
            uint48(block.timestamp + 365 days)
        );

        IERC20(lowVpt).approve(address(router), type(uint256).max);
        router.approveTokenWithPermit2(
            lowVpt,
            type(uint160).max,
            uint48(block.timestamp + 365 days)
        );

        // 9. Initialize the liquidity pools
        // Sort tokens for the high-volatility pool to ensure currency0 < currency1
        (address token0High, address token1High) = address(mockBaseToken) <
            highVpt
            ? (address(mockBaseToken), highVpt)
            : (highVpt, address(mockBaseToken));

        PoolKey memory highPoolKey = PoolKey({
            currency0: Currency.wrap(token0High),
            currency1: Currency.wrap(token1High),
            fee: 3000,
            tickSpacing: 60,
            hooks: vixHook
        });
        IPoolManager(POOL_MANAGER).initialize(highPoolKey, 1e18);

        // Sort tokens for the low-volatility pool
        (address token0Low, address token1Low) = address(mockBaseToken) < lowVpt
            ? (address(mockBaseToken), lowVpt)
            : (lowVpt, address(mockBaseToken));

        PoolKey memory lowPoolKey = PoolKey({
            currency0: Currency.wrap(token0Low),
            currency1: Currency.wrap(token1Low),
            fee: 3000,
            tickSpacing: 60,
            hooks: vixHook
        });
        IPoolManager(POOL_MANAGER).initialize(lowPoolKey, 1e18);

        vm.stopBroadcast();

        // 10. Log all necessary addresses for your front-end
        console.log("--- Copy these into your .env.local file ---");
        console.log("NEXT_PUBLIC_VIX_ADDRESS=");
        console.logAddress(address(vixHook));
        console.log("NEXT_PUBLIC_ROUTER_ADDRESS=");
        console.logAddress(address(router));
        console.log("NEXT_PUBLIC_USDC_ADDRESS=");
        console.logAddress(address(mockBaseToken));
        console.log("NEXT_PUBLIC_HIGH_VPT_POOL_ID=");
        console.logBytes32(PoolId.unwrap(PoolIdLibrary.toId(highPoolKey)));
        console.log("NEXT_PUBLIC_LOW_VPT_POOL_ID=");
        console.logBytes32(PoolId.unwrap(PoolIdLibrary.toId(lowPoolKey)));
        console.log("NEXT_PUBLIC_HOOK_DATA_SOURCE_ADDRESS=");
        console.logAddress(HOOK_DATA_SOURCE_POOL);
        console.log("---------------------------------------------");
    }
}
