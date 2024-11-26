module thalaswap_v2_demo::demo {
    use aptos_framework::fungible_asset::{FungibleAsset, Metadata};
    use aptos_framework::object::Object;
    use aptos_framework::primary_fungible_store;

    use thalaswap_v2::pool::{Self, Pool};

    fun swap_x_y_z(
        account: &signer,
        pool_0: Object<Pool>,
        pool_1: Object<Pool>,
        metadata_x: Object<Metadata>,
        metadata_y: Object<Metadata>,
        metadata_z: Object<Metadata>,
        amount_x: u64
    ): FungibleAsset {
        let x = primary_fungible_store::withdraw(account, metadata_x, amount_x);
        let y = pool::swap_exact_in_weighted(account, pool_0, x, metadata_y);
        let z = pool::swap_exact_in_weighted(account, pool_1, y, metadata_z);
        z
    }

    fun flash_borrow_x_repay_y(
        account: &signer,
        pool: Object<Pool>,
        borrow_amount: u64,
    ) {
        let (borrowed, flashloan_receipt) = pool::flashloan(pool, vector[borrow_amount]);
        // turn borrowed into repaid
        // ...
        let repaid = borrowed;
        pool::pay_flashloan(repaid, flashloan_receipt);
    }
}
