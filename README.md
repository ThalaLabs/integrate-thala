# ThalaSwap Integration

This repo is to help you integrate with ThalaSwap and/or ThalaProtocol. There are 2 steps:
1. Copy the interface directory to your project. Example: `cp -r thalaswap_v1_interface my_project/`
2. In your project, import it and use the methods provided. See any of the demo projects for examples (e.g. [`/thalaswap_v1_demo`](./thalaswap_v1_demo/) or [`/thalaswap_v2_demo`](./thalaswap_v2_demo/)).

## Contract addresses

ThalaSwapV1: https://explorer.aptoslabs.com/account/0x48271d39d0b05bd6efca2278f22277d6fcc375504f9839fd73f74ace240861af?network=mainnet

ThalaSwapV2: https://explorer.aptoslabs.com/account/0x007730cd28ee1cdc9e999336cbc430f99e7c44397c0aa77516f6f23a78559bb5/transactions?network=mainnet

ThalaSwapLens: https://explorer.aptoslabs.com/account/0xff1ac437457a839f7d07212d789b85dd77b3df00f59613fcba02388464bfcacb/transactions?network=mainnet

TODO: Add ThalaProtocol
ThalaProtocol: ...

## ThalaSwap V1 Concepts

### Pools (Base/Stable/Weighted)

[`base_pool`](./thalaswap_v1_interface/sources/base_pool.move) covers common amm pool type parameters.

[`stable_pool`](./thalaswap_v1_interface/sources/stable_pool.move) covers core stable pool amm logic.

[`weighted_pool`](./thalaswap_v1_interface/sources/weighted_pool.move) covers core weighted pool amm logic.

Each pool, weighted or stable, is its own resource under the ThalaSwapv1 resource account, `48271d39d0b05bd6efca2278f22277d6fcc375504f9839fd73f74ace240861af`

Pools are indexed via type params consisting of pool asset & pool weight types. Pool weights are supported in increments of `5`.

## ThalaSwap V2 Concepts

### Pool

[`pool`](./thalaswap_v2_interface/sources/pool.move) covers core amm logic assuming Fungible Assets.

Each pool, either weighed pool or stable pool, is its own object. Pool addresses
can be found in either `ThalaSwapV2::pool::pools()` or `ThalaSwapLens::lens::get_pools_info()`.

### Coin Wrapper

While `pool` covers core amm logic assuming Fungible Assets, any coin-specific logic
is left for [`coin_wrapper`](./thalaswap_v2_interface/coin_wrapper.move).

An example is creating a weighted pool. In `pool`, we have a method that
takes in FA metadata as input arguments:

```
public entry fun create_pool_weighted_entry(
    user: &signer,
    assets_metadata: vector<Object<Metadata>>,
    ...
)
```

In `coin_wrapper`, a corresponding method that takes in generic type args can be found:

```
public entry fun create_pool_weighted<T0, T1, T2, T3>(
    user: &signer,
    assets_metadata: vector<Object<Metadata>>,
    ...
)
```

For a Coin asset, make sure to pass in the right type arguments and `0xa` as a placeholder in `assets_metadata`.
For a Fungible Asset without a coin type, make sure to pass in
`0x007730cd28ee1cdc9e999336cbc430f99e7c44397c0aa77516f6f23a78559bb5::coin_wrapper::Notacoin`
as the type argument, and the FA metadata in `assets_metadata`. For example:

- THL: T = 0x7fd500c11216f0fe3095d0c4b8aa4d64a4e2e04f83758462f2b127255643615::thl_coin::THL, asset_metadata = 0xa (0xa is a placeholder)
- USDt: T = 0x007730cd28ee1cdc9e999336cbc430f99e7c44397c0aa77516f6f23a78559bb5::coin_wrapper::Notacoin, asset_metadata = 0x357b0b74bc833e95a115ad22604854d6b0fca151cecd94111770e5d6ffc9dc2b

## ThalaProtocol Concepts

### PSM V2

[`psm_v2`](./thalaprotocol_interface/sources/psm_v2.move) covers core PSM mint and redeem logic.

Each PSM is its own object. PSM address for a given exchange asset can be found using `ThalaProtocol::psm_v2::psm_address(exchange_asset_metadata)`.
