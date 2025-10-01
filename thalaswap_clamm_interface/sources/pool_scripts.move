module thalaswap_clamm::scripts {
    use std::string::String;

    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::Object;

    use aptos_token_objects::token::Token;

    use thalaswap_clamm::pool::Pool;


    /// Amount out less than requested
    const ERR_INSUFFICIENT_OUTPUT: u64 = 1;

    public entry fun create_concentrated_pool(_account: &signer, _metadata_0: Object<Metadata>, _metadata_1: Object<Metadata>, _sqrt_price: u128, _pool_swap_fee_bps: u64,) {
        abort 0
    }

    public entry fun new_position(_account: &signer, _pool_obj: Object<Pool>, _liquidity: u64, _amount_0: u64, _amount_1: u64, _tick_lower: u64, _tick_lower_neg: bool, _tick_upper: u64, _tick_upper_neg: bool) {
        abort 0
    }

    public entry fun increase_liquidity(_account: &signer, _token_obj: Object<Token>, _liquidity: u64, _amount_0: u64, _amount_1: u64) {
        abort 0
    }

    public entry fun remove_liquidity(_account: &signer, _token_obj: Object<Token>, _liquidity: u64, _min_amount_out_0: u64, _min_amount_out_1: u64) {
        abort 0
    }

    public entry fun swap(_account: &signer, _pool_obj: Object<Pool>, _amount_in: u64, _amount_out: u64, _sqrt_price_limit: u128, _exact_in: bool, _zero_for_one: bool, _integrator: String) {
        abort 0
    }

    public entry fun collect_fees(_ccount: &signer, _token_obj: Object<Token>) {
        abort 0
    }
}
