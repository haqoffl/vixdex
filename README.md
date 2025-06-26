# Vixdex

VixDex - Decentralized Volatility Trading Protocol

### uniswap prize winner hook in atrium academy UHI-4

## About this Project
VixDex is a decentralized volatility trading protocol. It is a Uniswap V4 hook that introduces a custom pricing model for trading directly on volatility on-chain. VixDex allows traders to take positions on whether an asset’s volatility will increase or decrease, similar to VIX options trading but in a fully decentralized and automated manner.


## How it Works
Traders can buy:

HIGH-IV Tokens → Value increases when IV is high.

LOW-IV Tokens → Value increases when IV is low.

Positions expire in 24H or 7D, and at the end of each cycle, new tokens are minted.

Price is mostly influenced by IV, with minor adjustments from supply and demand.

HIGH-IV and LOW-IV tokens are inversely correlated—when one increases, the other decreases.


## 🛠️ Key Features

✅ No Liquidity Providers (LPs) Needed – The contract itself manages token issuance and pricing.

✅ Uniswap V3 Integration – The contract retrieves data from Uniswap V3, performs IV-related calculations, and executes trades fully on-chain.

✅ Customizable Pricing Curve – The mechanism determining token prices may evolve to optimize efficiency.

✅ Automated Market Reset – Every 24H/7D, positions expire, and new IV tokens are issued.

✅ Fully On-Chain & Decentralized – Built on Ethereum & Uniswap V4 hooks.

## ⚙️ Design

   The Uniswap V4 hook is deployed as a No-Op hook that overrides specific permissions on the Uniswap V4 pool manager. The following hooks are overridden:

   `beforeAddLiquidity`

   `beforeSwap`

   `afterSwap`

   `beforeSwapReturnDelta`


# Vixdex Setup Guide

## Installation

### Step 1: Clone This Repository


`git clone https://github.com/vixdex/vixdex.git`
`cd /hooks`

### Step 2: Install Required Dependencies

#### Install Uniswap libraries:

````
```
forge install https://github.com/Uniswap/v4-core
forge install https://github.com/Uniswap/v4-periphery
forge install uniswap/v3-periphery
forge install uniswap/v3-core
forge install uniswap/permit2
forge install uniswap/universal-router
forge install uniswap/v2-periphery
forge install uniswap/v2-core

```
````

#### Install OpenZeppelin:

`forge install OpenZeppelin/openzeppelin-contracts`

#### Install Huff compiler integration

before this step, install huff compiler.

`forge install huff-language/foundry-huff`

### Step 3: Run Forked Sepolia Network

#### We’ll use anvil to fork the Ethereum Sepolia/Mainnet network:

`anvil --fork-url https://ethereum-rpc.publicnode.com --chain-id 3133`


💡 Use a unique chain ID not used by other networks to avoid MetaMask conflicts when working in client side.

### Step 4: Deploy Huff Contract (Bonding Curve)

`huffc src/BondingCurve.huff -b`

Deploy with bytecode:
`cast send --rpc-url <url> --private-key <private_key> --create 0x<bytecode>`

This returns the BondingCurve contract address. Update your test or deployment contracts with this address.

### Step 5: Deploy Volume Oracle

1. Clone the vixdex-volume-oracle-node repository.

2. Inside /node, install dependencies:

`npm install`
in .env change it according to yours!.


````
```
GEKO_TERMINAL_URL="https://api.geckoterminal.com/api/v2/"
MONGO_URI="mongodb://localhost:27017/vixdexFinance"
RPC_URL="http://localhost:8545"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" # Replace this with your bonding curve address
ORACLE_CONTRACT="0xAa07486C20F73fF4309495411927E6AE7C884DBa" # Replace after deploy
```
````

### Step 6: Deploy Oracle Contract Using Truffle

#### Go to /oracle, configure truffle-config.js for local development, then

`truffle deploy`

#### Update .env with the new oracle contract address.

### Step 7: Start the Node Server

cd node
npx nodemon index.js

### Step 8: Test Oracle API

#### Use Postman or terminal:

    URL: http://localhost:8000/volume/uniswapV3/pool/oracle

    Body:

   ````
   ```
{
  "chain": "eth", <your fav network>
  "poolAddress": "0xCBCdF9626bC03E24f779434178A73a0B4bad62eD" <your fav uniswap v3 pool>
}


   ```
   ````
   You’ll receive an array of volume data. Now your oracle contract is ready.
### Step 9: Final Contract Testing & Deployment

With both BondingCurve and Volume Oracle contracts ready:

Update your smart contract variables.

Happy coding :)

## 🛠️ Deployments

### 🌐 Sepolia Testnet

| Contract           | Address                                                                 |
|--------------------|--------------------------------------------------------------------------|
| Swap Router        | `0x5822A01d9465ce997e652ff592d0dB9604ef3dc1`                             |
| Huff Bonding Curve | `0xCa7FF6ad2e29cc407E399946c0E4e62cca18B730`                             |
| Vixdex Hook        | `0xa8378271B8b7394A8D2AABf47fEE58a4c1FdC8c8`                             |
| Volume Oracle      | *(See contract address in `vixdex-volume-oracle-node` repo)*            |


## 📄 Whitepaper

You can find the official Vixdex whitepaper in the following Google Drive folder:

🔗 [View Whitepaper Folder](https://drive.google.com/file/d/1HRLXA0EMePYPyHbVvtZ-cdS1K0VnBSKP/view?usp=sharing)


## 📬 Contact

If you have any questions, feedback, or are interested in contributing, feel free to reach out:

- 📧 Vixdex Official Email: [social@vixdex.finance](mailto:social@vixdex.finance)  
- 🐦 Twitter: [@vixdex_finance](https://x.com/vixdex_finance)

## ⚠️ Disclaimer

**Vixdex is currently under active development and is not yet production-ready but lauch in mid june on testnet**

This project **has not been audited**, and may contain bugs, vulnerabilities, or unintended behaviors. By using any part of this repository or interacting with its deployed contracts, you do so **at your own risk*