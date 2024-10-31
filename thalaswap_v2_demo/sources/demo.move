module thalaswap_v2_demo::demo {
    use std::signer;
    use std::vector;

    use aptos_framework::fungible_asset::{Self, FungibleAsset, Metadata};
    use aptos_framework::object::Object;
    use aptos_framework::primary_fungible_store;

    use thalaswap_v2_interface::coin_wrapper;
    use thalaswap_v2_interface::pool::{Self, Pool};


    // Coin Wrapper Methods

    public fun create_pool_weighted_coin<T0, T1, T2, T3>(
        user: &signer,
        assets_metadata: vector<Object<Metadata>>,
        amounts: vector<u64>,
        weights: vector<u64>,
        swap_fee_bps: u64,
    ) {
        coin_wrapper::create_pool_weighted<T0, T1, T2, T3>(
            user,
            assets_metadata,
            amounts,
            weights,
            swap_fee_bps
        );
    }

    public fun add_liquidity_weighted_coin<T0, T1, T2, T3>(
        user: &signer,
        pool_obj: Object<Pool>,
        amounts: vector<u64>,
        min_amount_out: u64,
    ) {
        coin_wrapper::add_liquidity_weighted<T0, T1, T2, T3>(
            user,
            pool_obj,
            amounts,
            min_amount_out
        );
    }

    public fun swap_exact_in_weighted_coin<T>(
        user: &signer,
        pool_obj: Object<Pool>,
        asset_metadata_in: Object<Metadata>,
        amount_in: u64,
        asset_metadata_out: Object<Metadata>,
        min_amount_out: u64,
    ) {
        coin_wrapper::swap_exact_in_weighted<T>(
            user,
            pool_obj,
            asset_metadata_in,
            amount_in,
            asset_metadata_out,
            min_amount_out
        );
    }

    public fun swap_exact_out_weighted_coin<T>(
        user: &signer,
        pool_obj: Object<Pool>,
        asset_metadata_in: Object<Metadata>,
        max_amount_in: u64,
        asset_metadata_out: Object<Metadata>,
        amount_out: u64,
    ) {
        coin_wrapper::swap_exact_out_weighted<T>(
            user,
            pool_obj,
            asset_metadata_in,
            max_amount_in,
            asset_metadata_out,
            amount_out
        );
    }

    // Fungible Asset Methods

    public fun create_pool_weighted(
        user: &signer,
        assets_metadata: vector<Object<Metadata>>,
        amounts: vector<u64>,
        weights: vector<u64>,
        swap_fee_bps: u64,
    ) {
        let assets = vector::empty();
        vector::zip(assets_metadata, amounts, |metadata, amount| {
            if (amount != 0) {
                let asset = primary_fungible_store::withdraw(user, metadata, amount);
                vector::push_back(&mut assets, asset);
            } else {
                vector::push_back(&mut assets, fungible_asset::zero(metadata));
            }
        });
        let (_, lp_token) = pool::create_pool_weighted(assets, weights, swap_fee_bps);
        primary_fungible_store::deposit(signer::address_of(user), lp_token);
    }

    public fun add_liquidity_weighted(
        user: &signer,
        pool_obj: Object<Pool>,
        assets: vector<FungibleAsset>,
    ) {
        let (lp_token, refunds) = pool::add_liquidity_weighted(pool_obj, assets);

        primary_fungible_store::deposit(signer::address_of(user), lp_token);
        vector::for_each(refunds, |refund| {
            primary_fungible_store::deposit(signer::address_of(user), refund);
        });
    }

    public fun remove_liquidity(
        user: &signer,
        pool_obj: Object<Pool>,
        lp_token: FungibleAsset,
    ) {
        let assets = pool::remove_liquidity(pool_obj, lp_token);

        vector::for_each(assets, |asset| {
            primary_fungible_store::deposit(signer::address_of(user), asset);
        });
    }

    public fun swap_exact_in_weighted(
        user: &signer,
        pool_obj: Object<Pool>,
        asset_metadata_in: Object<Metadata>,
        amount_in: u64,
        asset_metadata_out: Object<Metadata>,
    ) {
        let asset_in = primary_fungible_store::withdraw(user, asset_metadata_in, amount_in);
        let asset_out = pool::swap_exact_in_weighted(user, pool_obj, asset_in, asset_metadata_out);

        primary_fungible_store::deposit(signer::address_of(user), asset_out);
    }

    public fun swap_exact_out_weighted(
        user: &signer,
        pool_obj: Object<Pool>,
        asset_metadata_in: Object<Metadata>,
        amount_in: u64,
        asset_metadata_out: Object<Metadata>,
        amount_out: u64,
    ) {
        let asset_in = primary_fungible_store::withdraw(user, asset_metadata_in, amount_in);
        let (refund, asset_out) = pool::swap_exact_out_weighted(user, pool_obj, asset_in, asset_metadata_out, amount_out);

        primary_fungible_store::deposit(signer::address_of(user), refund);
        primary_fungible_store::deposit(signer::address_of(user), asset_out);
    }
}