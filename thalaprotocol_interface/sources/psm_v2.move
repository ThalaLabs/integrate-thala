module thalaprotocol_interface::psm_v2 {
    use aptos_framework::fungible_asset::{FungibleAsset, Metadata};
    use aptos_framework::object::{Object, ExtendRef};

    // Resources

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct PSM has key {
        extend_ref: ExtendRef,

        exchange_asset_metadata: Object<Metadata>,

        // Total number of mod tokens minted out of this PSM
        mod_minted: u64,
        // Maximum number of mod tokens that can be minted out of this PSM
        mint_cap: u64,

        mint_fee_bps: u64,
        redemption_fee_bps: u64,
    }

    public entry fun mint_coin_entry<CoinType>(_account: &signer, _psm_obj: Object<PSM>, _amount: u64) {
        abort 0
    }

    public entry fun mint_entry(_account: &signer, _psm_obj: Object<PSM>, _exchange_asset_metadata: Object<Metadata>, _amount: u64) {
        abort 0
    }

    /// Mint MOD tokens from the PSM.
    /// 
    /// Parameters:
    /// - `psm_obj`: The PSM object to mint the MOD tokens from.
    /// - `asset`: The underlying asset to mint the MOD tokens from.
    /// 
    /// Usage:
    /// 1. Ensure MOD mints are not paused
    /// 2. Ensure the PSM exists
    /// 3. Ensure the asset metadata matches the PSM's exchange asset metadata
    /// 4. Ensure the asset amount is not zero
    /// 5. Ensure we don't move past the mint cap with the amount of MOD to mint
    /// 6. Charge a fee on the exchange asset
    /// 7. Mint the MOD
    /// 8. Update the rate limiter: increment by the mod_amount
    public fun mint(_psm_obj: Object<PSM>, _asset: FungibleAsset): FungibleAsset {
        abort 0
    }

    public entry fun redeem_entry(_account: &signer, _psm_obj: Object<PSM>, _mod_amount: u64) {
        abort 0
    }

    /// Redeem MOD tokens from the PSM.
    /// 
    /// Parameters:
    /// - `psm_obj`: The PSM object to redeem the MOD tokens from.
    /// - `mod`: The MOD tokens to redeem for the underlying asset.
    /// 
    /// Usage:
    /// 1. Ensure MOD redemptions are not paused
    /// 2. Ensure the PSM exists
    /// 3. Ensure the mod metadata matches the PSM's exchange asset metadata
    /// 4. Ensure the mod amount is not zero
    /// 5. Ensure the mod amount is not greater than the PSM's balance of the exchange asset
    /// 6. Charge a fee on the exchange asset
    /// 7. Redeem the MOD
    /// 8. Update the rate limiter: decrement by the mod_amount
    public fun redeem(_psm_obj: Object<PSM>, _mod: FungibleAsset): FungibleAsset {
        abort 0
    }

    // Public PSM Helpers

    #[view]
    public fun psm_address(_exchange_asset_metadata: Object<Metadata>): address {
        abort 0
    }

    #[view]
    public fun balance(_psm_obj: Object<PSM>): u64 {
        abort 0
    }

    #[view]
    public fun mod_minted(_psm_obj: Object<PSM>): u64 {
        abort 0
    }

    #[view]
    public fun mintable_mod(_psm_obj: Object<PSM>): u64 {
        abort 0
    }

    #[view]
    public fun mintable_mod_rate_limited(_psm_obj: Object<PSM>): u64 {
        abort 0
    }

    #[view]
    public fun redeemable_mod(_psm_obj: Object<PSM>): u64 {
        abort 0
    }

    #[view]
    public fun redeemable_mod_rate_limited(_psm_obj: Object<PSM>): u64 {
        abort 0
    }

    #[view]
    public fun mint_cap(_psm_obj: Object<PSM>): u64 {
        abort 0
    }

    #[view]
    public fun psm_fees(_psm_obj: Object<PSM>): (u64, u64) {
        abort 0
    }

    #[view]
    public fun psm_open(_psm_obj: Object<PSM>): bool {
        abort 0
    }

    #[view]
    public fun mint_paused(): bool {
        abort 0
    }

    #[view]
    public fun redeem_paused(): bool {
        abort 0
    }

    #[view]
    public fun psm_rate_limiter_config(_psm_obj: Object<PSM>): (u64, u128, u64, u128) {
        abort 0
    }
}
