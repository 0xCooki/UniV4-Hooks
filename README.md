# Uniswap V4 Hooks

A repository for Uniswap V4 hooks. Built using [Foundry](https://book.getfoundry.sh/).

## Hooks

#### Counter

A counter [hook](./contracts/Hooks/CounterHook.sol) that simply counts each added liquidity, removed lquidity, swap, and donate call to a pool.

#### Receipt

This [hook](./contracts/Hooks/ReceiptHook.sol) is also an ERC1155 contract that mints an NFT after each swap performed on a pool. The NFT meta-data is stored off-chain, although a version could be created that stores and renders the receipt information on-chain also (this would be expensive to deploy to Ethereum mainnet however).

### Ownership Allowlist

Three seperate [hook](./contracts/Hooks/OwnershipAllowlistHooks.sol) contracts that restrict access to adding liquidity, swapping, and donating to a pool based on a defined token ownership of ERC20, ERC721, and ERC1155 tokens respectively.

## Utilities

Ancillary utilities used in testing and creation of the hooks.

### Awesome Uniswap Hooks

This [Awesome Uniswap Hooks](https://github.com/ora-io/awesome-uniswap-hooks) repo contains an extensive list of Hook resources.

### Hook Address Miner

This [contract library](./contracts/libraries/HookAddressMiner.sol) can be used to mine addresses for Uniswap V4 hooks. This is necessary because the leading bits of the hook contract address determine which kind of hooks are invoked when a swap is performed.