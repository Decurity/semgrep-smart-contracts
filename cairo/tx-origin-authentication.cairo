use starknet::ContractAddress;
use starknet::get_caller_address;

#[starknet::contract]
mod TxOrigin {
    #[storage]
    struct Storage {
        owner: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        // ruleid: tx-origin-authentication
        let contract_deployer = starknet::get_tx_info().unbox().account_contract_address;
        self.owner.write(contract_deployer)
    }

    #[external(v0)]
    fn authenticate_user(ref self: ContractState) {
        let tx_info = starknet::get_tx_info().unbox();
        let account = tx_info.account_contract_address;

        // ruleid: tx-origin-authentication
        assert(account == self.owner.read(), 1);
    }

    #[external(v0)]
    fn process_transaction(ref self: ContractState) {
        let info = starknet::get_tx_info().unbox();

        // ruleid: tx-origin-authentication
        if info.account_contract_address != self.owner.read() {
            return;
        }
    }

    #[external(v0)]
    fn correct_authentication(ref self: ContractState) {
        // ok: tx-origin-authentication
        assert(get_caller_address() == self.owner.read(), "Not Owner");
    }
}
