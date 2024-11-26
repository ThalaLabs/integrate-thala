module thalaswap_v1_interface::base_pool {
    use std::string::{String};

    use aptos_std::event::{EventHandle};

    use fixed_point64::fixed_point64::{FixedPoint64};

    friend thalaswap::init;

    friend thalaswap::stable_pool;
    friend thalaswap::weighted_pool;

    ///
    /// Error Codes
    ///

    const ERR_UNAUTHORIZED: u64 = 0;

    // Initialization
    const ERR_INITIALIZED: u64 = 1;
    const ERR_UNINITIALIZED: u64 = 2;

    // BPS
    const ERR_BPS_GT_10000: u64 = 3;

    ///
    /// Defaults
    ///

    const DEFAULT_SWAP_FEE_PROTOCOL_ALLOCATION_BPS: u64 = 2000;

    ///
    /// Constants
    ///

    const MAX_SUPPORTED_DECIMALS: u8 = 8;
    const MAX_SWAP_FEE: u64 = 1000;

    const BPS_BASE: u64 = 10000;

    ///
    /// Resources
    ///

    /// Used as a placeholder for void Weight & Asset pool type parameters
    struct Null {}

    /// Stores parameters that apply to all pools
    struct BasePoolParams has key {
        swap_fee_protocol_allocation_ratio: FixedPoint64,
        param_change_events: EventHandle<BasePoolParamChangeEvent>
    }

    ///
    /// Events
    ///

    /// Event emitted when a protocol parameter is changed
    struct BasePoolParamChangeEvent has drop, store {
        name: String,

        prev_value: u64,
        new_value: u64
    }

    //
    // Functions
    //

    #[view]
    /// Return the token supply of an LP token. LP token supply is always denominated in units of u64
    public fun pool_token_supply<LPCoinType>(): u64 {
        abort 0
    }

    /// Checks ordering, unique coins, & coin decimals
    /// Returns (success, number of assets in a pool)
    public(friend) fun validate_pool_assets<X, Y, Z, W>(): bool {
        abort 0
    }

    /// Copy from validate_pool_assets with only variance being max_weighted_pool_asset_decimals = 10
    public(friend) fun validate_weighted_pool_assets<X, Y, Z, W>(): bool {
        abort 0
    }

    /// Validates that the swap fee is between bounds
    public(friend) fun validate_swap_fee(_swap_fee_bps: u64): bool {
        abort 0
    }

    public fun is_null<CoinType>(): bool {
        abort 0
    }

    // Public Getters

    public(friend) fun initialized(): bool {
        abort 0
    }

    #[view]
    public fun swap_fee_protocol_allocation_ratio(): FixedPoint64 {
        abort 0
    }

    #[view]
    public fun max_supported_decimals(): u8 {
        MAX_SUPPORTED_DECIMALS
    }
}
