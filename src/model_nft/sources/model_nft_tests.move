#[test_only]
module model_nft::model_nft_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::transfer;
    use model_nft::model_nft::{Self, ModelNFT, AdminCap};
    use std::string;
    use std::vector;

    const EExpectedError: u64 = 999;

    #[test]
    fun test_mint_and_access() {
        let owner = @0xA;
        let allowed_user = @0xB;
        let not_allowed_user = @0xC;

        let scenario_val = ts::begin(owner);
        let scenario = &mut scenario_val;

        // Test minting
        test_mint(scenario, owner, allowed_user);
        
        ts::end(scenario_val);
    }

    fun test_mint(scenario: &mut Scenario, owner: address, allowed_user: address) {
        // Start from owner's context
        ts::next_tx(scenario, owner);
        {
            let initial_allowed = vector::empty<address>();
            vector::push_back(&mut initial_allowed, owner);
            vector::push_back(&mut initial_allowed, allowed_user);

            let (nft, cap) = model_nft::mint_model_nft(
                string::utf8(b"model_1"),
                string::utf8(b"Test Model"),
                string::utf8(b"Test Description"),
                string::utf8(b"test_key_123"),
                string::utf8(b"original_hash"),
                string::utf8(b"encrypted_hash"),
                initial_allowed,
                ts::ctx(scenario)
            );

            // Transfer NFT and AdminCap to owner
            transfer::public_transfer(nft, owner);
            transfer::public_transfer(cap, owner);
        };
    }

    #[test]
    #[expected_failure(abort_code = 1)]  // ENotOwner
    fun test_not_owner_cannot_access() {
        let owner = @0xA;
        let not_allowed_user = @0xC;
        let scenario_val = ts::begin(owner);
        let scenario = &mut scenario_val;

        // First mint the NFT
        ts::next_tx(scenario, owner);
        {
            let initial_allowed = vector::empty<address>();
            vector::push_back(&mut initial_allowed, owner);

            let (nft, cap) = model_nft::mint_model_nft(
                string::utf8(b"model_1"),
                string::utf8(b"Test Model"),
                string::utf8(b"Test Description"),
                string::utf8(b"test_key_123"),
                string::utf8(b"original_hash"),
                string::utf8(b"encrypted_hash"),
                initial_allowed,
                ts::ctx(scenario)
            );

            transfer::public_transfer(nft, owner);
            transfer::public_transfer(cap, owner);
        };

        // Try to access as not_allowed_user (should fail)
        ts::next_tx(scenario, not_allowed_user);
        {
            let nft = ts::take_from_address<ModelNFT>(scenario, owner);
            let _ = model_nft::get_encryption_key(&nft, ts::ctx(scenario));
            ts::return_to_address(owner, nft);
        };

        ts::end(scenario_val);
    }

    #[test]
    fun test_owner_can_access() {
        let owner = @0xA;
        let scenario_val = ts::begin(owner);
        let scenario = &mut scenario_val;

        // First mint the NFT
        ts::next_tx(scenario, owner);
        {
            let initial_allowed = vector::empty<address>();
            vector::push_back(&mut initial_allowed, owner);

            let (nft, cap) = model_nft::mint_model_nft(
                string::utf8(b"model_1"),
                string::utf8(b"Test Model"),
                string::utf8(b"Test Description"),
                string::utf8(b"test_key_123"),
                string::utf8(b"original_hash"),
                string::utf8(b"encrypted_hash"),
                initial_allowed,
                ts::ctx(scenario)
            );

            transfer::public_transfer(nft, owner);
            transfer::public_transfer(cap, owner);
        };

        // Access as owner (should succeed)
        ts::next_tx(scenario, owner);
        {
            let nft = ts::take_from_sender<ModelNFT>(scenario);
            let key = model_nft::get_encryption_key(&nft, ts::ctx(scenario));
            assert!(key == string::utf8(b"test_key_123"), 0);
            ts::return_to_sender(scenario, nft);
        };

        ts::end(scenario_val);
    }
}
