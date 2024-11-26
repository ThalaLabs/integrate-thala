module thalaswap_v1_interface::stable_pool {
    use std::string::{String};

    use aptos_framework::coin::{Coin, MintCapability, BurnCapability};

    use aptos_std::table::{Table};
    use aptos_std::smart_table::{SmartTable};
    use aptos_std::event::{EventHandle};

    use fixed_point64::fixed_point64::{FixedPoint64};

    friend thalaswap::init;

    ///
    /// Error codes
    ///

    const ERR_UNAUTHORIZED: u64 = 0;

    // Initialization
    const ERR_INITIALIZED: u64 = 1;
    const ERR_UNINITIALIZED: u64 = 2;

    // Pool Conditions
    const ERR_STABLE_POOL_EXISTS: u64 = 3;
    const ERR_STABLE_POOL_NOT_EXISTS: u64 = 4;
    const ERR_STABLE_POOL_INVALID_POOL_ASSETS: u64 = 5;
    const ERR_STABLE_POOL_INVARIANT_NOT_INCREASING: u64 = 6;
    const ERR_STABLE_POOL_INSUFFICIENT_INPUT: u64 = 7;
    const ERR_STABLE_POOL_INSUFFICIENT_LIQUIDITY: u64 = 8;
    const ERR_STABLE_POOL_LOCKED: u64 = 9;

    // Swap Conditions
    const ERR_STABLE_POOL_INVALID_SWAP: u64 = 100;

    // Management
    const ERR_STABLE_POOL_INVALID_SWAP_FEE: u64 = 200;

    // Input check
    const ERR_STABLE_POOL_AMP_FACTOR_OUT_OF_BOUND: u64 = 300;

    // Flashloan
    const ERR_STABLE_POOL_FLASHLOAN_UNINITIALIZED: u64 = 400;
    const ERR_STABLE_POOL_FLASHLOAN_INVALID_AMOUNT: u64 = 401;
    const ERR_STABLE_POOL_FLASHLOAN_INSUFFICIENT_REPAY: u64 = 402;
    const ERR_STABLE_POOL_FLASHLOAN_NOT_ONGOING: u64 = 403;
    const ERR_STABLE_POOL_FLASHLOAN_INVALID_FEE: u64 = 404;

    // Math
    const ERR_DIVIDE_BY_ZERO: u64 = 500;

    // Oracle
    const ERR_STABLE_POOL_ORACLE_EXISTS: u64 = 600;
    const ERR_STABLE_POOL_ORACLE_NOT_EXISTS: u64 = 601;
    const ERR_STABLE_POOL_ORACLE_INVALID_ASSETS: u64 = 602;

    ///
    /// Defaults
    ///

    const DEFAULT_SWAP_FEE_BPS: u64 = 10;
    const DEFAULT_FLASHLOAN_FEE_BPS: u64 = 1;

    ///
    /// Constants
    ///

    const POOL_TOKEN_DECIMALS: u8 = 8;
    const MINIMUM_LIQUIDITY: u64 = 100;

    /// A sane upper bound of amp factor so that it cannot go arbitrarily high
    const MAX_AMP_FACTOR: u64 = 10000;

    const BPS_BASE: u64 = 10000;

    ///
    /// Resources
    ///

    /// Token issued to LPs represnting fractional ownership of the pool
    struct StablePoolToken<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> {}

    /// Flashloan resource following "hot potato" pattern: https://medium.com/@borispovod/move-hot-potato-pattern-bbc48a48d93c
    /// This resource cannot be copied / dropped / stored, but can only be created and destroyed in the same module
    /// by `flashloan` and `pay_flashloan` functions
    struct Flashloan<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> {
        amount_0: u64,
        amount_1: u64,
        amount_2: u64,
        amount_3: u64,
    }

    /// We use a separate global storage for flashloan related structs because we want to do a backward compatible upgrade
    struct FlashloanHelper<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> has key {
        /// true if there is a flashloan in progress, and other flashloan / swap / liquidity operations cannot be executed for the pool
        locked: bool,
        /// flashloan fee in basis points
        flashloan_fee_bps: u64,
        flashloan_events: EventHandle<FlashloanEvent<Asset0, Asset1, Asset2, Asset3>>
    }

    struct StablePool<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> has key {
        asset_0: Coin<Asset0>,
        asset_1: Coin<Asset1>,
        asset_2: Coin<Asset2>,
        asset_3: Coin<Asset3>,

        amp_factor: u64,

        // multipliers for each pooled asset's precision to get to base_pool::max_supported_decimals()
        // for example, MOD has 8 decimals, so the multiplier should be 1 (=10^0).
        // let's say USDC has 6, then the multiplier should be 100 (=10^(8-6))
        precision_multipliers: vector<u64>,

        swap_fee_ratio: FixedPoint64,
        inverse_negated_swap_fee_ratio: FixedPoint64,

        pool_token_mint_cap: MintCapability<StablePoolToken<Asset0, Asset1, Asset2, Asset3>>,
        pool_token_burn_cap: BurnCapability<StablePoolToken<Asset0, Asset1, Asset2, Asset3>>,

        reserved_lp_coin: Coin<StablePoolToken<Asset0, Asset1, Asset2, Asset3>>,

        events: StablePoolEvents<Asset0, Asset1, Asset2, Asset3>,
    }

    struct StablePoolLookup has key {
        // key: LP token type_name, value: StablePoolInfo
        // this is used to help LP oracle to query the status of a pool using LP token name
        name_to_pool: Table<String, StablePoolInfo>,

        // key: unique pool ID, value: LP token type_name
        // this is to help DEX aggregator (e.g. Hippo) to iterate all pools
        id_to_name: Table<u64, String>,

        // Pool ID increments for each new pool
        next_id: u64,
    }

    /// Stores the status of a pool without "CoinType" generic type
    /// Can be used to query the status of a pool by LP token name - mainly used by Thalaswap LP Oracle (in ThalaOracle package)
    struct StablePoolInfo has copy, store, drop {
        balances: vector<u64>,
        precision_multipliers: vector<u64>,
        amp_factor: u64,
        lp_coin_supply: u64
    }

    struct StablePoolParams has key {
        default_swap_fee_ratio: FixedPoint64,
        param_change_events: EventHandle<StablePoolParamChangeEvent>
    }

    struct SwapFeeOverrides<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> has key {
        traders: SmartTable<address, FixedPoint64>
    }

    /// Stores cumulative price of the relative price of two assets X Y using the pool identified by Asset0/1/2/3
    /// and stores last updated timestamp of the price to help derive TWAP
    /// Asset0/1/2/3 is the pool assets, and X/Y is the pair of assets to be priced
    /// X and Y must be stored in order (coin_helper::is_unique_and_sorted<X, Y>() should return true)
    /// All u128 values are raw values of FixedPoint64
    struct TwapOracle<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3, phantom X, phantom Y> has key, drop {
        /// Cumulative price of asset x in terms of asset y
        cumulative_price_x: u128,
        /// Cumulative price of asset y in terms of asset x
        cumulative_price_y: u128,
        /// Spot price of asset x in terms of asset y
        spot_price_x: u128,
        /// Spot price of asset y in terms of asset x
        spot_price_y: u128,
        /// Timestamp of the last update
        timestamp: u64
    }

    ///
    /// Events
    ///

    /// Event emitted when a pool is created
    struct StablePoolCreationEvent<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> has drop, store {
        creator: address,
        amount_0: u64,
        amount_1: u64,
        amount_2: u64,
        amount_3: u64,
        minted_lp_coin_amount: u64,
        swap_fee_bps: u64,
    }

    /// Event emitted when a liquidity is added to a pool
    struct AddLiquidityEvent<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> has drop, store {
        amount_0: u64,
        amount_1: u64,
        amount_2: u64,
        amount_3: u64,
        minted_lp_coin_amount: u64,
    }

    /// Event emitted when a liquidity is removed from a pool
    struct RemoveLiquidityEvent<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> has drop, store {
        amount_0: u64,
        amount_1: u64,
        amount_2: u64,
        amount_3: u64,
        burned_lp_coin_amount: u64,
    }

    /// Event emitted when a swap is executed
    struct SwapEvent<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> has drop, store {
        idx_in: u64,
        idx_out: u64,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        pool_balance_0: u64,
        pool_balance_1: u64,
        pool_balance_2: u64,
        pool_balance_3: u64,
        amp_factor: u64,
    }

    /// Event emitted when a flashloan is executed
    struct FlashloanEvent<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> has drop, store {
        amount_0: u64,
        amount_1: u64,
        amount_2: u64,
        amount_3: u64,
    }

    /// Event emitted when a protocol parameter is changed
    struct StablePoolParamChangeEvent has drop, store {
        name: String,

        prev_value: u64,
        new_value: u64
    }

    struct StablePoolEvents<phantom Asset0, phantom Asset1, phantom Asset2, phantom Asset3> has store {
        pool_creation_events: EventHandle<StablePoolCreationEvent<Asset0, Asset1, Asset2, Asset3>>,
        add_liquidity_events: EventHandle<AddLiquidityEvent<Asset0, Asset1, Asset2, Asset3>>,
        remove_liquidity_events: EventHandle<RemoveLiquidityEvent<Asset0, Asset1, Asset2, Asset3>>,
        swap_events: EventHandle<SwapEvent<Asset0, Asset1, Asset2, Asset3>>,

        param_change_events: EventHandle<StablePoolParamChangeEvent>
    }

    ///
    /// Functions
    ///

    public fun create_stable_pool<Asset0, Asset1, Asset2, Asset3>(
        _account: &signer,
        _asset_0: Coin<Asset0>,
        _asset_1: Coin<Asset1>,
        _asset_2: Coin<Asset2>,
        _asset_3: Coin<Asset3>,
        _amp_factor: u64,
    ): Coin<StablePoolToken<Asset0, Asset1, Asset2, Asset3>> {
        abort 0
    }

    public fun add_liquidity<Asset0, Asset1, Asset2, Asset3>(
        _asset_0: Coin<Asset0>,
        _asset_1: Coin<Asset1>,
        _asset_2: Coin<Asset2>,
        _asset_3: Coin<Asset3>
    ): Coin<StablePoolToken<Asset0, Asset1, Asset2, Asset3>> {
        abort 0
    }

    public fun remove_liquidity<Asset0, Asset1, Asset2, Asset3>(
        _lp_coin: Coin<StablePoolToken<Asset0, Asset1, Asset2, Asset3>>
    ): (Coin<Asset0>, Coin<Asset1>, Coin<Asset2>, Coin<Asset3>) {
        abort 0
    }

    public fun swap_exact_in<Asset0, Asset1, Asset2, Asset3, X, Y>(_coin_in: Coin<X>): Coin<Y> {
        abort 0
    }

    /// Enables a user to swap_exact_in, taking advantage of fee_overrides if present
    public fun swap_exact_in_fee_overrides<Asset0, Asset1, Asset2, Asset3, X, Y>(
        _account: &signer,
        _coin_in: Coin<X>
    ): Coin<Y> {
        abort 0
    }

    // Swap with exact amount out
    // X is input coin, Y is output coin
    // Returns extra amount of coin X refunded, and output coin Y
    public fun swap_exact_out<Asset0, Asset1, Asset2, Asset3, X, Y>(
        _coin_in: Coin<X>,
        _amount_out: u64
    ): (Coin<X>, Coin<Y>) {
        abort 0
    }

    /// Get flash loan coins.
    /// We allow borrowing any assets
    /// Returns loan coins along with Flashloan resource
    public fun flashloan<Asset0, Asset1, Asset2, Asset3>(
        _amount_0: u64,
        _amount_1: u64,
        _amount_2: u64,
        _amount_3: u64
    ): (Coin<Asset0>, Coin<Asset1>, Coin<Asset2>, Coin<Asset3>, Flashloan<Asset0, Asset1, Asset2, Asset3>)
    {
        abort 0
    }

    /// Pay flash loan coins and destroy the Flashloan resource.
    /// User must pay back the loan coins plus the fee.
    public fun pay_flashloan<Asset0, Asset1, Asset2, Asset3>(
        _coin_0: Coin<Asset0>,
        _coin_1: Coin<Asset1>,
        _coin_2: Coin<Asset2>,
        _coin_3: Coin<Asset3>,
        _loan: Flashloan<Asset0, Asset1, Asset2, Asset3>
    )
    {
        abort 0
    }

    // Public Getters

    public fun initialized(): bool {
        abort 0
    }

    #[view]
    public fun stable_pool_exists<Asset0, Asset1, Asset2, Asset3>(): bool {
        abort 0
    }

    #[view]
    public fun oracle_exists<Asset0, Asset1, Asset2, Asset3, X, Y>(): bool {
        abort 0
    }

    #[view]
    /// Returns pool balances, amp factor, and lp coin supply
    /// **Note** Balances are normalized to the same precision -- `base_pool::max_supported_decimals()`
    public fun pool_info(_lp_coin_name: String): (vector<u64>, u64, u64) {
        abort 0
    }

    #[view]
    /// Get a list of balances. **Note** Balances are normalized to the same precision -- `base_pool::max_supported_decimals()`
    public fun pool_balances<Asset0, Asset1, Asset2, Asset3>(): vector<u64>
    {
        abort 0
    }

    #[view]
    /// Extract the AMP factor of a stable pool
    public fun pool_amp_factor<Asset0, Asset1, Asset2, Asset3>(): u64 {
        abort 0
    }

    #[view]
    public fun next_pool_id(): u64 {
        abort 0
    }

    #[view]
    public fun lp_name_by_id(_id: u64): String {
        abort 0
    }

    #[view]
    public fun get_precision_multipliers<Asset0, Asset1, Asset2, Asset3>(): vector<u64> {
        abort 0
    }

    #[view]
    public fun swap_fee_ratio<Asset0, Asset1, Asset2, Asset3>(): FixedPoint64 {
        abort 0
    }

    #[view]
    public fun swap_fee_ratio_with_overrides<Asset0, Asset1, Asset2, Asset3>(
        _trader_address: address
    ): FixedPoint64 {
        abort 0
    }

    #[view]
    public fun inverse_negated_swap_fee_ratio<Asset0, Asset1, Asset2, Asset3>(): FixedPoint64 {
        abort 0
    }

    #[view]
    public fun flashloan_fee_bps<Asset0, Asset1, Asset2, Asset3>(): u64 {
        abort 0
    }

    #[view]
    /// Returns (cumulative_price_x_to_y, cumulative_price_y_to_x, spot_price_x_to_y, spot_price_y_to_x, last updated timestamp)
    /// Asset0/1/2/3 identifies the stable pool
    /// X/Y identifies the asset pair to be priced
    /// Price u128 number is the raw value of FixedPoint64, updated at last swap
    public fun twap_oracle_status<Asset0, Asset1, Asset2, Asset3, X, Y>(
    ): (u128, u128, u128, u128, u64) {
        abort 0
    }

    #[view]
    /// Returns (price_x_to_y, price_y_to_x)
    /// Asset0/1/2/3 identifies the stable pool
    /// X/Y identifies the asset pair to be priced
    /// Cumulative price u128 number is the raw value of FixedPoint64. It's the current value
    /// Current cumulative price = last cumulative price + (current timestamp - last timestamp) * last spot price
    /// Reference: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2OracleLibrary.sol#L16
    public fun current_cumulative_prices<Asset0, Asset1, Asset2, Asset3, X, Y>(): (u128, u128) {
        abort 0
    }
}
