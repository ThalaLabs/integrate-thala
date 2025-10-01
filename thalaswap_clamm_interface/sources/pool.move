module thalaswap_clamm::pool {
    use std::option::Option;
    use std::string::String;

    use aptos_framework::fungible_asset::{Metadata, FungibleAsset};
    use aptos_framework::object::{ExtendRef, Object};

    use aptos_std::simple_map::SimpleMap;
    use aptos_std::smart_table::SmartTable;
    use aptos_std::smart_vector::SmartVector;

    use aptos_token_objects::collection::{MutatorRef, Collection};
    use aptos_token_objects::token::Token;

    use thalaswap_clamm::oracle::TwapOracle;

    //
    // Defaults
    //

    /// This default is equivalent to a 0% protocol take on swaps.
    const DEFAULT_PROTOCOL_ALLOCATION_BPS: u64 = 0;

    //
    // Constants
    //

    const MAX_SUPPORTED_DECIMALS: u8 = 10;

    const BPS_BASE: u64 = 10000;

    const POSITION_COLLECTION_NAME: vector<u8> = b"ThalaSwapCL Position Collection";

    const MAX_U256: u256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    //
    // Errors
    //

    // Authorization

    /// Unauthorized caller
    const ERR_UNAUTHORIZED: u64 = 0;

    // Pool Conditions

    /// Concentrated pool with same metadata + swap fee already exists
    const ERR_CONCENTRATED_POOL_EXISTS: u64 = 2;

    /// Concentrated pool at the specified address does not exist
    const ERR_CONCENTRATED_POOL_NOT_EXISTS: u64 = 3;

    /// Incorrect assets provided (metadatas do not match pool assets or metadatas unsorted)
    const ERR_CONCENTRATED_POOL_INVALID_ASSETS: u64 = 5;

    /// Asset does not match pool assets
    const ERR_CONCENTRATED_POOL_ASSET_INVALID: u64 = 6;

    /// Insufficient input amount for swap/liquidity operations
    const ERR_CONCENTRATED_POOL_INSUFFICIENT_INPUT: u64 = 7;

    /// Insufficient liquidity provided to complete liquidity operation
    const ERR_CONCENTRATED_POOL_INSUFFICIENT_LIQUIDITY: u64 = 8;

    /// Position token does not belong to caller
    const ERR_CONCENTRATED_POOL_TOKEN_OWNER_MISMATCH: u64 = 9;

    /// Pool liquidity operations are paused
    const ERR_CONCENTRATED_POOL_LIQUIDITY_PAUSED: u64 = 10;

    // Tick Conditions

    /// Tick provided is not a multiple of pool tick spacing
    const ERR_CONCENTRATED_POOL_INVALID_TICK_SPACING: u64 = 100;

    /// Ticks provided do not match expectations (out of order, do not match position object)
    const ERR_CONCENTRATED_POOL_INVALID_TICKS: u64 = 101;

    /// Tick provided is lower than min tick
    const ERR_CONCENTRATED_POOL_TICK_TOO_LOW: u64 = 102;

    /// Tick provided is higher than max tick
    const ERR_CONCENTRATED_POOL_TICK_TOO_HIGH: u64 = 103;

    /// Liquidity after swap/liquidity operation is higher than max liquidity per tick
    const ERR_CONCENTRATED_POOL_LIQUIDITY_TOO_HIGH: u64 = 104;

    /// Ticks provided do not exist in the pool
    const ERR_CONCENTRATED_POOL_TICK_NOT_INITIALIZED: u64 = 105;

    // Swap Conditions

    /// Invalid swap parameters xxx
    const ERR_CONCENTRATED_POOL_INVALID_SWAP: u64 = 200;

    /// Invalid sqrt price limit provided, higher than current price
    const ERR_CONCENTRATED_POOL_PRICE_LIMIT_GT_SQRT_PRICE: u64 = 202;

    /// Invalid sqrt price limit provided, lower than current price
    const ERR_CONCENTRATED_POOL_PRICE_LIMIT_LT_SQRT_PRICE: u64 = 203;

    /// Invalid sqrt price limit provided, lower than min sqrt limit
    const ERR_CONCENTRATED_POOL_PRICE_LIMIT_LT_MIN_SQRT_RATIO: u64 = 204;

    /// Invalid sqrt price limit provided, higher than max sqrt limit
    const ERR_CONCENTRATED_POOL_PRICE_LIMIT_GT_MAX_SQRT_RATIO: u64 = 205;

    /// Insufficient pool balance to cover exact out requested
    const ERR_CONCENTRATED_POOL_INSUFFICIENT_ASSET_OUT: u64 = 206;

    /// Insufficient asset in to cover exact out requested
    const ERR_CONCENTRATED_POOL_INSUFFICIENT_ASSET_IN: u64 = 207;

    /// Swap operations are paused
    const ERR_CONCENTRATED_POOL_SWAP_PAUSED: u64 = 208;

    // Fee Conditions

    /// Swap fee provided does not match allowed pool fee options
    const ERR_CONCENTRATED_POOL_INVALID_SWAP_FEE: u64 = 300;

    /// Invalid protocol fee provided
    const ERR_CONCENTRATED_POOL_INVALID_PROTOCOL_FEE: u64 = 302;

    // Flashloan Conditions

    /// Pool is locked, no operations are allowed
    const ERR_CONCENTRATED_POOL_LOCKED: u64 = 400;

    /// Pool flashloan paid when pool is not locked
    const ERR_CONCENTRATED_POOL_FLASHLOAN_NOT_ONGOING: u64 = 401;

    /// Insufficient repay amount provided for flashloan
    const ERR_CONCENTRATED_POOL_FLASHLOAN_INSUFFICIENT_REPAY: u64 = 402;

    /// Invalid amount provided for flashloan
    const ERR_CONCENTRATED_POOL_FLASHLOAN_INVALID_AMOUNT: u64 = 403;

    /// Flashloan operations are paused
    const ERR_CONCENTRATED_POOL_FLASHLOAN_PAUSED: u64 = 405;

    // Position Conditions
    /// Position does not exist
    const ERR_CONCENTRATED_POOL_POSITION_NOT_EXISTS: u64 = 500;

    // Param Conditions

    /// Imbalanced array lengths for swap fee multipliers
    const ERR_CONCENTRATED_POOL_SWAP_FEE_MULTIPLIER_ARRAY_LENGTH_MISMATCH: u64 = 600;

    /// Swap fee multiplier input ratio greater than one
    const ERR_CONCENTRATED_POOL_SWAP_FEE_MULTIPLIER_INPUT_RATIO_GT_ONE: u64 = 601;

    // Rate Limit Conditions

    /// Rate limiter does not exist for asset
    const ERR_CONCENTRATED_POOL_NO_RATE_LIMITER_FOR_ASSET: u64 = 703;

    // Invariants
    // NOTE: These errors are NOT covered in unit tests as they are not expected to be thrown

    /// Pool liquidity shouldn't change due to liquidity add/removal
    const ERR_CONCENTRATED_POOL_INVARIANT_TICK_CHANGE_AFTER_LIQUIDITY_CHANGE: u64 = 800;

    /// Pool liquidity should increase by liquidity delta after add
    const ERR_CONCENTRATED_POOL_INVARIANT_POOL_LIQUIDITY_CHANGE_INACCURATE_AFTER_ADD: u64 = 801;

    /// Tick liquidity gross should increase by liquidity delta after add
    const ERR_CONCENTRATED_POOL_INVARIANT_TICK_LIQUIDITY_GROSS_CHANGE_INACCURATE_AFTER_ADD: u64 = 802;

    /// Tick liquidity net should increase by liquidity delta after add
    const ERR_CONCENTRATED_POOL_INVARIANT_TICK_LIQUIDITY_NET_CHANGE_INACCURATE_AFTER_ADD: u64 = 803;

    /// Removing > 0 liquidity should decrease liquidity
    const ERR_CONCENTRATED_POOL_INVARIANT_REMOVE_LIQUIDITY_NOT_DECREASE_POOL_LIQUIDITY: u64 = 804;

    /// Removing liquidity should decrease the associated tick's liquidity
    const ERR_CONCENTRATED_POOL_INVARIANT_REMOVE_LIQUIDITY_NOT_DECREASE_TICK_LIQUIDITY: u64 = 805;

    /// Removing 0 liquidity should not decrease liquidity
    const ERR_CONCENTRATED_POOL_INVARIANT_REMOVE_ZERO_LIQUIDITY_CHANGES_LIQUIDITY: u64 = 806;

    /// If tick does not change during a swap, liquidity should remain constant
    const ERR_CONCENTRATED_POOL_INVARIANT_LIQUIDITY_CHANGE_TICK_CONSTANT: u64 = 807;

    /// Fee growth of asset_in should not decrease throughout a swap
    const ERR_CONCENTRATED_POOL_INVARIANT_FEE_GROWTH_DECREASE_AFTER_SWAP: u64 = 808;

    /// Fee growth of asset_out should remain constant throughout a swap
    const ERR_CONCENTRATED_POOL_INVARIANT_FEE_GROWTH_CHANGE_ASSET_OUT: u64 = 809;

    /// Swaps returning 0 amount in should not return a non-zero amount out
    const ERR_CONCENTRATED_POOL_INVARIANT_ZERO_IN_NONZERO_OUT: u64 = 810;

    /// Tick fee growth outside should not exceed global fee growth
    const ERR_CONCENTRATED_POOL_INVARIANT_TICK_FEE_GROWTH_OUTSIDE_EXCEEDS_GLOBAL_GROWTH: u64 = 811;

    /// Swaps should push prices in the right direction - A -> B should make A cheaper;
    const ERR_CONCENTRATED_POOL_INVARIANT_SWAP_PUSHES_PRICE_IN_INCORRECT_DIRECTION: u64 = 812;

    //
    // Resources
    //

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Clamm has key {
        /// Current protocol allocation as a percentage of the swap fee taken on withdrawal
        /// Represented in bps
        swap_fee_protocol_allocation_bps: u64,

        /// List of all pools
        pools: SmartVector<Object<Pool>>,

        swap_paused: bool,
        liquidity_paused: bool,
        flashloan_paused: bool,

        /// List of fee-adjusted users. Maps user address to swap fee multiplier
        trader_swap_fee_multipliers: SmartTable<address, u64>,

        /// List of addresses that are exempt from rate limiting
        rate_limit_exempt_addresses: vector<address>,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Pool has key {
        // immutable

        /// Metadata of asset 0
        metadata_0: Object<Metadata>,

        /// Metadata of asset 1
        metadata_1: Object<Metadata>,

        /// NFT collection object. Tokens are generated from this collection object
        collection_obj: Object<Collection>,

        /// Enables mutation of nft position collection
        mutator_ref: MutatorRef,

        oracle_obj: Object<TwapOracle>,

        /// Swap fee in basis points
        swap_fee_bps: u64,

        /// Pool tick spacing
        tick_spacing: u64,

        /// Maximum amount of position liquidity that any tick in the range can use
        max_liquidity_per_tick: u64,

        /// Extend reference used for fetching pool signer
        extend_ref: ExtendRef,

        // mutable

        /// Last utilized position number
        position_id: u64,

        /// Current sqrt price (64.64 representation)
        sqrt_price: u128,

        /// Current tick
        tick: I64,

        /// Lookup between tick and tick liquidity info
        ticks: SmartTable<I64, TickInfo>,

        /// Bitmap for ticks in tick table
        tick_bitmap: TickBitmap,

        /// Current in range liquidity available to the pool
        /// This value has no relationship to the total liquidity across all ticks
        liquidity: u64,

        /// The fees of metadata_0 collected per unit of liquidity for the entire life of the pool
        /// This value can overflow the uint256. The value is represented as a (64.64) number
        fee_growth_global_0: u128,

        /// The fees of metadata_1 collected per unit of liquidity for the entire life of the pool
        /// This value can overflow the uint256. The value is represented as a (64.64) number
        fee_growth_global_1: u128,

        /// true if there is a flashloan in progress, and other flashloan / swap / liquidity operations cannot be executed for the pool
        locked: bool,
    }

    struct TickInfo has store, copy, drop {
        /// The total position liquidity that references this tick
        liquidity_gross: u64,

        /// Amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        liquidity_net: I64,

        /// Fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        /// Only has relative meaning, not absolute, the value depends on when the tick is initialized
        fee_growth_outside_0: u128,
        fee_growth_outside_1: u128,

        /// The cumulative tick value on the other side of the tick
        tick_cumulative_outside: I128,

        /// Seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        /// Only has relative meaning, not absolute, the value depends on when the tick is initialized
        seconds_per_liquidity_outside: u128,

        /// The seconds spent on the other side of the tick (relative to the current tick)
        /// Only has relative meaning, not absolute, the value depends on when the tick is initialized
        seconds_outside: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Position has key {
        // immutable

        /// Position id of the position
        position_id: u64,

        /// Pool obj the position is tied to
        pool_obj: Object<Pool>,

        /// Tick lower
        tick_lower: I64,

        /// Tick upper
        tick_upper: I64,

        /// Used to manage fees stored at the position object
        extend_ref: ExtendRef,

        // mutable

        /// Amount of virtual liquidity since the last time the position struct was touched
        liquidity: u64,

        /// Tracks the amount of fees earned on token_0 (represented as 64.64)
        fee_growth_inside_0_last: u128,

        /// Tracks the amount of fees earned on token_1 (represented as 64.64)
        fee_growth_inside_1_last: u128,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct PositionCollection has key {
        collection_obj: Object<Collection>,
        mutator_ref: MutatorRef,
    }

    struct SwapCache has drop {
        /// Current value of the tick accumulator, computed only if we cross an initialized tick
        tick_cumulative: I128,

        /// Current value of seconds per liquidity accumulator, computed only if we cross an initialized tick (represented as 64.64)
        seconds_per_liquidity_cumulative: u128,

        /// Whether we've computed and cached the above two accumulators
        computed_latest_observation: bool,
    }

    struct SwapState has drop {
        /// Amount remaining to be swapped in/out of the input/output asset
        amount_specified_remaining: u64,

        /// Amount already swapped out/in of the output/input asset
        amount_calculated: u64,

        /// Current sqrt(price) (represented as 64.64)
        sqrt_price: u128,

        /// Tick associated with the current price
        tick: I64,

        /// Global fee growth of the input token (represented as 64.64)
        fee_growth_global: u128,

        /// Amount of input token paid as protocol fee
        protocol_fee: u64,

        /// Total amount of input allocated to fee
        total_fee: u64,

        /// Current liquidity in range
        liquidity: u64
    }

    /// Flashloan resource following "hot potato" pattern: https://medium.com/@borispovod/move-hot-potato-pattern-bbc48a48d93c
    /// This resource cannot be copied / dropped / stored, but can only be created and destroyed in the same module
    /// by `flashloan` and `pay_flashloan` functions
    struct Flashloan {
        pool_obj: Object<Pool>,
        amount_0: u64,
        amount_1: u64,
    }

    struct PositionInfo has drop {
        /// Position id of the position
        position_id: u64,

        /// Pool obj the position is tied to
        pool_obj: Object<Pool>,

        /// Tick lower
        tick_lower: I64,

        /// Tick upper
        tick_upper: I64,

        /// Amount of virtual liquidity since the last time the position struct was touched
        liquidity: u64,

        /// Most recent fee growth of asset 0 realized by position
        fee_growth_inside_0_last: u128,

        /// Most recent fee growth of asset 1 realized by position
        fee_growth_inside_1_last: u128,
    }

    struct LiquidityInvariantState has drop {
        /// Current pool tick
        tick: I64,

        /// Current pool liquidity
        liquidity: u64,

        /// liquidity_gross at a position's lower tick
        tick_lower_liquidity_gross: u64,

        /// liquidity_net at a position's lower tick
        tick_lower_liquidity_net: I64,

        /// liquidity_gross at a position's upper tick
        tick_upper_liquidity_gross: u64,

        /// liquidity_net at a position's upper tick
        tick_upper_liquidity_net: I64
    }

    struct SwapInvariantState has drop {
        /// Current pool tick
        tick: I64,

        /// Current pool liquidity
        liquidity: u64,

        /// Current global fee growth of asset_0 in a pool
        fee_growth_global_0: u128,

        /// Current global fee growth of asset_1 in a pool
        fee_growth_global_1: u128,

        /// Current balance of the asset provided in to the swap
        balance_in: u64,

        /// Current balance of asset returned out from the swap
        balance_out: u64,
    }

    struct I64 has copy, drop, store {}

    struct I128 has copy, drop, store {}

    struct TickBitmap has store {}

    // Events

    #[event]
    /// Event emitted when a pool is created
    struct PoolCreationEvent has drop, store {
        pool_obj: Object<Pool>,
        creator: address,
        metadata_0: Object<Metadata>,
        metadata_1: Object<Metadata>,
        sqrt_price: u128,
        swap_fee_bps: u64,
        collection_obj: Object<Collection>
    }

    #[event]
    /// Event emitted when a new liquidity position is added to a pool
    struct NewPositionEvent has drop, store {
        pool_obj: Object<Pool>,
        token_obj: Object<Token>,
        recipient: address,
    }

    #[event]
    /// Event emitted when a new liquidity position is added to a pool
    struct IncreaseLiquidityEvent has drop, store {
        pool_obj: Object<Pool>,
        metadata_0: Object<Metadata>,
        metadata_1: Object<Metadata>,
        token_obj: Object<Token>,
        recipient: address,
        amount_0: u64,
        amount_1: u64,
        refund_0: u64,
        refund_1: u64,
        liquidity: u64,
        pool_balance_0: u64,
        pool_balance_1: u64,
    }

    #[event]
    /// Event emitted when a liquidity is removed from a pool
    struct RemoveLiquidityEvent has drop, store {
        pool_obj: Object<Pool>,
        metadata_0: Object<Metadata>,
        metadata_1: Object<Metadata>,
        token_obj: Object<Token>,
        amount_0: u64,
        amount_1: u64,
        liquidity_delta: u64,
        pool_balance_0: u64,
        pool_balance_1: u64,
    }

    #[event]
    /// Event emitted when owed fees go from user position to user wallet
    struct CollectFeesEvent has drop, store {
        pool_obj: Object<Pool>,
        token_obj: Object<Token>,
        amount_0: u64,
        amount_1: u64,
    }

    #[event]
    /// Event emitted when owed fees go from pool to user position
    struct AccrueFeesEvent has drop, store {
        pool_obj: Object<Pool>,
        position_obj: Object<Position>,
        amount_0: u64,
        amount_1: u64,
    }

    #[event]
    /// Event emitted when a swap is executed
    struct SwapEvent has drop, store {
        pool_obj: Object<Pool>,
        metadata_0: Object<Metadata>,
        metadata_1: Object<Metadata>,
        zero_for_one: bool,
        exact_in: bool,
        amount_in: u64,
        amount_out: u64,
        refund_amount: u64,
        protocol_fee_amount: u64,
        fee_amount: u64,
        pool_balance_0: u64,
        pool_balance_1: u64,
        integrator: String,
    }

    #[event]
    /// Event emitted when a flashloan is executed
    struct FlashloanEvent has drop, store {
        pool_obj: Object<Pool>,
        borrow_amount_0: u64,
        borrow_amount_1: u64,
        repay_amount_0: u64,
        repay_amount_1: u64,
        protocol_fee_amount_0: u64,
        protocol_fee_amount_1: u64
    }

    #[event]
    /// Event emitted when a protocol parameter is changed
    struct PoolParamChangeEvent has drop, store {
        name: String,
        prev_value: u64,
        new_value: u64
    }

    #[event]
    struct RateLimitUpdateEvent has drop, store {
        asset_metadata: Object<Metadata>,
        window_max_qty: u128,
        window_duration_seconds: u64,
    }

    ///
    /// Pool Methods
    ///

    public fun create_concentrated_pool(
        _account: &signer,
        _metadata_0: Object<Metadata>,
        _metadata_1: Object<Metadata>,
        _sqrt_price: u128,
        _swap_fee_bps: u64,
    ): (Object<Pool>) {
        abort 0
    }

    /// Creates a new position for the given recipient/tick_lower/tick_upper
    /// The amount of Asset0/Asset1 due depends on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// signer - The address for which the liquidity will be created
    /// tick_lower - The lower tick of the position in which to add liquidity
    /// tick_upper - The upper tick of the position in which to add liquidity
    /// liquidity - The amount of liquidity to mint
    /// asset_0 - the asset contributed to the pool in exchange for liquidity
    /// asset_1 - the asset contributed to the pool in exchange for liquidity
    /// @return asset_0 The amount of asset_0 remaining from minting the given amount of liquidity
    /// @return asset_1 The amount of asset_1 remaining from minting the given amount of liquidity
    /// @return token_obj The object representing the token minted in this pool
    public fun new_position(
        _recipient: address,
        _pool_obj: Object<Pool>,
        _liquidity_delta: u64,
        _asset_0: FungibleAsset,
        _asset_1: FungibleAsset,
        _tick_lower: I64,
        _tick_upper: I64,
    ): (Object<Token>, FungibleAsset, FungibleAsset) {
        abort 0
    }

    /// Adds liquidity to an existing position
    /// The amount of Asset0/Asset1 due depends on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// signer - The address for which the liquidity will be created
    /// tick_lower - The lower tick of the position in which to add liquidity
    /// tick_upper - The upper tick of the position in which to add liquidity
    /// liquidity - The amount of liquidity to mint
    /// asset_0 - the asset contributed to the pool in exchange for liquidity
    /// asset_1 - the asset contributed to the pool in exchange for liquidity
    /// @return asset_0 The amount of asset_0 remaining from minting the given amount of liquidity
    /// @return asset_1 The amount of asset_1 remaining from minting the given amount of liquidity
    /// @return token_obj The object representing the token minted in this pool
    public fun increase_liquidity(
        _account: &signer,
        _token_obj: Object<Token>,
        _liquidity_delta: u64,
        _asset_0: FungibleAsset,
        _asset_1: FungibleAsset,
    ): (Object<Token>, FungibleAsset, FungibleAsset) {
        abort 0
    }

    /// remove_liquidity subtracts liquidity from the sender and returns tokens owed to the sender.
    /// Also triggers a collection of fees owed to a position
    ///
    /// pool_obj - The pool for which to remove liquidity
    /// token_obj - The token/position for which to remove liquidity
    /// amount_out - How much liquidity to remove
    /// @return amount_0 The amount of Asset0 the recipient is owed
    /// @return amount_1 The amount of Asset1 the recipient is owed
    public fun remove_liquidity(
        _account: &signer,
        _token_obj: Object<Token>,
        _liquidity_delta: u64,
    ): (FungibleAsset, FungibleAsset) {
        abort 0
    }

    /// Collects tokens owed to a position
    /// Does not recompute fees earned, which must be done either via add_liquidity or remove_liquidity of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only asset_0 or only asset_1, amount_0_requested or
    /// amount_1_requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. uint64_max. Coins owed may be from accumulated swap fees or burned liquidity.
    /// token_obj - The token/position for which to remove liquidity
    /// @return Asset0 The amount of fees collected in Asset0
    /// @return Asset1 The amount of fees collected in Asset1
    public fun collect_fees(
        _account: &signer,
        _token_obj: Object<Token>
    ): (FungibleAsset, FungibleAsset) {
        abort 0
    }

    /// Swap asset In to Out via a given pool. Considerate of trading fee overrides.
    ///
    /// @param user - The user who is swapping
    /// @param pool_obj - The pool for which the swap will take place
    /// @param asset_in - The max asset input allocated to the swap. If swap exact in, the full amount provided to the swap, if swap exact out, the maximum amount of asset_in that can be spent
    /// @param amount_out - if swap exact in, the minimum amount of asset out to receive, if swap exact out, the exact amount of asset out to receive
    /// @param sqrt_price_limit - If zero for one, the price cannot be less than this value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param exact_in - If true, the swap will be exact in, if false, the swap will be exact out
    /// @return FA - FA representing the refund of asset_in returned from the swap
    /// @return FA - FA representing the amount of asset_out returned from the swap
    public fun swap(
        _user: &signer,
        _pool_obj: Object<Pool>,
        _asset_in: FungibleAsset,
        _amount_out: u64,
        _sqrt_price_limit: u128,
        _exact_in: bool,
        _integrator: String,
    ): (FungibleAsset, FungibleAsset) {
        abort 0
    }

    /// Swap asset In to Out via a given pool.
    ///
    /// @param pool_obj - The pool for which the swap will take place
    /// @param asset_in - The max asset input allocated to the swap. If swap exact in, the full amount provided to the swap, if swap exact out, the maximum amount of asset_in that can be spent
    /// @param amount_out - if swap exact in, the minimum amount of asset out to receive, if swap exact out, the exact amount of asset out to receive
    /// @param sqrt_price_limit - If zero for one, the price cannot be less than this value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param exact_in - If true, the swap will be exact in, if false, the swap will be exact out
    /// @return FA - FA representing the refund of asset_in returned from the swap
    /// @return FA - FA representing the amount of asset_out returned from the swap
    public fun swap_without_fee_exemptions(
        _pool_obj: Object<Pool>,
        _asset_in: FungibleAsset,
        _amount_out: u64,
        _sqrt_price_limit: u128,
        _exact_in: bool,
        _integrator: String,
    ): (FungibleAsset, FungibleAsset) {
        abort 0
    }

    /// Get flash loan coins.
    /// We allow borrowing any assets
    /// Returns loan coins along with Flashloan resource
    public fun flashloan(
        _pool_obj: Object<Pool>,
        _amount_0: u64,
        _amount_1: u64,
    ): (FungibleAsset, FungibleAsset, Flashloan) {
        abort 0
    }

    /// Pay flash loan coins and destroy the Flashloan resource.
    /// User must pay back the loan coins plus the fee.
    public fun pay_flashloan(
        _asset_0: FungibleAsset,
        _asset_1: FungibleAsset,
        _loan: Flashloan
    ) {
        abort 0
    }

    /// Snapshot the tick_cumulative, seconds_per_liquidity, and time a tick set was active
    /// Mirrors UniswapV3Pool.snapshotCumulativesInside
    public fun snapshot_cumulatives_inside(_token_obj: Object<Token>): (I128, u128, u64) {
        abort 0
    }

    public entry fun set_pool_collection_name(_manager: &signer, _pool_obj: Object<Pool>, _name: String) {
        abort 0
    }

    public entry fun set_pool_collection_description(_manager: &signer, _pool_obj: Object<Pool>, _description: String) {
        abort 0
    }

    public entry fun set_pool_collection_uri(_manager: &signer, _pool_obj: Object<Pool>, _uri: String) {
        abort 0
    }

    public fun pool_seed(_metadata_0: Object<Metadata>, _metadata_1: Object<Metadata>, _swap_fee_bps: u64): vector<u8> {
        abort 0
    }

    public fun clamm_collection_name(_metadata_0: Object<Metadata>, _metadata_1: Object<Metadata>, _swap_fee_bps: u64): String {
        abort 0
    }

    public fun clamm_token_name(_position_id: u64): String {
        abort 0
    }

    /// Returns position deposit id, liquidity, lower tick, and upper tick
    public fun unpack_position_info(_position_info: PositionInfo): (u64, Object<Pool>, u64, I64, I64) {
        abort 0
    }

    // Public Pool Helpers

    #[view]
    public fun liquidity_paused(): bool {
        abort 0
    }

    #[view]
    public fun swap_paused(): bool {
        abort 0
    }

    #[view]
    public fun flashloan_paused(): bool {
        abort 0
    }

    #[view]
    public fun pool_exists(_metadata_0: Object<Metadata>, _metadata_1: Object<Metadata>, _swap_fee_bps: u64): bool {
        abort 0
    }

    #[view]
    public fun pool_obj_exists(_pool_addr: address): bool {
        abort 0
    }

    #[view]
    public fun pool_obj(_metadata_0: Object<Metadata>, _metadata_1: Object<Metadata>, _swap_fee_bps: u64): Object<Pool> {
        abort 0
    }

    #[view]
    public fun pool_obj_from_token_obj(_token_obj: Object<Token>): Object<Pool> {
        abort 0
    }

    #[view]
    public fun pool_metadata(_pool_obj: Object<Pool>): (Object<Metadata>, Object<Metadata>) {
        abort 0
    }

    #[view]
    /// Returns the "effective" max tick a pool supports. Rounds in the direction of zero,
    /// returning the greatest tick that is a multiple of a pool's tick_spacing
    public fun max_tick(_pool_obj: Object<Pool>): I64 {
        abort 0
    }

    #[view]
    /// Returns the "effective" min tick a pool supports. Rounds in the direction of zero,
    /// returning the greatest tick that is a multiple of a pool's tick_spacing
    public fun min_tick(_pool_obj: Object<Pool>): I64 {
        abort 0
    }

    #[view]
    public fun swap_fee_bps(_pool_obj: Object<Pool>): u64 {
        abort 0
    }

    #[view]
    public fun swap_fee_protocol_allocation_bps(): u64 {
        abort 0
    }

    #[view]
    public fun tick_sqrt_price(_pool_obj: Object<Pool>): (I64, u128) {
        abort 0
    }

    #[view]
    public fun tick_spacing(_pool_obj: Object<Pool>): u64 {
        abort 0
    }

    #[view]
    public fun tick_at_sqrt_price(_sqrt_price: u128): (u64, bool) {
        abort 0
    }


    #[view]
    public fun sqrt_price_at_tick(_tick: u64, _tick_neg: bool): u128 {
        abort 0
    }

    #[view]
    public fun tick_liquidity_info(_pool_obj: Object<Pool>, _tick: u64, _tick_neg: bool): (u128, u64, I64) {
        abort 0
    }

    #[view]
    public fun tick_fee_growth_outside_info(_pool_obj: Object<Pool>, _tick: u64, _tick_neg: bool): (u128, u128) {
        abort 0
    }

    #[view]
    public fun liquidity(_pool_obj: Object<Pool>): u64 {
        abort 0
    }

    #[view]
    public fun num_ticks(_pool_obj: Object<Pool>): u64 {
        abort 0
    }

    #[view]
    public fun num_tick_buckets(_pool_obj: Object<Pool>): u64 {
        abort 0
    }

    #[view]
    public fun next_initialized_tick(_pool_obj: Object<Pool>, _zero_for_one: bool): (u64, bool, bool) {
        abort 0
    }

    #[view]
    public fun ticks(_pool_obj: Object<Pool>): SimpleMap<I64, TickInfo> {
        abort 0
    }

    #[view]
    public fun ticks_paginated(_pool_obj: Object<Pool>, _start_bucket_index: u64, _start_vector_index: u64, _num_keys_to_get: u64): (SimpleMap<I64, TickInfo>, Option<u64>, Option<u64>) {
        abort 0
    }

    #[view]
    public fun global_fee_info(_pool_obj: Object<Pool>): (u128, u128) {
        abort 0
    }

    #[view]
    public fun next_position_id(_pool_obj: Object<Pool>): u64 {
        abort 0
    }

    #[view]
    public fun oracle_address(_pool_obj: Object<Pool>): address {
        abort 0
    }

    #[view]
    public fun oracle(_pool_obj: Object<Pool>): Object<TwapOracle> {
        abort 0
    }

    #[view]
    /// Returns the collection object associated with a pool
    public fun collection(_pool_obj: Object<Pool>): Object<Collection> {
        abort 0
    }

    #[view]
    /// Returns position info struct
    public fun position_info(_token_obj: Object<Token>): PositionInfo {
        abort 0
    }

    #[view]
    public fun pools(): vector<Object<Pool>> {
        abort 0
    }

    #[view]
    /// Get a list of balances
    public fun pool_balances(_pool_obj: Object<Pool>): (u64, u64) {
        abort 0
    }

    #[view]
    /// Returns the maximum liquidity added per tick
    public fun max_liquidity_per_tick(_pool_obj: Object<Pool>): u64 {
        abort 0
    }

    #[view]
    /// Return the fees available in a position
    /// We use the `position_obj` because we don't have the signer in this context
    public fun fees_available(_token_obj: Object<Token>): (u64, u64) {
        abort 0
    }

    #[view]
    public fun exists_asset_remove_liquidity_rate_limiter(_asset_metadata: Object<Metadata>): bool {
        abort 0
    }

    #[view]
    fun asset_remove_liquidity_rate_limiter_remaining(_asset_metadata: Object<Metadata>): u128 {
        abort 0
    }

    #[view]
    public fun user_remove_liquidity_rate_limit_exempt(_account_addr: address): bool {
        abort 0
    }

    #[view]
    public fun remove_liquidity_rate_limit_exempt_users(): vector<address> {
        abort 0
    }

    #[view]
    public fun trader_swap_fee_multiplier(_trader_address: address): u64 {
        abort 0
    }

    #[view]
    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioA A sqrt price representing the first tick boundary
    /// @param sqrtRatioB A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    public fun liquidity_for_amount_0(
        _sqrt_ratio_a: u128,
        _sqrt_ratio_b: u128,
        _amount_0: u64
    ): u64 {
        abort 0
    }

    #[view]
    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioA A sqrt price representing the first tick boundary
    /// @param sqrtRatioB A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    public fun liquidity_for_amount_1(
        _sqrt_ratio_a: u128,
        _sqrt_ratio_b: u128,
        _amount_1: u64
    ): u64 {
        abort 0
    }

    #[view]
    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrt_ratio A sqrt price representing the current pool prices
    /// @param sqrt_ratio_a A sqrt price representing the first tick boundary
    /// @param sqrt_ratio_b A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    public fun liquidity_for_amounts(
        _sqrt_ratio: u128,
        _sqrt_ratio_a: u128,
        _sqrt_ratio_b: u128,
        _amount_0: u64,
        _amount_1: u64
    ): u64 {
        abort 0
    }

    #[view]
    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrt_ratio_a A sqrt price representing the first tick boundary
    /// @param sqrt_ratio_b A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @param liquidity_is_neg Whether the liquidity is negative. Influences rounding direction
    /// @return amount0 The amount of token0
    public fun amount_0_for_liquidity(
        _sqrt_ratio_a: u128,
        _sqrt_ratio_b: u128,
        _liquidity_u64: u64,
        _liquidity_is_neg: bool
    ): u64 {
        abort 0
    }

    #[view]
    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrt_ratio_a A sqrt price representing the first tick boundary
    /// @param sqrt_ratio_b A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @param liquidity_is_neg Whether the liquidity is negative. Influences rounding direction
    /// @return amount1 The amount of token1
    public fun amount_1_for_liquidity(
        _sqrt_ratio_a: u128,
        _sqrt_ratio_b: u128,
        _liquidity_u64: u64,
        _liquidity_is_neg: bool
    ): u64 {
        abort 0
    }

    #[view]
    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrt_ratio A sqrt price representing the current pool prices
    /// @param sqrt_ratio_a A sqrt price representing the first tick boundary
    /// @param sqrt_ratio_b A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    public fun amounts_for_liquidity(
        _sqrt_ratio: u128,
        _sqrt_ratio_a: u128,
        _sqrt_ratio_b: u128,
        _liquidity_u64: u64,
        _liquidity_is_neg: bool
    ): (u64, u64) {
        abort 0
    }

    #[view]
    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param zero_for_one Whether the token passed to the quote is in token0 or token1 in the pool
    /// @param base_amount Amount of token to be converted
    /// @param tick Tick value used to calculate the quote
    /// @param tick_neg Tick sign used to calculate the quote
    /// @return quote_amount Amount of quoteToken received for baseAmount of baseToken
    public fun quote_at_tick(_zero_for_one: bool, _base_amount: u64, _tick: u64, _tick_neg: bool): u64 {
        abort 0
    }

    #[view]
    public fun initialized_ticks_crossed(_pool_obj: Object<Pool>, _tick_before: u64, _tick_before_neg: bool, _tick_after: u64, _tick_after_neg: bool): u16 {
        abort 0
    }

    #[view]
    /// returns (amount_in, amount_out, protocol_fee_amount)
    public fun preview_swap(_pool_obj: Object<Pool>, _asset_in_metadata: Object<Metadata>, _amount: u64, _sqrt_price_limit: u128, _exact_in: bool, _trader: Option<address>): (u64, u64, u64, u64) {
        abort 0
    }

    #[view]
    /// Returns the total value of a position object in terms of amount_0 & amount_1
    /// - Includes both principal token value & pending fees owed
    public fun position_total_value(_token_obj: Object<Token>): (u64, u64) {
        abort 0
    }

    #[view]
    /// Returns the value of the principal deposited to a position object in terms of amount_0 & amount_1
    public fun position_principal_value(_token_obj: Object<Token>): (u64, u64) {
        abort 0
    }

    #[view]
    /// Returns the fee growth inside at a specific tickLower/tickUpper pair.
    /// Can be used to compute APY % during position previews
    /// To Compute APY:
    /// - 1. Call view_fee_growth_inside() with ledgerVersion = current
    /// - 2. Call view_fee_growth_inside() with ledgerVersion = current - "X" hours
    /// - 3. Compute APY %
    /// -----3a. amount_0_X_hours = (fee_growth_inside_0_current - fee_growth_inside_0_previous) * position.liquidity(t=current)
    /// -----3b. amount_1_X_hours = (fee_growth_inside_1_current - fee_growth_inside_1_previous) * position.liquidity(t=current)
    /// -----3c. position_value = amounts_for_liquidity(pool.sqrt_price, tick_math::get_sqrt_ratio_at_tick(tick_lower), tick_math::get_sqrt_ratio_at_tick(tick_upper), liquidity, true)
    /// -----3d. fees_earned_USD = (amount_0_X_hours * USD/amount_0 + amount_1_X_hours * USD/amount_1)
    /// -----3e. position_value_USD = (position_value_0 * USD/amount_0 + position_value_1 * USD/amount_1)
    /// -----3f. APY % = (fees_earned_USD / position_value_USD) * (seconds_in_year / X_hours_seconds) * 100
    public fun view_fee_growth_inside(_pool_obj: Object<Pool>, _tick_lower_u64: u64, _tick_lower_neg: bool, _tick_upper_u64: u64, _tick_upper_neg: bool): (u128, u128) {
        abort 0
    }
}