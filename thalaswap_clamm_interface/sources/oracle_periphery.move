module thalaswap_clamm::oracle_periphery {
    use aptos_framework::object::Object;

    use thalaswap_clamm::pool::Pool;

    struct I64 {}
    struct I128 {}

    /// Amount out less than requested
    const ERR_ORACLE_TIMESTAMP_TOO_OLD: u64 = 1;

    /// Invalid seconds ago
    const ERR_ORACLE_ZERO_SECONDS_AGO: u64 = 2;

    #[view]
    /// @notice Fetches tick_cumulative and seconds_per_liquidity_cumulative on an oracle at any timestamp.
    /// - If timestamp is older than oldest observation, abort
    /// - If timestamp exists in obervation table, return data
    /// - If timestamp is in between observation table entries, interpolate
    /// - If timestamp is after last observation, extrapolate
    /// Returns (tick_cumulative, seconds_per_liquidity_cumulative)
    public fun tick_liquidity_accumulators(_pool_obj: Object<Pool>, _timestamp: u64): (I128, u128) {
        abort 0
    }

    #[view]
    /// Computes tick/seconds_per_liquidity TWAP looking back seconds_ago duration.
    /// Returns (average_tick, average_seconds_per_liquidity) over past seconds_ago
    public fun consult_oracle(_pool_obj: Object<Pool>, _seconds_ago: u64): (I64, u128) {
        abort 0
    }
}
