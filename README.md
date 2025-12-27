## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
### Deploying Diamond Facotry:

forge script script/deployDiamondFactory.s.sol:DeployDiamondFactory \
  --fork-url hypercore \
  --broadcast \
  --legacy


## Initial Modules Deployments:

  DiamondCutFacet:        0x95d2EF6bbf1731E909F3D8Bf8DAec28AF7B5AE38
  DiamondLoupeFacet:      0x37f36f667F33C3FCF725Bc7B87b3B6fA358f5C6e
  ValidationFacet:        0x1F26Cf678bd526196E2D8497e464774484518069
  executeFacet:           0x0954FDfEba0F89A9e9B776d897dddf4e26FcA3Da
  OwnerAuthorityResolver:  0x7E2a43DD6b95c518a5248fD5a2A57315D767499b
  NFTAuthorityResolver:  0xFA565823BF266B26F7cA44C2C305BB303C89b63a
  DiamondFactory deployed at: 0x270EEF348212855eCb43374cEAfE012FA8c12B4e

## Generating Abi's

  jq '.abi' out/Diamond.sol/Diamond.json > abis/Diamond.abi.json
  jq '.abi' out/DiamondFactory.sol/DiamondFactory.json > abis/DiamondFactory.abi.json
  jq '.abi' out/DiamondCutFacet.sol/DiamondCutFacet.json > abis/DiamondCutFacet.abi.json
  jq '.abi' out/DiamondLoupeFacet.sol/DiamondLoupeFacet.json > abis/DiamondLoupeFacet.abi.json
  jq '.abi' out/ExecuteFacet.sol/ExecuteFacet.json > abis/ExecuteFacet.abi.json

  

## Optional Modules


forge script script/DeployOpenMintERC20.s.sol:DeployOpenMintERC20   --fork-url hypercore   --broadcast   --legacy

    OpenMintERC20 deployed at: 0x8900E4FCd3C2e6d5400fdE29719Eb8b5fc811b3c
    Name:      OpenMint
    Symbol:    OM20
    Decimals:  18

forge script script/MintOpenMintERC20.s.sol:MintOpenMintERC20 \
  --fork-url hypercore \
  --broadcast \
  --legacy
