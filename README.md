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

  DiamondCutFacet:        0xc562e12eC6Fc842FC729d1d37274A34483Ce180e
  DiamondLoupeFacet:      0x1692e2E1c580cCaaaC4F3D2b44a2AC1EE10e7B3D
  OwnershipFacet:         0x5Ec444910Add57E5715Cb7a25702903FdA5c58D5
  ValidationFacet:        0xE3545DF9c2d3fA766196a1886173E1b66e17D0f7
  OwnerValidationModule:  0x3A88f91D0812a2370c7F4Bd6605676ADdDBcC44B
  DiamondFactory deployed at: 0x46c30d20098EE751A1EA9eFb12a5619A7f2E54c3