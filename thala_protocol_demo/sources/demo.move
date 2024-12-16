module thala_protocol_demo::demo {
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::fungible_asset::{FungibleAsset, Metadata};

    use thala_protocol_interface::psm_v2::{Self, PSM};

    // PSM V2 Methods

    /// Mint MOD tokens from the `x` token PSM.
    /// 
    /// Parameters:
    /// - `account`: The account holding the `x` token and receiving the minted MOD tokens.
    /// - `metadata_x`: The metadata of the `x` token.
    /// - `amount_x`: The amount of the `x` token to mint the MOD tokens against (1:1 ratio).
    /// 
    /// Returns:
    /// - The MOD tokens minted.
    fun mint(
        account: &signer,
        metadata_x: Object<Metadata>,
        amount_x: u64
    ): FungibleAsset {
        let x = primary_fungible_store::withdraw(account, metadata_x, amount_x);
        let psm_obj: Object<PSM> = object::address_to_object<PSM>(psm_v2::psm_address(metadata_x));
        psm_v2::mint(psm_obj, x)
    }
    
    /// Redeem MOD tokens from the `x` token PSM.
    /// 
    /// Parameters:
    /// - `account`: The account holding the MOD tokens and receiving the `x` tokens.
    /// - `metadata_x`: The metadata of the `x` token.
    /// - `metadata_mod`: The metadata of the MOD token.
    /// - `amount_mod`: The amount of MOD tokens to redeem for `x` tokens (1:1 ratio).
    /// 
    /// Returns:
    /// - The `x` tokens redeemed.
    fun redeem(
        account: &signer,
        metadata_x: Object<Metadata>,
        metadata_mod: Object<Metadata>,
        amount_mod: u64
    ): FungibleAsset {
        let mod = primary_fungible_store::withdraw(account, metadata_mod, amount_mod);
        let psm_obj: Object<PSM> = object::address_to_object<PSM>(psm_v2::psm_address(metadata_x));
        psm_v2::redeem(psm_obj, mod)
    }
}

