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

  DiamondLoupeFacet:      0x69238e56411524FeB5E0C700221A916d4A98FBe7
  OwnershipFacet:         0xCeD152Ea769b1740feEcCDa959e9C45C99227d47
  ValidationFacet:        0xaE78271d68274F6Dc5d49C0f5557f2C0c465Dbd9
  OwnerValidationFacet:  0x7002E6f18f240f8e2209d3209D061a6E1E1bE977
  DiamondFactory deployed at: 0xC95776A97661A21d86FA1Bb9b9fF6934E15BF1AF

## Optional Modules

forge script script/DeployBasicWalletFacet.s.sol:DeployBasicWalletFacet \
  --fork-url hypercore \
  --broadcast \
  --legacy

  BasicWalletFacet deployed at: 0x79e2fa7763C4D1884f6a6D98b51220eD79fC4484