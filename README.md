# Uniswap V4 Hooks

A repository for Uniswap V4 hooks. Built using [Foundry](https://book.getfoundry.sh/).

### Hooks

TBD

### Utilities

Ancillary utilities used in testing and creation of the hooks.

#### Hook Address Miner

This contract library can be used to mine addresses for Uniswap V4 hooks. This is necessary because the leading bits of the hook contract address determine which kind of hooks are invoked when a swap is performed.