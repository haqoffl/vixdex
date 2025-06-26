// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Test,console} from "forge-std/Test.sol";
import {Deployers} from "v4-core/test/utils/Deployers.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {CurrencySettler} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import {SortTokens} from "@uniswap/v4-core/test/utils/SortTokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {Vix} from "../src/Vix.sol";
//neede to automatically deploy and get bytecode adn address of bonding curve
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {IVolumeOracle} from "../src/interfaces/IVolumeOracle.sol";
import {IMinimalUniswapV3Pool} from "../src/MockUniswapV3Pool.sol";
contract VixTest is Test,Deployers {
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    Vix hook;
    address public baseToken;
    address public poolAdd = 0xFf1Ddc65b292d4a8f4251DBa04f2B170DbBC69d7; // pool address of uniswap V3 pair (WBTC/ETH)
    address[2] ivTokenAdd;
    address volumeOracle = 0xDf2D6dc6598655685FF9f6f272324B8E749A3546; // volume oracle from vixdex

    struct HookData{
        address poolAdd;
    }
    address _bondingCurve = 0xCa7FF6ad2e29cc407E399946c0E4e62cca18B730; // Bonding curve address 
    uint slope = 0.003 * 1e18; //slope of bonding curve
    uint fee = 0.003 * 1e18; // fee for the bonding curve
    uint basePrice = 0.1 * 1e18; // base price of the bonding curve

    function setUp()external {
        deployFreshManagerAndRouters();
        (currency0, currency1) = deployMintAndApprove2Currencies();   
        console.log("_baseTokenCurrency: ",Currency.unwrap(currency0));
        baseToken = address(Currency.unwrap(currency0));
        address hookAddress = address(
            uint160(
                    Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
                    Hooks.BEFORE_SWAP_FLAG |
                    Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG |
                    Hooks.AFTER_SWAP_FLAG
            )
        );
        deployCodeTo("Vix.sol",abi.encode(manager,baseToken,_bondingCurve,volumeOracle,slope,fee,basePrice),hookAddress);

        hook = Vix(hookAddress);
        (address[2] memory ivTokenAddresses) = hook.deploy2Currency(poolAdd,["HIGH-IV-BTC","LOW-IV-BTC"],["HIVB","LIVB"],poolAdd);
        ivTokenAdd = ivTokenAddresses;
        assertEq(MockERC20(ivTokenAdd[0]).balanceOf(address(manager)), MockERC20(ivTokenAdd[0]).totalSupply());
        assertEq(MockERC20(ivTokenAdd[1]).balanceOf(address(manager)), MockERC20(ivTokenAdd[1]).totalSupply());
        console.log("vix token 0 address",ivTokenAdd[0]);
        console.log("vix token 1 address",ivTokenAdd[1]);
        uint token0ClaimID = CurrencyLibrary.toId(Currency.wrap(ivTokenAdd[0]));
        uint token1ClaimID = CurrencyLibrary.toId(Currency.wrap(ivTokenAdd[1]));

        uint token0ClaimsBalance = manager.balanceOf(
            address(hook),
            token0ClaimID
        );
        uint token1ClaimsBalance = manager.balanceOf(
            address(hook),
            token1ClaimID
        );

        console.log("token0 claims balance in pool manager: ",token0ClaimsBalance);
        console.log("token1 claims balance in pool manager: ",token1ClaimsBalance);
        console.log("hook address: ",address(hook));
      
    }

 

function test_swapHighVolatileToken() external {
    vm.skip(true);
    _testSwap(ivTokenAdd[0], "High VIX Token");
}

function test_swapLowVolatileToken() external {
    vm.skip(true);
    _testSwap(ivTokenAdd[1], "Low VIX Token");
}

function test_VPTsPriceChangesAccordingToIv() external {
    Currency token0;
    Currency token1;

    (token0, token1) = SortTokens.sort(MockERC20(baseToken), MockERC20(ivTokenAdd[0]));
    (key, ) = initPool(token0, token1, hook, 3000, SQRT_PRICE_1_1);

    bytes memory hookData = abi.encode(HookData(poolAdd));
    PoolSwapTest.TestSettings memory settings = PoolSwapTest.TestSettings({
        takeClaims: false,
        settleUsingBurn: false
    });


    _buyIVToken(token0,ivTokenAdd[0], settings, hookData);

    //low token buying

    (token0, token1) = SortTokens.sort(MockERC20(baseToken), MockERC20(ivTokenAdd[1]));
    (key, ) = initPool(token0, token1, hook, 3000, SQRT_PRICE_1_1);
    _buyIVToken(token0,ivTokenAdd[1], settings, hookData);

    console.log("liquidity: ",IMinimalUniswapV3Pool(poolAdd).liquidity());
    IMinimalUniswapV3Pool(poolAdd).setTickAndLiq(
        113167885471817127,
        268011
    );
    console.log("liquidity after setting tick and liq: ",IMinimalUniswapV3Pool(poolAdd).liquidity());
    (address vixHighToken,address _vixLowToken,uint _circulation0,uint _circulation1,uint _contractHoldings0,uint _contractHoldings1,uint _reserve0,uint _reserve1,uint160 _averageIV,address _poolAddress)= hook.getVixData(poolAdd);

    console.log("contract holdings of high token",_contractHoldings0);
    console.log("contract holdings of low token",_contractHoldings1);
    console.log("reserve of high token",_reserve0);
    console.log("reserve of low token",_reserve1);
    (token0, token1) = SortTokens.sort(MockERC20(baseToken), MockERC20(ivTokenAdd[1]));
    _buyIVToken(token0,ivTokenAdd[1], settings, hookData);

    (vixHighToken,_vixLowToken,_circulation0,_circulation1,_contractHoldings0,_contractHoldings1,_reserve0,_reserve1,_averageIV,_poolAddress)= hook.getVixData(poolAdd);
    console.log("contract holding of high token after buying low token",_contractHoldings0);
    console.log("contract holding of low token after buying low token",_contractHoldings1);
    console.log("reserve of high token after buying low token",_reserve0);
    console.log("reserve of low token after buying low token",_reserve1);
    console.log("average IV after buying low token",_averageIV);

   

}

function _testSwap(address ivToken, string memory label) internal {
    Currency token0;
    Currency token1;

    (token0, token1) = SortTokens.sort(MockERC20(baseToken), MockERC20(ivToken));
    (key, ) = initPool(token0, token1, hook, 3000, SQRT_PRICE_1_1);

    bytes memory hookData = abi.encode(HookData(poolAdd));
    PoolSwapTest.TestSettings memory settings = PoolSwapTest.TestSettings({
        takeClaims: false,
        settleUsingBurn: false
    });

    console.log(string.concat("== Testing ", label, " =="));
    console.log("Initial base token balance:", MockERC20(baseToken).balanceOf(address(this)));
    console.log(string.concat("Initial ", label, " balance:"), MockERC20(ivToken).balanceOf(address(this)));

    _buyIVToken(token0, ivToken, settings, hookData);
    _sellIVToken(token0, ivToken, settings, hookData);

    // Earnings Withdrawal (optional)
    hook.withdrawEarningsForOwner();
    hook.withdrawEarningsForInitiator(poolAdd);

    console.log("Final base token balance:", MockERC20(baseToken).balanceOf(address(this)));
    console.log(string.concat("Final ", label, " balance:"), MockERC20(ivToken).balanceOf(address(this)));
    console.log("Base token balance in pool manager:", MockERC20(baseToken).balanceOf(address(manager)));
}

function _buyIVToken(Currency token0, address ivToken, PoolSwapTest.TestSettings memory settings, bytes memory hookData) internal {
    bool baseIsToken0 = Currency.unwrap(token0) == baseToken;

    console.log("Buying IV token...");
    swapRouter.swap(
        key,
        IPoolManager.SwapParams({
            zeroForOne: baseIsToken0, // base to iv
            amountSpecified: 10 ether,
            sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE + 1
        }),
        settings,
        hookData
    );

    uint bought = MockERC20(ivToken).balanceOf(address(this));
    console.log("IV token bought:", bought);
    console.log("Base token after buy:", MockERC20(baseToken).balanceOf(address(this)));
}

function _sellIVToken(Currency token0, address ivToken, PoolSwapTest.TestSettings memory settings, bytes memory hookData) internal {
    bool baseIsToken0 = Currency.unwrap(token0) == baseToken;

    uint amount = MockERC20(ivToken).balanceOf(address(this));
    require(amount > 0, "Nothing to sell");

    MockERC20(ivToken).approve(address(swapRouter), amount);
    console.log("Selling IV token...");

    swapRouter.swap(
        key,
        IPoolManager.SwapParams({
            zeroForOne: !baseIsToken0, // iv to base
            amountSpecified: -(int256(amount)),
            sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
        }),
        settings,
        hookData
    );

    console.log("IV token after sell:", MockERC20(ivToken).balanceOf(address(this)));
    console.log("Base token after sell:", MockERC20(baseToken).balanceOf(address(this)));
}




}


/*

Limitations:
    1. ETH should be in token1 for the liquidity conversion to work correctly.(because it is static right now)
    12122106024


steps to test: 
anvil --fork-url https://ethereum-rpc.publicnode.com --chain-id 3133
forge test --fork-url http://localhost:8545 test/Vix.t.sol
 */


