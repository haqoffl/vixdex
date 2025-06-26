// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.26;
interface IMinimalUniswapV3Pool {
    function liquidity() external view returns (uint128);
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
    function tickSpacing() external view returns (int24);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function setTickAndLiq(uint128 liquidity_,int24 tick_) external;
}

contract MockUniswapV3Pool is IMinimalUniswapV3Pool {
    uint128 private _liquidity;
    int24 private _tick;
    int24 private _tickSpacing;
    address private _token0;
    address private _token1;
    uint24 private _fee;
    address private _realPoolAddress;

    constructor(
        uint128 liquidity_,
        int24 tick_,
        int24 tickSpacing_,
        address token0_,
        address token1_,
        uint24 fee_,
        address realPoolAddress_ 
    ) {
        _liquidity = liquidity_;
        _tick = tick_;
        _tickSpacing = tickSpacing_;
        _token0 = token0_;
        _token1 = token1_;
        _fee = fee_;
        _realPoolAddress = realPoolAddress_;
    }

    function liquidity() external view override returns (uint128) {
        return _liquidity;
    }

    function slot0() external view override returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    ) {
        // Return mocked values
        return (0, _tick, 0, 0, 0, 0, true);
    }

    function tickSpacing() external view override returns (int24) {
        return _tickSpacing;
    }

    function token0() external view override returns (address) {
        return _token0;
    }

    function token1() external view override returns (address) {
        return _token1;
    }

    function fee() external view override returns (uint24) {
        return _fee;
    }
    

    // Add any other mocked methods as needed.

    function getRealPoolAddress() external view returns (address) {
        // This function is not part of the IUniswapV3Pool interface, but can be added for testing purposes.
        return _realPoolAddress;
    }

    function setTickAndLiq(
        uint128 liquidity_,
        int24 tick_
    ) external {
        _liquidity = liquidity_;
        _tick = tick_;
    }


}
