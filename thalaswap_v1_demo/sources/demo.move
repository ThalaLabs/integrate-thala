module thalaswap_v1_demo::demo {

    use aptos_framework::coin::{Self, Coin};

    use thalaswap_v1_interface::stable_pool;
    use thalaswap_v1_interface::weighted_pool;

    // Weighted Methods

    public fun swap_x_y_z_weighted<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, Asset4, Asset5, Asset6, Asset7, Weight4, Weight5, Weight6, Weight7, X, Y, Z>(
        user: &signer,
        amount_in: u64,
    ): Coin<Z> {
        // Swaps between x -> y -> z through pools 0 & 1
        let x = coin::withdraw<X>(user, amount_in);
        let y = weighted_pool::swap_exact_in<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3, X, Y>(x);
        let z = weighted_pool::swap_exact_in<Asset4, Asset5, Asset6, Asset7, Weight4, Weight5, Weight6, Weight7, Y, Z>(y);
        z
    }

    fun flash_borrow_x_repay_y_weighted<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(
        borrow_amount_0: u64,
        borrow_amount_1: u64,
        borrow_amount_2: u64,
        borrow_amount_3: u64,
    ) {
        let (borrowed_0, borrowed_1, borrowed_2, borrowed_3, flashloan_receipt) = weighted_pool::flashloan<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(borrow_amount_0, borrow_amount_1, borrow_amount_2, borrow_amount_3);
        // turn borrowed into repaid
        // ...

        weighted_pool::pay_flashloan<Asset0, Asset1, Asset2, Asset3, Weight0, Weight1, Weight2, Weight3>(borrowed_0, borrowed_1, borrowed_2, borrowed_3, flashloan_receipt);
    }

    // Stable Methods

    public fun swap_x_y_z_stable<Asset0, Asset1, Asset2, Asset3, Asset4, Asset5, Asset6, Asset7, X, Y, Z>(
        user: &signer,
        amount_in: u64,
    ): Coin<Z> {
        // Swaps between x -> y -> z through pools 0 & 1
        let x = coin::withdraw<X>(user, amount_in);
        let y = stable_pool::swap_exact_in<Asset0, Asset1, Asset2, Asset3, X, Y>(x);
        let z = stable_pool::swap_exact_in<Asset4, Asset5, Asset6, Asset7, Y, Z>(y);
        z
    }

    fun flash_borrow_x_repay_y_stable<Asset0, Asset1, Asset2, Asset3>(
        borrow_amount_0: u64,
        borrow_amount_1: u64,
        borrow_amount_2: u64,
        borrow_amount_3: u64,
    ) {
        let (borrowed_0, borrowed_1, borrowed_2, borrowed_3, flashloan_receipt) = stable_pool::flashloan<Asset0, Asset1, Asset2, Asset3>(borrow_amount_0, borrow_amount_1, borrow_amount_2, borrow_amount_3);
        // turn borrowed into repaid
        // ...

        stable_pool::pay_flashloan<Asset0, Asset1, Asset2, Asset3>(borrowed_0, borrowed_1, borrowed_2, borrowed_3, flashloan_receipt);
    }
}