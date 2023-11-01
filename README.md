# Fuzz, Invariant and Differential Tests Using Foundry

## Requirements

Running these tests requires the following:

- Python 3.10+
  - Packages: `pip install eth_abi`
- [Foundry](https://github.com/foundry-rs)
- [zkSync Foundry](https://github.com/matter-labs/foundry-zksync)

## Usage

This repo contains examples of advanced testing using Foundry. To run these tests using Forge to see expected behavior, follow these steps (one test should fail): 

1. Clone this repo and navigate to the project root directory
2. Run `forge test`

To run these tests using zkSync Foundry, run the following from project root (test output should match that of Forge above):

```sh
zkforge test
```
