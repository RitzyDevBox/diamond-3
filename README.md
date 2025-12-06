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


## Existing Deployments:

  DiamondCutFacet:        0xEF692792B764d482B59bF4A2E102553a12e33cB5
  DiamondLoupeFacet:      0xb9c4ec659666888fB01bA89B8c889eE33c280AB4
  OwnershipFacet:         0x119dA5fD2d8Fd0C62e9F9b3827F0E28A89bB151E
  ValidationFacet:        0x9eca556E7A08822A710b1c22B375a2C81a6d7ecC
  OwnerValidationFacet:  0xf99728FCD046Dd3D2Ff82aD2C42f186E8cF27d36
  DiamondFactory deployed at: 0xA2156c50c876cA57efF74f1646bC642a74e06a64
