module thalaprotocol_demo::demo {
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::fungible_asset::{FungibleAsset, Metadata};

    use thalaprotocol_interface::psm_v2::{Self, PSM};

    // PSM V2 Methods

    fun mint(
        account: &signer,
        metadata_x: Object<Metadata>,
        amount_x: u64
    ): FungibleAsset {
        let x = primary_fungible_store::withdraw(account, metadata_x, amount_x);
        let psm_obj: Object<PSM> = object::address_to_object<PSM>(psm_v2::psm_address(metadata_x));
        psm_v2::mint(psm_obj, x)
    }
    
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

