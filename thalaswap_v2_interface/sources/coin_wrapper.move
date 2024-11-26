/// methods in pool.move assume all assets are in the form of fungible assets,
/// so add_liquidity(APT, 1000) simply check user's APT FA balance,
/// this can cause sad UX if user has 2000 APT Coin but 0 APT FA.
///
/// coin_wrapper aims to address this by always converting enough amount
/// of Coin to FA before calling into pool.move methods,
/// so that users have best chance of completing interactions with the pool module.
///
/// users should keep using coin_wrapper methods to interact with thalaswap_v2
/// until all coins are fully migrated to fungible assets (coin balance = 0).
module thalaswap_v2::coin_wrapper {
    use aptos_framework::object::Object;
    use aptos_framework::fungible_asset::Metadata;

    use thalaswap_v2::pool::Pool;

    /// A placeholder coin type for native FA assets such as native USDT.
    /// let's say we have a pool <APT, native USDT>, to add liquidity,
    /// we should call add_liquidity<APT, Notacoin>
    struct Notacoin {}

    const ERR_COIN_WRAPPER_COIN_FA_MISMATCH: u64 = 0;
    const ERR_COIN_WRAPPER_INSUFFICIENT_USER_BALANCE: u64 = 1;
    const ERR_COIN_WRAPPER_INSUFFICIENT_OUTPUT: u64 = 2;

    /// Creates a new weighted pool using coin balances, converting them to fungible assets as needed.
    ///
    /// Type Arguments:
    /// - `T0`, `T1`, `T2`, `T3`: The types of the coins corresponding to the fungible assets to be included in the pool.
    /// - `Notacoin`: A placeholder for "null" if < 6 assets are included in the pool. `Notacoin` can also be used if an asset has no CoinType.
    ///
    ///
    /// Parameters:
    /// - `user`: The signer creating the pool.
    /// - `assets_metadata`: Metadata for the assets to be included in the pool.
    /// - `amounts`: Initial amounts of each asset to deposit into the pool.
    /// - `weights`: Weights for each asset in the pool.
    /// - `swap_fee_bps`: The swap fee in basis points.
    ///
    /// Steps:
    /// 1. Derive corresponding fungible asset from coin types `T0`, `T1`, `T2`, `T3`.
    /// If coin type exists, use that to derive FA address if possible. Otherwise, use the passed in FA address
    /// 2. Calls the internal pool module to create the pool.
    /// 3. Deposits the resulting LP tokens back to the user's account.
    public entry fun create_pool_weighted<T0, T1, T2, T3>(
        _user: &signer,
        _assets_metadata: vector<Object<Metadata>>,
        _amounts: vector<u64>,
        _weights: vector<u64>,
        _swap_fee_bps: u64,
    ) {
        abort 0
    }

    /// Creates a new stable pool using coin balances, converting them to fungible assets as needed.
    ///
    /// Type Arguments:
    /// - `T0`, `T1`, `T2`, `T3`, `T4`, `T5`: The types of the coins corresponding to the assets to be included in the pool.
    /// - `Notacoin`: A placeholder for "null" if < 6 assets are included in the pool. `Notacoin` can also be used if an asset has no CoinType.
    ///
    /// Parameters:
    /// - `user`: The signer creating the pool.
    /// - `assets_metadata`: Metadata for the assets to be included in the pool.
    /// - `amounts`: Initial amounts of each asset to deposit into the pool.
    /// - `swap_fee_bps`: The swap fee in basis points.
    /// - `amp_factor`: The amplification factor for the stable pool.
    ///
    /// Steps:
    /// 1. Derive corresponding fungible asset from coin types `T0`, `T1`, `T2`, `T3`, `T4`, `T5`.
    /// If coin type exists, use that to derive FA address if possible. Otherwise, use the passed in FA address
    /// 2. Utilizes the pool module to create a stable pool.
    /// 3. Deposits the resulting LP tokens back to the user's account.
    public entry fun create_pool_stable<T0, T1, T2, T3, T4, T5>(
        _user: &signer,
        _assets_metadata: vector<Object<Metadata>>,
        _amounts: vector<u64>,
        _swap_fee_bps: u64,
        _amp_factor: u64,
    ) {
        abort 0
    }

    /// Adds liquidity to a weighted pool using coin balances, converting them to fungible assets as needed.
    ///
    /// Type Arguments:
    /// - `T0`, `T1`, `T2`, `T3`: The types of the coins corresponding to the assets being added to the pool.
    /// - `Notacoin`: A placeholder for "null" if < 6 assets are included in the pool. `Notacoin` can also be used if an asset has no CoinType.
    ///
    /// Parameters:
    /// - `user`: The signer adding liquidity.
    /// - `pool_obj`: The pool object where liquidity is being added.
    /// - `amounts`: Amounts of each asset to add to the pool.
    /// - `min_amount_out`: Minimum acceptable amount of LP tokens to receive to avoid transaction failure.
    ///
    /// Steps:
    /// 1. Derive corresponding fungible asset from coin types `T0`, `T1`, `T2`, `T3`.
    /// If coin type exists, use that to derive FA address if possible. Otherwise, use the passed in FA address
    /// 2. Calls the pool module to add liquidity with the converted assets.
    /// 3. Checks if the resulting LP tokens exceed the minimum threshold.
    /// 4. Deposits LP tokens and refunds any excess assets.
    public entry fun add_liquidity_weighted<T0, T1, T2, T3>(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _amounts: vector<u64>,
        _min_amount_out: u64,
    ) {
        abort 0
    }

    /// Adds liquidity to a stable pool using coin balances, converting them to fungible assets as needed.
    ///
    /// Type Arguments:
    /// - `T0`, `T1`, `T2`, `T3`, `T4`, `T5`: The types of the coins corresponding to the assets being added to the pool.
    /// - `Notacoin`: A placeholder for "null" if < 6 assets are included in the pool. `Notacoin` can also be used if an asset has no CoinType.
    ///
    /// Parameters:
    /// - `user`: The signer adding liquidity.
    /// - `pool_obj`: The pool object where liquidity is being added.
    /// - `amounts`: Amounts of each asset to add to the pool.
    /// - `min_amount_out`: Minimum acceptable amount of LP tokens to receive to avoid transaction failure.
    ///
    /// Steps:
    /// 1. Derive corresponding fungible asset from coin types `T0`, `T1`, `T2`, `T3`, `T4`, `T5`.
    /// If coin type exists, use that to derive FA address if possible. Otherwise, use the passed in FA address
    /// 2. Calls the pool module to add liquidity with the converted assets.
    /// 3. Ensures the resulting LP tokens meet the minimum threshold.
    /// 4. Deposits the LP tokens into the user's account.
    public entry fun add_liquidity_stable<T0, T1, T2, T3, T4, T5>(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _amounts: vector<u64>,
        _min_amount_out: u64,
    ) {
        abort 0
    }

    /// Executes an exact input swap in a weighted pool using coin balances, converting them as needed.
    ///
    /// Type Arguments:
    /// - `T`: The type of the coin corresponding to the input asset being swapped.
    ///
    /// Parameters:
    /// - `user`: The signer performing the swap.
    /// - `pool_obj`: The pool where the swap occurs.
    /// - `asset_metadata_in`: Metadata of the input asset.
    /// - `amount_in`: The exact amount of input asset for the swap.
    /// - `asset_metadata_out`: Metadata of the desired output asset.
    /// - `min_amount_out`: Minimum amount of the output asset to receive.
    ///
    /// Steps:
    /// 1. Converts the coin `T` to a fungible asset and deposits it.
    /// 2. Executes the swap using the pool module.
    /// 3. Ensures the output meets the user's minimum constraints.
    public entry fun swap_exact_in_weighted<T>(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _asset_metadata_in: Object<Metadata>,
        _amount_in: u64,
        _asset_metadata_out: Object<Metadata>,
        _min_amount_out: u64,
    ) {
        abort 0
    }

    /// Executes an exact input swap in a stable pool using coin balances, converting them as needed.
    ///
    /// Type Arguments:
    /// - `T`: The type of the coin corresponding to the input asset being swapped.
    ///
    /// Parameters:
    /// - `user`: The signer performing the swap.
    /// - `pool_obj`: The pool where the swap occurs.
    /// - `asset_metadata_in`: Metadata of the input asset.
    /// - `amount_in`: The exact amount of input asset for the swap.
    /// - `asset_metadata_out`: Metadata of the desired output asset.
    /// - `min_amount_out`: Minimum amount of the output asset to receive.
    ///
    /// Steps:
    /// 1. Converts the coin `T` to a fungible asset and deposits it.
    /// 2. Executes the swap using the pool module.
    /// 3. Verifies the output against the minimum amount.
    public entry fun swap_exact_in_stable<T>(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _asset_metadata_in: Object<Metadata>,
        _amount_in: u64,
        _asset_metadata_out: Object<Metadata>,
        _min_amount_out: u64,
    ) {
        abort 0
    }

    /// Executes a swap to receive an exact amount of an asset in a weighted pool using coin balances.
    ///
    /// Type Arguments:
    /// - `T`: The type of the coin corresponding to the input asset being swapped.
    ///
    /// Parameters:
    /// - `user`: The signer performing the swap.
    /// - `pool_obj`: The pool where the swap occurs.
    /// - `asset_metadata_in`: Metadata of the input asset.
    /// - `max_amount_in`: The maximum amount of input asset allowable for the swap.
    /// - `asset_metadata_out`: Metadata of the desired exact output asset.
    /// - `amount_out`: The exact amount of output asset desired.
    ///
    /// Steps:
    /// 1. Converts user's coin `T` to a fungible asset up to the maximum input.
    /// 2. Performs the exact output swap via the pool module.
    /// 3. Manages any potential refunds.
    public entry fun swap_exact_out_weighted<T>(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _asset_metadata_in: Object<Metadata>,
        _max_amount_in: u64,
        _asset_metadata_out: Object<Metadata>,
        _amount_out: u64,
    ) {
        abort 0
    }

    /// Executes a swap to receive an exact amount of an asset in a stable pool using coin balances.
    ///
    /// Type Arguments:
    /// - `T`: The type of the coin corresponding to the input asset being swapped.
    ///
    /// Parameters:
    /// - `user`: The signer performing the swap.
    /// - `pool_obj`: The pool where the swap occurs.
    /// - `asset_metadata_in`: Metadata of the input asset.
    /// - `max_amount_in`: The maximum amount of input asset allowable for the swap.
    /// - `asset_metadata_out`: Metadata of the desired exact output asset.
    /// - `amount_out`: The exact amount of output asset desired.
    ///
    /// Steps:
    /// 1. Converts user's coin `T` to a fungible asset up to the maximum input.
    /// 2. Executes the stable pool swap for the exact output.
    /// 3. Handles any excess input refund.
    public entry fun swap_exact_out_stable<T>(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _asset_metadata_in: Object<Metadata>,
        _max_amount_in: u64,
        _asset_metadata_out: Object<Metadata>,
        _amount_out: u64,
    ) {
        abort 0
    }
}
