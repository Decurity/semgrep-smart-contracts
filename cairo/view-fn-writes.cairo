#[starknet::interface]
trait ISimpleStorage<TContractState> {
    fn set(ref self: TContractState, x: u128);
    fn get(self: @TContractState) -> u128;
}

#[starknet::contract]
mod SimpleStorage {
    #[storage]
    struct Storage {
        stored_data: u128
    }

    #[abi(embed_v0)]
    impl SimpleStorage of super::ISimpleStorage<ContractState> {
        // ok: view-fn-writes
        fn set(ref self: ContractState, x: u128) {
            self.stored_data.write(x);
        }

        // ruleid: view-fn-writes
        fn get(self: ContractState) -> u128 {
            self.stored_data.write(123);
        }
    }
}