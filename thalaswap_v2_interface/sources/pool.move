module thalaswap_v2::pool {
    use std::option::Option;

    use aptos_framework::fungible_asset::{BurnRef, FungibleAsset, Metadata, MintRef, TransferRef};
    use aptos_framework::object::{ExtendRef, Object};

    // Defaults

    const DEFAULT_FLASHLOAN_FEE_BPS: u64 = 1;
    const DEFAULT_SWAP_FEE_PROTOCOL_ALLOCATION_BPS: u64 = 2000;

    // Constants

    /// Maximum number of assets in a stable pool
    /// Factors in this decision:
    /// - The use of 8 assets in a pool leads to overflows of `dp` in swap math invariant computation
    /// - Large pool asset counts with variable precision leads to overflows after normalization
    const MAX_WEIGHTED_POOL_ASSETS: u64 = 4;

    /// Maximum number of assets in a stable pool
    /// Factors in this decision:
    /// - The use of 8 assets in a pool leads to overflows of `dp` in swap math invariant computation
    /// - Large pool asset counts with variable precision leads to overflows after normalization
    const MAX_STABLE_POOL_ASSETS: u64 = 6;

    /// Minimum decimal precision supported in a pool
    /// Decision Factors:
    /// - Pools with high variance in pool decimals lead to overflows in swap math after normalization
    const MIN_STABLE_DECIMALS_SUPPORTED: u8 = 6;

    /// Maximum decimal precision supported in a pool
    /// Decision Factors:
    /// - fungible store & coin modules only support u64 balances (max: 1.84*10^19). At 12 decimals precision, the max ownership of an asset per-user is 10_000_000
    /// - Capping max decimals reduces overflow risks on pool creation
    /// - Pools with high variance in pool decimals lead to overflows in swap math after normalization
    const MAX_STABLE_DECIMALS_SUPPORTED: u8 = 12;

    const POOL_TYPE_STABLE: u8 = 100;
    const POOL_TYPE_WEIGHTED: u8 = 101;

    // Resources

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Pool has key {
        extend_ref: ExtendRef,

        assets_metadata: vector<Object<Metadata>>,

        pool_type: u8,
        /// swap fee takes on 0% (no fee), 0.05%, 0.30%, or 1%
        swap_fee_bps: u64,
        /// true if there is a flashloan in progress, and other flashloan / swap / liquidity operations cannot be executed for the pool
        locked: bool,

        lp_token_mint_ref: MintRef,
        lp_token_transfer_ref: TransferRef,
        lp_token_burn_ref: BurnRef
    }

    /// Flashloan resource following "hot potato" pattern: https://medium.com/@borispovod/move-hot-potato-pattern-bbc48a48d93c
    /// This resource cannot be copied / dropped / stored, but can only be created and destroyed in the same module
    /// by `flashloan` and `pay_flashloan` functions
    struct Flashloan {
        pool_obj: Object<Pool>,
        amounts: vector<u64>,
    }

    struct AddLiquidityPreview has drop {
        minted_lp_token_amount: u64,
        refund_amounts: vector<u64>
    }

    struct RemoveLiquidityPreview has drop {
        withdrawn_amounts: vector<u64>
    }

    struct SwapPreview has drop {
        amount_in: u64,
        amount_in_post_fee: u64,
        amount_out: u64,

        /// Only applicable to stable swap, set to 0 for weighted pool swap
        amount_normalized_in: u128,

        /// Only applicable to stable swap, set to 0 for weighted pool swap
        amount_normalized_out: u128,

        total_fee_amount: u64,
        protocol_fee_amount: u64,
        idx_in: u64,
        idx_out: u64,
        swap_fee_bps: u64,
    }

    /// Creates a new weighted pool with specified assets, weights, and swap fee.
    ///
    /// Parameters:
    /// - `user`: The signer who is creating the pool.
    /// - `assets_metadata`: Metadata for each asset to be included in the pool.
    /// - `amounts`: Initial amounts to deposit for each asset.
    /// - `weights`: Weights for each asset that determine their relative importance in the pool. Must sum to 100
    /// - `swap_fee_bps`: The swap fee expressed in basis points (bps).
    ///
    /// Usage:
    /// 1. Withdraws specified amounts of assets from the user's account.
    /// 2. Verifies that the sum of weights is exactly 100 and all weights are positive.
    /// 3. Verifies that swap fee is either 5, 30, or 100 BPS.
    /// 4. Validates the provided metadata.
    /// 5. Creates a pool, reserving initial liquidity, and mints corresponding LP tokens.
    /// 6. Emits an event signaling the creation of the pool.
    public entry fun create_pool_weighted_entry(
        _user: &signer,
        _assets_metadata: vector<Object<Metadata>>,
        _amounts: vector<u64>,
        _weights: vector<u64>,
        _swap_fee_bps: u64,
    ) {
        abort 0
    }

    /// Internally creates a weighted pool, returning the pool object and LP tokens.
    ///
    /// Parameters:
    /// - `assets`: Vector of assets to include in the pool.
    /// - `weights`: Vector of weights for each asset.
    /// - `swap_fee_bps`: The swap fee in basis points.
    ///
    /// Returns:
    /// - A tuple containing the newly created pool object and the initial LP tokens.
    ///
    /// Steps:
    /// 1. Validates that the weights and metadata are appropriate for a weighted pool.
    /// 2. Checks initial asset balances.
    /// 3. Calls internal methods to create and initialize the pool.
    /// 4. Emits a `PoolCreationEvent`.
    public fun create_pool_weighted(_assets: vector<FungibleAsset>, _weights: vector<u64>, _swap_fee_bps: u64): (Object<Pool>, FungibleAsset) {
        abort 0
    }

    /// Creates a new stable pool with specified assets, swap fee, and amplification factor.
    ///
    /// Parameters:
    /// - `user`: The signer creating the pool.
    /// - `assets_metadata`: Metadata for each asset to be included in the stable pool.
    /// - `amounts`: Initial amounts to deposit for each asset.
    /// - `swap_fee_bps`: The swap fee expressed in basis points (bps).
    /// - `amp_factor`: The amplification factor to stabilize the pool.
    ///
    /// Usage:
    /// 1. Withdraws specified amounts of assets from the user's account.
    /// 2. Validates metadata and checks amplification factor bounds.
    /// 3. Verifies that swap fee is either 5, 30, or 100 BPS.
    /// 4. Computes the initial LP token amount based on normalization factors.
    /// 5. Creates the pool object and mints corresponding LP tokens.
    /// 6. Emits an event to signal the pool creation.
    public entry fun create_pool_stable_entry(
        _user: &signer,
        _assets_metadata: vector<Object<Metadata>>,
        _amounts: vector<u64>,
        _swap_fee_bps: u64,
        _amp_factor: u64,
    ) {
        abort 0
    }

    /// Internally creates a stable pool, returning the pool object and LP tokens.
    ///
    /// Parameters:
    /// - `assets`: Vector of assets to include in the pool.
    /// - `swap_fee_bps`: The swap fee in basis points.
    /// - `amp_factor`: Amplification factor to stabilize swap operations.
    ///
    /// Returns:
    /// - A tuple with the created pool object and initial LP tokens.
    ///
    /// Steps:
    /// 1. Validates stability-specific metadata and amplification factor.
    /// 2. Ensures all asset amounts are greater than zero.
    /// 3. Handles asset normalization and computes initial LP token minting.
    /// 4. Invokes internal pool creation processes.
    /// 5. Emits a `PoolCreationEvent`.
    public fun create_pool_stable(_assets: vector<FungibleAsset>, _swap_fee_bps: u64, _amp_factor: u64): (Object<Pool>, FungibleAsset) {
        abort 0
    }

    /// Adds liquidity to a weighted pool.
    ///
    /// Parameters:
    /// - `user`: The signer of the transaction who is adding liquidity.
    /// - `pool_obj`: The pool object to which liquidity is being added.
    /// - `amounts`: A vector of amounts to add for each asset in the pool.
    /// - `min_amount_out`: The minimum amount of LP tokens that must be received.
    ///
    /// Steps:
    /// 1. The function withdraws the specified amounts from the user's account.
    /// 2. It checks whether the minimum LP tokens are received.
    /// 3. LP tokens are deposited back into the user's account.
    /// 4. Any excess assets are refunded to the user.
    public entry fun add_liquidity_weighted_entry(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _amounts: vector<u64>,
        _min_amount_out: u64,
    ) {
        abort 0
    }

    /// Adds liquidity to a weighted pool with specified assets.
    ///
    /// Parameters:
    /// - `pool_obj`: The pool object to which liquidity is being added.
    /// - `assets`: A vector of assets being provided as liquidity.
    ///
    /// Returns:
    /// - A tuple containing the minted LP tokens and any excess assets refunded.
    ///
    /// Steps:
    /// 1. Calculates the amount of LP tokens to be minted for the provided assets.
    /// 2. Deposits the assets into the pool, adjusting for any excess amounts.
    /// 3. Mints and returns the appropriate LP tokens and refunds.
    public fun add_liquidity_weighted(_pool_obj: Object<Pool>, _assets: vector<FungibleAsset>): (FungibleAsset, vector<FungibleAsset>) {
        abort 0
    }

    /// Adds liquidity to a stable pool.
    ///
    /// Parameters:
    /// - `user`: The signer of the transaction who is adding liquidity.
    /// - `pool_obj`: The pool object to which liquidity is being added.
    /// - `amounts`: A vector of amounts to add for each asset in the pool.
    /// - `min_amount_out`: The minimum amount of LP tokens that must be received.
    ///
    /// Steps:
    /// 1. The function withdraws the specified amounts from the user's account.
    /// 2. It mints new LP tokens.
    /// 3. LP tokens are deposited back into the user's account.
    public entry fun add_liquidity_stable_entry(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _amounts: vector<u64>,
        _min_amount_out: u64,
    ) {
        abort 0
    }

    /// Adds liquidity to a stable pool with specified assets.
    ///
    /// Parameters:
    /// - `pool_obj`: The pool object to which liquidity is being added.
    /// - `assets`: A vector of assets being provided as liquidity.
    ///
    /// Returns:
    /// - The amount of LP tokens minted as a result of the liquidity addition.
    ///
    /// Steps:
    /// 1. Computes the invariant before and after adding the assets to ensure an increased invariant.
    /// 2. Updates pool balances with the provided assets.
    /// 3. Mints and returns LP tokens without excess assets handling.
    public fun add_liquidity_stable(_pool_obj: Object<Pool>, _assets: vector<FungibleAsset>): FungibleAsset {
        abort 0
    }

    /// Removes liquidity from a pool.
    ///
    /// Parameters:
    /// - `user`: The signer who is withdrawing liquidity.
    /// - `pool_obj`: The pool object from which liquidity is being removed.
    /// - `lp_token_metadata`: Metadata of the LP tokens being burned for withdrawal.
    /// - `amount`: The amount of LP tokens to burn.
    /// - `min_amount_outs`: Minimum amounts of each asset to receive as per the user's expectation.
    ///
    /// Steps:
    /// 1. The function withdraws LP tokens from the user's account.
    /// 2. It calculates and verifies withdrawal amounts.
    /// 3. Assets are withdrawn from the pool and deposited into the user's account.
    public entry fun remove_liquidity_entry(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _lp_token_metadata: Object<Metadata>,
        _amount: u64,
        _min_amount_outs: vector<u64>
    ) {
        abort 0
    }

    /// Removes liquidity from a pool, returns proportional asset shares.
    ///
    /// Parameters:
    /// - `pool_obj`: The pool object from which liquidity is being removed.
    /// - `lp_token`: The LP token asset representing the user's share in the pool.
    ///
    /// Returns:
    /// - A vector of fungible assets the user receives after removing liquidity.
    ///
    /// Steps:
    /// 1. Burns the specified LP tokens.
    /// 2. Calculates and retrieves the proportional amount of each pool asset.
    /// 3. Deposits the withdrawn assets back to the user.
    public fun remove_liquidity(_pool_obj: Object<Pool>, _lp_token: FungibleAsset): vector<FungibleAsset> {
        abort 0
    }

    /// Swaps a specific amount of an input asset for a weighted output asset.
    ///
    /// Parameters:
    /// - `user`: The signer executing the swap.
    /// - `pool_obj`: The pool object where the swap is taking place.
    /// - `asset_metadata_in`: Metadata of the input asset.
    /// - `amount_in`: The amount of the input asset being swapped.
    /// - `asset_metadata_out`: Metadata of the desired output asset.
    /// - `min_amount_out`: The minimum amount of the output asset for the swap to proceed.
    ///
    /// Steps:
    /// 1. The function checks balance sufficiency.
    /// 2. Withdraws the specified input amount from the user.
    /// 3. Calculates the output amount after applying fees.
    /// 4. Deposits output asset into the user's account.
    public entry fun swap_exact_in_weighted_entry(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _asset_metadata_in: Object<Metadata>,
        _amount_in: u64,
        _asset_metadata_out: Object<Metadata>,
        _min_amount_out: u64
    ) {
        abort 0
    }

    /// Executes a swap from an input asset to an output asset in a weighted pool.
    ///
    /// Parameters:
    /// - `account`: The signer performing the swap.
    /// - `pool_obj`: The pool object where the swap occurs.
    /// - `asset_in`: The asset being exchanged.
    /// - `asset_out_metadata`: Metadata of the asset to be received.
    ///
    /// Returns:
    /// - The asset received after conducting the swap.
    ///
    /// Steps:
    /// 1. Computes the output amount based on the input and pool conditions.
    /// 2. Applies swap fees and updates the pool balances.
    /// 3. Issues the output asset to the user.
    public fun swap_exact_in_weighted(_account: &signer, _pool_obj: Object<Pool>, _asset_in: FungibleAsset, _asset_out_metadata: Object<Metadata>): FungibleAsset {
        abort 0
    }

    /// Swaps a specific amount of an input asset for a stable pool output asset.
    ///
    /// Parameters:
    /// - `user`: The signer executing the swap.
    /// - `pool_obj`: The pool object where the swap is taking place.
    /// - `asset_metadata_in`: Metadata of the input asset.
    /// - `amount_in`: The amount of the input asset being swapped.
    /// - `asset_metadata_out`: Metadata of the desired output asset.
    /// - `min_amount_out`: The minimum amount of the output asset for the swap to proceed.
    ///
    /// Steps:
    /// 1. Ensures the input amount is valid and the user has sufficient balance.
    /// 2. Withdraws the input asset.
    /// 3. Executes the swap using stable math.
    /// 4. Deposits output asset into the user's account after checking minimum output constraints.
    public entry fun swap_exact_in_stable_entry(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _asset_metadata_in: Object<Metadata>,
        _amount_in: u64,
        _asset_metadata_out: Object<Metadata>,
        _min_amount_out: u64
    ) {
        abort 0
    }

    /// Executes a swap from an input asset to an output asset in a stable pool.
    ///
    /// Parameters:
    /// - `account`: The signer conducting the swap.
    /// - `pool_obj`: The pool object where the swap is taking place.
    /// - `asset_in`: The asset being swapped from.
    /// - `metadata_out`: Metadata of the asset to be retrieved after the swap.
    ///
    /// Returns:
    /// - The asset received after the swap process.
    ///
    /// Steps:
    /// 1. Uses stable pool mechanics to determine appropriate exchange amounts.
    /// 2. Considers swap fees and adjusts the pool accordingly.
    /// 3. Updates the TWAP Oracle if needed and provides the output asset.
    public fun swap_exact_in_stable(_account: &signer, _pool_obj: Object<Pool>, _asset_in: FungibleAsset, _metadata_out: Object<Metadata>): FungibleAsset {
        abort 0
    }

    /// Swaps to achieve an exact amount of a weighted output asset, providing input from the user's balance.
    ///
    /// Parameters:
    /// - `user`: The signer executing the swap.
    /// - `pool_obj`: The pool object where the swap is taking place.
    /// - `asset_metadata_in`: Metadata of the input asset.
    /// - `amount_in`: The maximum allowable amount of the input asset for the swap.
    /// - `asset_metadata_out`: Metadata of the desired output asset.
    /// - `amount_out`: The exact amount of the output asset the user wants to receive.
    ///
    /// Steps:
    /// 1. Checks if the input balance is sufficient to cover the maximum input amount.
    /// 2. Withdraws the input asset amount.
    /// 3. Calculates the required input for the exact output amount after fees.
    /// 4. Refunds any excess input back to the user's account.
    /// 5. Deposits the exact output asset into the user's account.
    public entry fun swap_exact_out_weighted_entry(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _asset_metadata_in: Object<Metadata>,
        _amount_in: u64,
        _asset_metadata_out: Object<Metadata>,
        _amount_out: u64,
    ) {
        abort 0
    }

    /// Conducts a swap to obtain a specified exact amount of an output asset in a weighted pool.
    ///
    /// Parameters:
    /// - `account`: The signer executing the swap.
    /// - `pool_obj`: The pool object involved in the swap.
    /// - `asset_in`: Asset provided as input to achieve the exact output.
    /// - `asset_out_metadata`: Metadata of the asset to be received.
    /// - `amount_out`: Target amount of the output asset.
    ///
    /// Returns:
    /// - A tuple with any unused input assets returned and the exact output asset obtained.
    ///
    /// Steps:
    /// 1. Validates the input and calculates the required exact input given swap fees.
    /// 2. Any excess input is refunded to the user's account.
    /// 3. Executes the swap ensuring the exact output amount is delivered.
    public fun swap_exact_out_weighted(_account: &signer, _pool_obj: Object<Pool>, _asset_in: FungibleAsset, _asset_out_metadata: Object<Metadata>, _amount_out: u64): (FungibleAsset, FungibleAsset) {
        abort 0
    }

    /// Swaps to achieve an exact amount of a stable output asset, providing input from the user's balance.
    ///
    /// Parameters:
    /// - `user`: The signer executing the swap.
    /// - `pool_obj`: The pool object where the swap is taking place.
    /// - `asset_metadata_in`: Metadata of the input asset.
    /// - `amount_in`: The maximum allowable amount of the input asset for the swap.
    /// - `asset_metadata_out`: Metadata of the desired output asset.
    /// - `amount_out`: The exact amount of the output asset the user wants to receive.
    ///
    /// Steps:
    /// 1. Ensures sufficient input balance and withdraws the specified amount.
    /// 2. Uses stable math to compute required input for achieving the exact output.
    /// 3. Refunds any input exceeding the calculated requirement back to the user.
    /// 4. Updates the TWAP Oracle with the swap details.
    /// 5. Provides the exact output asset to the user.
    public entry fun swap_exact_out_stable_entry(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _asset_metadata_in: Object<Metadata>,
        _amount_in: u64,
        _asset_metadata_out: Object<Metadata>,
        _amount_out: u64,
    ) {
        abort 0
    }

    /// Conducts a swap to obtain a specified exact amount of an output asset in a stable pool.
    ///
    /// Parameters:
    /// - `account`: The signer executing the swap.
    /// - `pool_obj`: The pool object involved in the swap.
    /// - `asset_in`: Asset provided as input.
    /// - `asset_out_metadata`: Metadata of the asset to be received.
    /// - `amount_out`: Exact amount of the output asset desired.
    ///
    /// Returns:
    /// - A tuple of any unused input asset and the exact output asset obtained.
    ///
    /// Steps:
    /// 1. Uses stable pool mathematics to compute the needed input amount after fees.
    /// 2. Refunds any excess input assets.
    /// 3. Executes the swap to deliver the exact output asset and updates TWAP if necessary.
    public fun swap_exact_out_stable(_account: &signer, _pool_obj: Object<Pool>, _asset_in: FungibleAsset, _asset_out_metadata: Object<Metadata>, _amount_out: u64): (FungibleAsset, FungibleAsset) {
        abort 0
    }

    /// Initiates a flashloan by borrowing specified asset amounts from a pool.
    /// We allow borrowing any assets.
    ///
    /// Parameters:
    /// - `pool_obj`: The pool object from which assets are being borrowed.
    /// - `amounts`: The amounts to borrow for each asset in the pool.
    ///
    /// Returns:
    /// - A tuple containing the loaned assets vector and a Flashloan resource.
    ///
    /// Usage:
    /// 1. Verifies flashloan conditions such as sufficient pool balance.
    /// 2. Locks the pool while the loan is active.
    /// 3. Provides the borrowed assets and tracks them using the Flashloan resource.
    public fun flashloan(_pool_obj: Object<Pool>, _amounts: vector<u64>): (vector<FungibleAsset>, Flashloan) {
        abort 0
    }

    /// Completes the flashloan by repaying the borrowed assets along with fees.
    ///
    /// Parameters:
    /// - `assets`: A vector of assets being repaid to the pool.
    /// - `loan`: The Flashloan resource that tracks the borrowed amounts and pool information.
    ///
    /// Process:
    /// 1. Ensures that the pool is locked and verifies the repayment amounts against the borrowed amounts.
    /// 2. Computes the required fee for each asset and verifies that the pool invariant is not decreased post-repayment.
    /// 3. Deposits the repaid assets back into the pool.
    /// 4. Collects and deposits the computed flashloan fees.
    /// 5. Unlocks the pool and emits a `FlashloanEvent` to signal completion.
    ///
    /// Preconditions:
    /// - The assets vector must match the pool's assets in metadata order and length.
    /// - All conditions must ensure the invariant check passes for both stable and weighted pools.
    public fun pay_flashloan(_assets: vector<FungibleAsset>, _loan: Flashloan) {
        abort 0
    }

    // Public Pool Helpers

    #[view]
    public fun preview_add_liquidity_weighted(_pool_obj: Object<Pool>, _metadata: vector<Object<Metadata>>, _amounts: vector<u64>): AddLiquidityPreview {
        abort 0
    }

    #[view]
    public fun preview_add_liquidity_stable(_pool_obj: Object<Pool>, _metadata: vector<Object<Metadata>>, _amounts: vector<u64>): AddLiquidityPreview {
        abort 0
    }

    #[view]
    public fun preview_remove_liquidity(_pool_obj: Object<Pool>, _lp_token_metadata: Object<Metadata>, _lp_token_amount: u64): RemoveLiquidityPreview {
        abort 0
    }

    #[view]
    public fun preview_swap_exact_in_weighted(_pool_obj: Object<Pool>, _asset_in_metadata: Object<Metadata>, _sset_out_metadata: Object<Metadata>, _amount_in: u64, _trader: Option<address>): SwapPreview {
        abort 0
    }

    #[view]
    public fun preview_swap_exact_in_stable(_pool_obj: Object<Pool>, _asset_in_metadata: Object<Metadata>, _asset_out_metadata: Object<Metadata>, _amount_in: u64, _trader: Option<address>): SwapPreview {
        abort 0
    }

    #[view]
    public fun preview_swap_exact_out_weighted(_pool_obj: Object<Pool>, _metadata_in: Object<Metadata>, _metadata_out: Object<Metadata>, _amount_out: u64, _trader: Option<address>): SwapPreview {
        abort 0
    }

    #[view]
    public fun preview_swap_exact_out_stable(_pool_obj: Object<Pool>, _asset_in_metadata: Object<Metadata>, _asset_out_metadata: Object<Metadata>, _amount_out: u64, _trader: Option<address>): SwapPreview {
        abort 0
    }

    #[view]
    public fun pools(): vector<Object<Pool>> {
        vector[]
    }

    #[view]
    public fun swap_fee_protocol_allocation_bps(): u64 {
        0
    }

    #[view]
    public fun flashloan_fee_bps(): u64 {
        0
    }

    #[view]
    public fun fees_metadata(): vector<Object<Metadata>> {
        vector[]
    }

    #[view]
    public fun pool_balances(_pool_obj: Object<Pool>): vector<u64> {
        vector[]
    }

    #[view]
    public fun pool_assets_metadata(_pool_obj: Object<Pool>): vector<Object<Metadata>> {
        vector[]
    }

    #[view]
    public fun pool_size(_pool_obj: Object<Pool>): u64 {
        0
    }

    #[view]
    public fun pool_type(_pool_obj: Object<Pool>): u8 {
        0
    }

    #[view]
    public fun pool_is_weighted(_pool_obj: Object<Pool>): bool {
        false
    }

    #[view]
    public fun pool_is_stable(_pool_obj: Object<Pool>): bool {
        false
    }

    #[view]
    public fun pool_swap_fee_bps(_pool_obj: Object<Pool>): u64 {
        0
    }

    #[view]
    public fun pool_locked(_pool_obj: Object<Pool>): bool {
        false
    }

    #[view]
    public fun pool_lp_token_metadata(_pool_obj: Object<Pool>): Object<Metadata> {
        abort 0
    }

    #[view]
    /// Return the token supply of an LP token. LP token supply is always denominated in units of u64
    public fun pool_lp_token_supply(_pool_obj: Object<Pool>): u64 {
        0
    }

    #[view]
    public fun pool_weights(_pool_obj: Object<Pool>): vector<u64> {
        vector[]
    }

    #[view]
    public fun pool_amp_factor(_pool_obj: Object<Pool>): u64 {
        0
    }

    #[view]
    public fun pool_precision_multipliers(_pool_obj: Object<Pool>): vector<u64> {
        vector[]
    }

    #[view]
    public fun pool_balances_normalized(_pool_obj: Object<Pool>): vector<u128> {
        vector[]
    }

    #[view]
    public fun pool_invariant(_pool_obj: Object<Pool>): u256 {
        0
    }

    #[view]
    public fun stable_pool_exists(_metadata: vector<Object<Metadata>>, _swap_fee_bps: u64): bool {
        false
    }

    #[view]
    public fun weighted_pool_exists(_metadata: vector<Object<Metadata>>, _weights: vector<u64>, _swap_fee_bps: u64): bool {
        false
    }

    #[view]
    public fun lp_seed_stable(_metadata: vector<Object<Metadata>>, _swap_fee_bps: u64): vector<u8> {
        vector[]
    }

    #[view]
    public fun lp_seed_weighted(_metadata: vector<Object<Metadata>>, _weights: vector<u64>, _swap_fee_bps: u64): vector<u8> {
        vector[]
    }

    #[view]
    public fun oracle_exists(_pool_obj: Object<Pool>, _metadata_x: Object<Metadata>, _metadata_y: Object<Metadata>): bool {
        false
    }

    #[view]
    public fun oracle_address(_pool_obj: Object<Pool>, _metadata_x: Object<Metadata>, _metadata_y: Object<Metadata>): address {
        @thalaswap_v2
    }

    #[view]
    /// Returns (cumulative_price_x_to_y, cumulative_price_y_to_x, spot_price_x_to_y, spot_price_y_to_x, last updated timestamp)
    /// X/Y identifies the asset pair to be priced
    /// Price u128 number is the raw value of FixedPoint64, updated at last swap
    public fun twap_oracle_status(_pool_obj: Object<Pool>, _metadata_x: Object<Metadata>, _metadata_y: Object<Metadata>): (u128, u128, u128, u128, u64) {
        (0, 0, 0, 0, 0)
    }

    #[view]
    /// Returns (price_x_to_y, price_y_to_x)
    /// X/Y identifies the asset pair to be priced
    /// Cumulative price u128 number is the raw value of FixedPoint64. It's the current value
    /// Current cumulative price = last cumulative price + (current timestamp - last timestamp) * last spot price
    /// Reference: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2OracleLibrary.sol#L16
    public fun current_cumulative_prices(_pool_obj: Object<Pool>, _metadata_x: Object<Metadata>, _metadata_y: Object<Metadata>): (u128, u128) {
        (0, 0)
    }

    #[view]
    public fun trader_swap_fee_multiplier(_trader_address: address): u64 {
        0
    }

    #[view]
    public fun fee_balance(_asset_metadata: Object<Metadata>): u64 {
        0
    }
}
