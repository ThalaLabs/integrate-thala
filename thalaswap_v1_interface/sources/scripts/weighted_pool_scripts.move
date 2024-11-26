module thalaswap_v1_interface::weighted_pool_scripts {

    const ERR_LP_SLIPPAGE: u64 = 0;
    const ERR_INSUFFICIENT_OUTPUT: u64 = 1;

    public entry fun create_weighted_pool<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(_account: &signer, _in_0: u64, _in_1: u64, _in_2: u64, _in_3: u64) {
        abort 0
    }

    public entry fun swap_exact_in<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(_account: &signer, _amount_in: u64, _min_amount_out: u64) {
        abort 0
    }

    public entry fun swap_exact_out<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(_account: &signer, _amount_in: u64, _amount_out: u64) {
        abort 0
    }

    public entry fun add_liquidity<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(_account: &signer, _in_0: u64, _in_1: u64, _in_2: u64, _in_3: u64, _min_amount_in_0: u64, _min_amount_in_1: u64, _min_amount_in_2: u64, _min_amount_in_3: u64) {
        abort 0
    }

    public entry fun remove_liquidity<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(_account: &signer, _lp_token_in: u64, _min_amount_out_0: u64, _min_amount_out_1: u64, _min_amount_out_2: u64, _min_amount_out_3: u64) {
        abort 0
    }
}
