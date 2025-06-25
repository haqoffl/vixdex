// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/Router.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PoolKey, Currency} from "v4-core/src/types/PoolKey.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";

//uses address from mainnet, so need to fork mainnet to test this, save RPC url as an evironment var MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/yourKey


contract RouterForkTest is Test {
    using SafeERC20 for IERC20;
    
    Router public router;

    address constant POSITION_MANAGER = 0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4;
    address constant UNIVERSAL_ROUTER = 0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b;
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant HIGH = 0x2c39e1831464B8acd3b41E941b59965538AD4DAc;
    

    // A known whale holding USDC on mainnet
    address constant whale = 0x55FE002aefF02F77364de339a1292923A15844B8;

    function setUp() public {
        // vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
        vm.startPrank(whale);

        router = new Router(POSITION_MANAGER, payable(UNIVERSAL_ROUTER), POOL_MANAGER, PERMIT2);

        // Give the whale some USDC if needed on fork
        deal(USDC, whale, 100_000e6);

        // IMPORTANT: Approve the router directly to spend whale's USDC
        IERC20(USDC).approve(address(router), type(uint256).max);

        
        // Also setup Permit2 for the router contract
        router.approveTokenWithPermit2(USDC, 10_000e6, uint48(block.timestamp + 3600));

        vm.stopPrank();
    }
    function testExactInputSwapSingle_USDC_To_VPTs() public {
        vm.startPrank(whale);
        
        // PoolKey memory key = PoolKey({
        //     currency0: Currency.wrap(USDC),
        //     currency1: Currency.wrap(HIGH),
        //     fee: 3000,
        //     tickSpacing: 60,
        //     hooks: IHooks(address(0xA84e223e414176D612685a1277d0BAF309D388c8))
        // });

        // uint128 amountIn = 10_000e6;
        // uint128 minAmountOut = 9_900e6;
        // bool zeroForOne = true;
	
        uint256 amountOut = router.ExactOutputSwapSingle(
            USDC,
            HIGH,
            3000,
            60,
            0x18081f554ce7503e0BE894B5D7dfE9AA83fBC8C8,
            4 ether,
            2 * 1e6,
            true,
            0x74CB8871FE62ADA6EC9965f9dd7C1D0826de26cc, 
            whale);
            
        console.log("balance of high token: ",IERC20(HIGH).balanceOf(whale));
            
	    console.log("balance of USDC token: ",IERC20(USDC).balanceOf(whale));
        console.log("Amount out:", amountOut);
        // IERC20(HIGH).approve(address(router), type(uint256).max);

         
        // Also setup Permit2 for the router contract
        // router.approveTokenWithPermit2(HIGH,3 ether, uint48(block.timestamp + 3600));
        // uint256 amountIn = router.ExactInputSwapSingle(
        // 	USDC,
        // 	HIGH,
        // 	3000,
        // 	60,
        // 	0x18081f554ce7503e0BE894B5D7dfE9AA83fBC8C8,
        // 	3 ether,
        // 	0,
        // 	false,
        // 	0x74CB8871FE62ADA6EC9965f9dd7C1D0826de26cc,
        // 	whale
        // );
        // console.log("balance of USDC token: ",IERC20(USDC).balanceOf(whale));
        // console.log("Amount out:", amountIn);

        // emit log_named_uint("USDT received", amountOut);
        // assertGt(amountOut, minAmountOut, "Should receive more than minimum USDT");

        vm.stopPrank();
    }
    
    // function testExactInputSwapSingle_RevertsOnLowMinAmountOut() public {
    //     vm.startPrank(whale);

    //     PoolKey memory key = PoolKey({
    //         currency0: Currency.wrap(USDC),
    //         currency1: Currency.wrap(USDT),
    //         fee: 100,
    //         tickSpacing: 1,
    //         hooks: IHooks(address(0))
    //     });

    //     uint128 amountIn = 10_000e6;
    //     uint128 minAmountOut = 100_000e6; // too high
    //     bool zeroForOne = true;

    //     vm.expectRevert();
    //     router.ExactInputSwapSingle(
    //         key,
    //         amountIn,
    //         minAmountOut,
    //         zeroForOne,
    //         "",
    //         whale
    //     );

    //     vm.stopPrank();
    // }

    // function testExactOutputSwapSingle_USDC_to_USDT() public {
    //     vm.startPrank(whale);

    //     PoolKey memory key = PoolKey({
    //         currency0: Currency.wrap(USDC),
    //         currency1: Currency.wrap(USDT),
    //         fee: 100,
    //         tickSpacing: 1,
    //         hooks: IHooks(address(0))
    //     });

    //     uint128 amountOut = 9_000e6;
    //     uint128 maxAmountIn = 10_000e6;
    //     bool zeroForOne = true;

    //     uint256 amountIn = router.ExactOutputSwapSingle(
    //         key,
    //         amountOut,
    //         maxAmountIn,
    //         zeroForOne,
    //         "",
    //         whale
    //     );

    //     emit log_named_uint("USDC spent", amountIn);
    //     assertLe(amountIn, maxAmountIn, "Spent more than allowed input");

    //     vm.stopPrank();
    // }

    // function testExactOutputSwapSingle_RevertsOnLowMaxAmountIn() public {
    //     vm.startPrank(whale);

    //     PoolKey memory key = PoolKey({
    //         currency0: Currency.wrap(USDC),
    //         currency1: Currency.wrap(USDT),
    //         fee: 100,
    //         tickSpacing: 1,
    //         hooks: IHooks(address(0))
    //     });

    //     uint128 amountOut = 9_000e6;
    //     uint128 maxAmountIn = 1000e6; // too low
    //     bool zeroForOne = true;

    //     vm.expectRevert();
    //     router.ExactOutputSwapSingle(
    //         key,
    //         amountOut,
    //         maxAmountIn,
    //         zeroForOne,
    //         "",
    //         whale
    //     );

    //     vm.stopPrank();
    // }

    // function testApproveTokenWithPermit2() public {
    //     vm.startPrank(whale);

    //     uint160 amount = 1_000e6;
    //     uint48 expiration = uint48(block.timestamp + 3600);

    //     router.approveTokenWithPermit2(USDC, amount, expiration);

    //     assertTrue(true, "approveTokenWithPermit2 ran without errors");

    //     vm.stopPrank();
    // }

    // function testCreatePool_RevertsOnInvalidToken() public {
    //     vm.startPrank(whale);

    //     address invalidToken = address(0);
    //     address tokenB = USDT;

    //     vm.expectRevert();
    //     router.createPool(
    //         invalidToken,
    //         tokenB,
    //         100,
    //         1,
    //         address(0),
    //         79228162514264337593543950336
    //     );

    //     vm.stopPrank();
    // }
}
