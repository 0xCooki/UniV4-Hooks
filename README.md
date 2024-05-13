# Uniswap V4 Hooks

A repository for Uniswap V4 hooks. Built using [Foundry](https://book.getfoundry.sh/).

### Hooks

##### Counter

A counter hook that simply counts each added liquidity, removed lquidity, swap, and donate call to a pool.

##### Receipt

This hook is also an ERC1155 contract that mints an NFT after each swap performed on a pool. The NFT meta-data is stored off-chain, although a version could be created that stores and renders the receipt information on-chain also (this would be expensive to deploy to Ethereum mainnet however).

### Utilities

Ancillary utilities used in testing and creation of the hooks.

##### Awesome Uniswap Hooks

This [Awesome Uniswap Hooks](https://github.com/ora-io/awesome-uniswap-hooks) repo contains an extensive list of Hook resources

##### Hook Address Miner

This contract library can be used to mine addresses for Uniswap V4 hooks. This is necessary because the leading bits of the hook contract address determine which kind of hooks are invoked when a swap is performed.