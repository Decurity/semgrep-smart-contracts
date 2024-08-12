#[starknet::contract]
mod SimpleStorage {
    #[storage]
    struct Storage {
        stored_data: u128
    }

    // ok: view-fn-writes
    fn set(ref self: ContractState, x: u128) {
        self.stored_data.write(x);
    }

    // ruleid: view-fn-writes
    fn get(self: ContractState) -> u128 {
        self.stored_data.write(123);
    }
}