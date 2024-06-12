#[contract]
mod contract {
    struct Storage {}

    // ruleid: ok 
    #[external]
    fn get_variable((self: @ContractState) {}

    // ruleid: view-fn-mutable-state 
    #[external]
    fn GETTER((ref self: ContractState) {}
}
