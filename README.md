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

  DiamondCutFacet:        0x530cEDC71065c7C99D75Ff92A06224344E994DF6
  DiamondLoupeFacet:      0x463958828FF2157862540A7Cb11240Dc76E80c7a
  OwnershipFacet:         0x902dF657ca8E3389F11C6886A98ac58586986ae6
  ValidationFacet:        0xbB26aFc03112D60B74111d2157fd61CE61EbB3dC
  OwnerValidationModule:  0x26B3190Ffd4e4E3bDF7bDD687B68db115654E102
  DiamondFactory deployed at: 0x62C78c7E4dd26214eA44617Fa9cDd6F285d24C7A