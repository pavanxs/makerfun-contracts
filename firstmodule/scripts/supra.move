module exampleAddress::token {
    use std::string;
    use std::vector;
    use std::signer;
    use std::error;

    /// Error codes
    const ETOKEN_ALREADY_EXISTS: u64 = 1;
    const ETOKEN_NOT_FOUND: u64 = 2;
    const EINVALID_AMOUNT: u64 = 3;
    const EUNAUTHORIZED: u64 = 4;

    struct TokenInfo has key {
        name: string::String,
        symbol: string::String,
        decimals: u8,
        total_supply: u64,
        creator: address,
    }

    struct Balance has key {
        value: u64,
    }

    #[entry]
    public fun initialize(
        account: &signer,
        name: string::String,
        symbol: string::String,
        decimals: u8,
        total_supply: u64,
    ) {
        let creator_addr = signer::address_of(account);
        
        assert!(!exists<TokenInfo>(creator_addr), error::already_exists(ETOKEN_ALREADY_EXISTS));
        assert!(total_supply > 0, error::invalid_argument(EINVALID_AMOUNT));

        move_to(account, TokenInfo {
            name,
            symbol,
            decimals,
            total_supply,
            creator: creator_addr,
        });

        move_to(account, Balance { value: total_supply });
    }

    #[entry]
    public fun transfer(
        from: &signer,
        to: address,
        amount: u64,
    ) acquires Balance {
        let from_addr = signer::address_of(from);
        
        assert!(exists<Balance>(from_addr), error::not_found(ETOKEN_NOT_FOUND));
        assert!(amount > 0, error::invalid_argument(EINVALID_AMOUNT));

        // Create Balance resource for recipient if it doesn't exist
        if (!exists<Balance>(to)) {
            move_to(from, Balance { value: 0 });
        };

        // Handle the transfer with separate scopes for mutable borrows
        let from_balance = borrow_global_mut<Balance>(from_addr);
        assert!(from_balance.value >= amount, error::invalid_argument(EINVALID_AMOUNT));
        from_balance.value = from_balance.value - amount;

        let to_balance = borrow_global_mut<Balance>(to);
        to_balance.value = to_balance.value + amount;
    }

    #[view]
    public fun get_balance(owner: address): u64 acquires Balance {
        assert!(exists<Balance>(owner), error::not_found(ETOKEN_NOT_FOUND));
        borrow_global<Balance>(owner).value
    }

    #[view]
    public fun get_token_info(creator: address): (string::String, string::String, u8, u64) acquires TokenInfo {
        assert!(exists<TokenInfo>(creator), error::not_found(ETOKEN_NOT_FOUND));
        let info = borrow_global<TokenInfo>(creator);
        (info.name, info.symbol, info.decimals, info.total_supply)
    }
}