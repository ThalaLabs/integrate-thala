module thalaswap_clamm::oracle {
    use std::string::String;

    use aptos_framework::object::Object;

    struct I64 has copy, drop, store {}
    struct I128 has copy, drop, store {}

    friend thalaswap_clamm::pool;
    friend thalaswap_clamm::oracle_periphery;

    // constants

    /// Initial TWAP oracle capacity of 500 observations
    const DEFAULT_TWAP_ORACLE_OBSERVATION_CAPACITY: u64 = 500;

    /// Number of TWAP oracle observations that can be cleaned up in a single batch
    const TWAP_ORACLE_MAX_BATCH_CLEANUP_SIZE: u64 = 50;

    /// Maximum capacity of TWAP oracle observations that can be specified in admin setters
    const MAX_TWAP_ORACLE_OBSERVATION_CAPACITY: u64 = 3000;

    /// Minimum capacity of TWAP oracle observations that can be specified in admin setters
    /// Oracle MUST have at least 1 observation, else oracle will DoS pool operations
    /// A default of 10 observations is used to ensure consult_oracle has more ranges to work with by
    /// guaranteeing the existence of old enough observations
    const MIN_TWAP_ORACLE_OBSERVATION_CAPACITY: u64 = 10;

    const ORACLE_SEED: vector<u8> = b"oracle";

    // error codes

    /// Unauthorized caller
    const ERR_ORACLE_UNAUTHORIZED: u64 = 0;

    /// Oracle does not exist
    const ERR_ORACLE_NOT_EXIST: u64 = 1;

    /// Last observation timestamp greater than timestamp provided
    const ERR_ORACLE_TIMESTAMP_TOO_OLD: u64 = 2;

    /// Observation capacity provided less than minimum supported capacity
    const ERR_ORACLE_OBSERVATION_LENGTH_TOO_LOW: u64 = 3;

    /// Observation capacity provided greater than maximum supported capacity
    const ERR_ORACLE_OBSERVATION_LENGTH_TOO_HIGH: u64 = 4;

    /// Inputs provided have mismatched lengths
    const ERR_ORACLE_VECTOR_LENGTH_MISMATCH: u64 = 5;

    /// Timestamp not found in oracle
    const ERR_ORACLE_TIMESTAMP_NOT_EXIST: u64 = 6;

    /// Prev observation not exist
    const ERR_ORACLE_PREV_OBSERVATION_NOT_EXIST: u64 = 7;

    /// Next observation not exist
    const ERR_ORACLE_NEXT_OBSERVATION_NOT_EXIST: u64 = 8;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct OracleManager has key {
        observation_capacity: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct TwapOracle has key, drop {}

    /// Stores cumulative tick/seconds per liquidity data
    struct Observation has copy, drop, store {
        /// Timestamp of the update
        timestamp: u64,

        /// the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
        tick_cumulative: I128,

        /// the seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized (represented as 64.64)
        seconds_per_liquidity_cumulative: u128,

        /// Current tick value
        tick: I64,

        /// Current liquidity
        liquidity: u64,
    }

    #[event]
    /// Event emitted when a protocol parameter is changed
    struct OracleParamChangeEvent has drop, store {
        name: String,
        prev_value: u64,
        new_value: u64
    }

    #[event]
    /// Event emitted when a new oracle is created
    struct OracleCreationEvent has drop, store {
        oracle_obj: Object<TwapOracle>,
    }


    fun init_module(_account: &signer) {
        abort 0
    }

    //
    // Config & Param Management
    //

    public entry fun set_oracle_observation_capacity(_manager: &signer, _observation_capacity: u64) {
        abort 0
    }

    //
    // Oracle Methods
    //

    /// used to remove the first `num_observations` from the pool in the emergency event that excess observations are causing a DoS on any pool operations
    public entry fun trim_observations(_manager: &signer, _oracle_obj_vec: vector<Object<TwapOracle>>, _num_observations: vector<u64>)  {
        abort 0
    }

    public(friend) fun create_oracle(_creator: &signer): Object<TwapOracle> {
        abort 0
    }

    /// Attempt to update observations with (tick, liquidity)
    public(friend) fun write_twap(_oracle_obj: Object<TwapOracle>, _tick: I64, _liquidity: u64) {
        abort 0
    }

    // Internal Pool Helpers

    /// @notice Transforms a previous observation into a new observation using a linear extrapolation
    /// @dev Mirrors univ3._transform
    /// formulas:
    /// - tick_cumulative = lastObservation.tick_cumulative + tick * timeElapsed
    /// - seconds_per_liquidity_cumulative = lastObservation.seconds_per_liquidity_cumulative + (time_elapsed / liquidity)
    ///
    /// ex:
    /// - t = 30
    /// - oracle observation at time t = 20
    /// - tick_cumulative(t=20), seconds_per_liquidity_cumulative = 100, 100
    /// - tick = 5
    /// - liquidity = 5
    /// - tick_cumulative(t=30) = 100 + (5 * 10) = 150
    /// - seconds_per_liquidity_cumulative(t=30) = 100 + (10/5) = 102
    public(friend) fun extrapolate(_last_observation: &Observation, _timestamp: u64, _tick: I64, _liquidity: u64): (I128, u128) {
        abort 0
    }

    /// @notice Interpolates a new observation using data from surrounding observations
    /// formulas:
    /// - tick_cumulative = ((after_observation.tick_cumulative - before_observation.tick_cumulative) / observation_time_delta) * time_elapsed
    /// - seconds_per_liquidity_cumulative = (after_observation.seconds_per_liquidity_cumulative - before_observation.seconds_per_liquidity_cumulative) * time_elapsed / observation_time_delta
    ///
    /// ex:
    /// - oracle observations at time t = 10, 20
    /// - tick_cumulatives(t=10, t=20) = 1, 5
    /// - interpolate at time t=15
    /// - tickCumulative = 1 + ((5 - 1) / (20 - 10)) * (15 - 10) = 3
    public(friend) fun interpolate(_before_observation: &Observation, _after_observation: &Observation, _timestamp: u64): (I128, u128) {
        abort 0
    }

    /// Removes up to size_to_free observations from the TWAP oracle if the observations map is over-provisioned
    fun free_oldest_observations(_oracle_obj: Object<TwapOracle>, _size_to_free: u64)  {
        abort 0
    }

    //
    // View Methods
    //

    #[view]
    public fun last_observation(_oracle_obj: Object<TwapOracle>): Observation  {
        abort 0
    }

    #[view]
    public fun first_observation(_oracle_obj: Object<TwapOracle>): Observation  {
        abort 0
    }

    #[view]
    public fun fetch_observation(_oracle_obj: Object<TwapOracle>, _timestamp: u64): Observation {
        abort 0
    }

    public fun observation_info(_observation: Observation): (u64, I128, u128, I64, u64) {
        abort 0
    }

    public fun contains_timestamp(_oracle_obj: Object<TwapOracle>, _timestamp: u64): bool {
        abort 0
    }

    public fun prev_observation(_oracle_obj: Object<TwapOracle>, _timestamp: u64): Observation {
        abort 0
    }

    public fun next_observation(_oracle_obj: Object<TwapOracle>, _timestamp: u64): Observation {
        abort 0
    }

    #[view]
    public fun seed(): vector<u8> {
        ORACLE_SEED
    }
}
