#[starknet::contract]
mod contract {
    struct Storage {}

    // ok: view-fn-mutable-state 
    // #[external]
    // fn get_variable(self: @ContractState) {}

    // ruleid: view-fn-mutable-state 
    #[external]
    fn GETTER(ref self: ContractState) {}
}
