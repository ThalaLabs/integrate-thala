module thalaswap_v1_demo::demo {
    use std::signer;

    use aptos_framework::coin::{Self, Coin};

    use thalaswap_v1_interface::stable_pool::{Self, StablePoolToken};
    use thalaswap_v1_interface::weighted_pool::{Self, WeightedPoolToken};

    use thalaswap_v1_interface::stable_pool_scripts;
    use thalaswap_v1_interface::weighted_pool_scripts;


    // Weighted Script Methods

    public entry fun create_pool_weighted_entry<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
        user: &signer,
        in_0: u64,
        in_1: u64,
        in_2: u64,
        in_3: u64
    ) {
        weighted_pool_scripts::create_weighted_pool<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
            user,
            in_0,
            in_1,
            in_2,
            in_3
        );
    }

    public fun add_liquidity_weighted_entry<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
        user: &signer,
        in_0: u64,
        in_1: u64,
        in_2: u64,
        in_3: u64,
        min_amount_in_0: u64,
        min_amount_in_1: u64,
        min_amount_in_2: u64,
        min_amount_in_3: u64
    ) {
        weighted_pool_scripts::add_liquidity<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
            user,
            in_0,
            in_1,
            in_2,
            in_3,
            min_amount_in_0,
            min_amount_in_1,
            min_amount_in_2,
            min_amount_in_3
        );
    }

    public fun remove_liquidity_weighted_entry<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
        user: &signer,
        lp_token_in: u64,
        min_amount_out_0: u64,
        min_amount_out_1: u64,
        min_amount_out_2: u64,
        min_amount_out_3: u64,
    ) {
        weighted_pool_scripts::remove_liquidity<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
            user,
            lp_token_in,
            min_amount_out_0,
            min_amount_out_1,
            min_amount_out_2,
            min_amount_out_3
        );
    }

    public fun swap_exact_in_weighted_entry<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(
        user: &signer,
        amount_in: u64,
        min_amount_out: u64,
    ) {
        weighted_pool_scripts::swap_exact_in<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(
            user,
            amount_in,
            min_amount_out
        );
    }

    public fun swap_exact_out_weighted_entry<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(
        user: &signer,
        max_amount_in: u64,
        amount_out: u64,
    ) {
        weighted_pool_scripts::swap_exact_out<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(
            user,
            max_amount_in,
            amount_out
        );
    }

    // Stable Script Methods

    public entry fun create_pool_stable_entry<Asset0, Asset1, Asset2, Asset3>(
        user: &signer,
        in_0: u64,
        in_1: u64,
        in_2: u64,
        in_3: u64,
        amp_factor: u64,
    ) {
        stable_pool_scripts::create_stable_pool<Asset0, Asset1, Asset2, Asset3>(
            user,
            in_0,
            in_1,
            in_2,
            in_3,
            amp_factor
        );
    }

    public fun add_liquidity_stable_entry<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
        user: &signer,
        in_0: u64,
        in_1: u64,
        in_2: u64,
        in_3: u64,
    ) {
        stable_pool_scripts::add_liquidity<Asset0, Asset1, Asset2, Asset3>(
            user,
            in_0,
            in_1,
            in_2,
            in_3
        );
    }

    public fun remove_liquidity_stable_entry<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
        user: &signer,
        lp_token_in: u64,
        min_amount_out_0: u64,
        min_amount_out_1: u64,
        min_amount_out_2: u64,
        min_amount_out_3: u64,
    ) {
        stable_pool_scripts::remove_liquidity<Asset0, Asset1, Asset2, Asset3>(
            user,
            lp_token_in,
            min_amount_out_0,
            min_amount_out_1,
            min_amount_out_2,
            min_amount_out_3
        );
    }

    public fun swap_exact_in_stable_entry<Asset0, Asset1, Asset2, Asset3, X, Y>(
        user: &signer,
        amount_in: u64,
        min_amount_out: u64,
    ) {
        stable_pool_scripts::swap_exact_in<Asset0, Asset1, Asset2, Asset3, X, Y>(
            user,
            amount_in,
            min_amount_out
        );
    }

    public fun swap_exact_out_stable_entry<Asset0, Asset1, Asset2, Asset3, X, Y>(
        user: &signer,
        max_amount_in: u64,
        amount_out: u64,
    ) {
        stable_pool_scripts::swap_exact_out<Asset0, Asset1, Asset2, Asset3, X, Y>(
            user,
            max_amount_in,
            amount_out
        );
    }

    // Weighted Methods

    public fun create_weighted_pool<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
        user: &signer,
        asset_0: Coin<Asset0>,
        asset_1: Coin<Asset1>,
        asset_2: Coin<Asset2>,
        asset_3: Coin<Asset3>
    ) {
        weighted_pool::create_weighted_pool<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
            user,
            asset_0,
            asset_1,
            asset_2,
            asset_3
        );
    }

    public fun add_liquidity_weighted<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
        user: &signer,
        coin_0: Coin<Asset0>,
        coin_1: Coin<Asset1>,
        coin_2: Coin<Asset2>,
        coin_3: Coin<Asset3>
    ) {
        let (lp_token, refund_0, refund_1, refund_2, refund_3) = weighted_pool::add_liquidity<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(coin_0, coin_1, coin_2, coin_3);

        coin::deposit(signer::address_of(user), lp_token);
        coin::deposit(signer::address_of(user), refund_0);
        coin::deposit(signer::address_of(user), refund_1);
        coin::deposit(signer::address_of(user), refund_2);
        coin::deposit(signer::address_of(user), refund_3);
    }

    public fun remove_liquidity_weighted<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
        user: &signer,
        lp_token: Coin<WeightedPoolToken<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>>,
    ) {
        let (asset_0, asset_1, asset_2, asset_3) = weighted_pool::remove_liquidity(lp_token);

        coin::deposit(signer::address_of(user), asset_0);
        coin::deposit(signer::address_of(user), asset_1);
        coin::deposit(signer::address_of(user), asset_2);
        coin::deposit(signer::address_of(user), asset_3);
    }

    public fun swap_exact_in_weighted<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(
        user: &signer,
        amount_in: u64,
    ) {
        let asset_in = coin::withdraw<X>(user, amount_in);
        let asset_out = weighted_pool::swap_exact_in<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(asset_in);

        coin::deposit(signer::address_of(user), asset_out);
    }

    public fun swap_exact_out_weighted<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(
        user: &signer,
        amount_in: u64,
        amount_out: u64,
    ) {
        let asset_in = coin::withdraw<X>(user, amount_in);
        let (refund, asset_out) = weighted_pool::swap_exact_out<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(asset_in, amount_out);

        coin::deposit(signer::address_of(user), refund);
        coin::deposit(signer::address_of(user), asset_out);
    }

    // Stable Methods

    public fun create_stable_pool<Asset0, Asset1, Asset2, Asset3>(
        user: &signer,
        asset_0: Coin<Asset0>,
        asset_1: Coin<Asset1>,
        asset_2: Coin<Asset2>,
        asset_3: Coin<Asset3>,
        amp_factor: u64,
    ) {
        stable_pool::create_stable_pool<Asset0, Asset1, Asset2, Asset3>(
            user,
            asset_0,
            asset_1,
            asset_2,
            asset_3,
            amp_factor
        );
    }

    public fun add_liquidity_stable<Asset0, Asset1, Asset2, Asset3>(
        user: &signer,
        coin_0: Coin<Asset0>,
        coin_1: Coin<Asset1>,
        coin_2: Coin<Asset2>,
        coin_3: Coin<Asset3>
    ) {
        let lp_token = stable_pool::add_liquidity<Asset0, Asset1, Asset2, Asset3>(coin_0, coin_1, coin_2, coin_3);

        coin::deposit(signer::address_of(user), lp_token);
    }

    public fun remove_liquidity_stable<Asset0, Asset1, Asset2, Asset3>(
        user: &signer,
        lp_token: Coin<StablePoolToken<Asset0, Asset1, Asset2, Asset3>>,
    ) {
        let (asset_0, asset_1, asset_2, asset_3) = stable_pool::remove_liquidity(lp_token);

        coin::deposit(signer::address_of(user), asset_0);
        coin::deposit(signer::address_of(user), asset_1);
        coin::deposit(signer::address_of(user), asset_2);
        coin::deposit(signer::address_of(user), asset_3);
    }

    public fun swap_exact_in_stable<Asset0, Asset1, Asset2, Asset3, X, Y>(
        user: &signer,
        amount_in: u64,
    ) {
        let asset_in = coin::withdraw<X>(user, amount_in);
        let asset_out = stable_pool::swap_exact_in<Asset0, Asset1, Asset2, Asset3, X, Y>(asset_in);

        coin::deposit(signer::address_of(user), asset_out);
    }

    public fun swap_exact_out_stable<Asset0, Asset1, Asset2, Asset3, X, Y>(
        user: &signer,
        amount_in: u64,
        amount_out: u64,
    ) {
        let asset_in = coin::withdraw<X>(user, amount_in);
        let (refund, asset_out) = stable_pool::swap_exact_out<Asset0, Asset1, Asset2, Asset3, X, Y>(asset_in, amount_out);

        coin::deposit(signer::address_of(user), refund);
        coin::deposit(signer::address_of(user), asset_out);
    }
}