module thalaswap_clamm::fees {
    use aptos_framework::fungible_asset::{FungibleAsset, Metadata};
    use aptos_framework::object::Object;

    friend thalaswap_clamm::pool;

    const FEE_MANAGER_ROLE: vector<u8> = b"fee_manager";

    ///
    /// Error Codes
    ///

    /// Unauthorized caller
    const ERR_UNAUTHORIZED: u64 = 0;

    ///
    /// Functions
    ///


    public(friend) fun absorb_fee(_fee: FungibleAsset) {
        abort 0
    }

    public fun withdraw_fee(_manager: &signer, _metadata: Object<Metadata>, _amount: u64): FungibleAsset {
        abort 0
    }

    public entry fun transfer_fee(_manager: &signer, _recipient: address, _fee_metadata: Object<Metadata>) {
        abort 0
    }
}
