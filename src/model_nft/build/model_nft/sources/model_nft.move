module model_nft::model_nft {
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::event;
    use sui::dynamic_field as df;
    use sui::display;
    use sui::package;
    use std::string::{Self, String};
    use std::vector;

    // ====== Constants ======
    const ENotOwner: u64 = 1;
    const ENotAllowed: u64 = 2;
    const EInvalidAdminCap: u64 = 3;

    // One-time witness for the module
    struct MODEL_NFT has drop {}

    // Add a key struct for the encryption key dynamic field
    struct EncryptionKeyField has store, copy, drop { }

    struct AdminCap has key, store {
        id: UID,
        nft_id: ID
    }

    struct ModelNFT has key, store {
        id: UID,
        nft_name: String,
        model_id: String,
        name: String,
        description: String,
        created_at: u64,
        owner: address,
        creator: address,
        original_hash: String,
        encrypted_hash: String,
        allowed_addresses: Table<address, bool>,
        project_url: String,
        image_url: String
    }

    struct ModelInfo has copy, drop {
        nft_name: String,
        model_id: String,
        name: String,
        description: String,
        created_at: u64,
        owner: address,
        creator: address,
        project_url: String,
        image_url: String
    }

    // ====== Events ======

    struct ModelNFTMinted has copy, drop {
        creator: address,
        nft_name: String,
        model_id: String,
        nft_id: ID,
        project_url: String,
        image_url: String
    }

    struct AdminActionPerformed has copy, drop {
        nft_id: ID,
        action_type: String,
        admin: address
    }

    struct AccessGranted has copy, drop {
        nft_id: ID,
        granted_address: address
    }

    struct AccessRevoked has copy, drop {
        nft_id: ID,
        revoked_address: address
    }

    struct EncryptionKeyUpdated has copy, drop {
        nft_id: ID
    }

    struct ModelHashUpdated has copy, drop {
        nft_id: ID
    }

    // ====== Display ======
    fun init(witness: MODEL_NFT, ctx: &mut TxContext) {
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"description"),
            string::utf8(b"model_id"),
            string::utf8(b"creator"),
            string::utf8(b"project_url"),
            string::utf8(b"image_url"),
        ];

        let values = vector[
            string::utf8(b"{nft_name}"),
            string::utf8(b"{description}"),
            string::utf8(b"{model_id}"),
            string::utf8(b"{creator}"),
            string::utf8(b"{project_url}"),
            string::utf8(b"{image_url}"),
        ];

        let publisher = package::claim(witness, ctx);
        let display = display::new_with_fields<ModelNFT>(
            &publisher, 
            keys,
            values,
            ctx
        );
        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    // ====== Public Functions ======

    public entry fun mint_model_nft(
        nft_name: String,
        model_id: String,
        name: String,
        description: String,
        encryption_key: String,
        original_hash: String,
        encrypted_hash: String,
        project_url: String,
        image_url: String,
        initial_allowed_addresses: vector<address>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let nft_id = object::new(ctx);
        let id = object::uid_to_inner(&nft_id);

        let allowed_addresses = table::new(ctx);
        let i = 0;
        while (i < vector::length(&initial_allowed_addresses)) {
            let addr = *vector::borrow(&initial_allowed_addresses, i);
            table::add(&mut allowed_addresses, addr, true);
            i = i + 1;
        };

        let nft = ModelNFT {
            id: nft_id,
            nft_name,
            model_id,
            name,
            description,
            created_at: tx_context::epoch(ctx),
            owner: sender,
            creator: sender,
            original_hash,
            encrypted_hash,
            allowed_addresses,
            project_url,
            image_url
        };

        // Add encryption key as a dynamic field
        df::add(&mut nft.id, EncryptionKeyField {}, encryption_key);

        let cap = AdminCap {
            id: object::new(ctx),
            nft_id: id
        };

        event::emit(ModelNFTMinted {
            creator: sender,
            nft_name,
            model_id,
            nft_id: id,
            project_url,
            image_url
        });

        transfer::public_transfer(nft, sender);
        transfer::public_transfer(cap, sender);
    }

    public entry fun add_allowed_address(
        cap: &AdminCap,
        nft: &mut ModelNFT,
        new_address: address,
        ctx: &TxContext
    ) {
        assert!(cap.nft_id == object::uid_to_inner(&nft.id), EInvalidAdminCap);
        table::add(&mut nft.allowed_addresses, new_address, true);

        event::emit(AccessGranted {
            nft_id: object::uid_to_inner(&nft.id),
            granted_address: new_address
        });

        event::emit(AdminActionPerformed {
            nft_id: object::uid_to_inner(&nft.id),
            action_type: string::utf8(b"add_allowed_address"),
            admin: tx_context::sender(ctx)
        });
    }

    public entry fun remove_allowed_address(
        cap: &AdminCap,
        nft: &mut ModelNFT,
        remove_address: address,
        ctx: &TxContext
    ) {
        assert!(cap.nft_id == object::uid_to_inner(&nft.id), EInvalidAdminCap);
        table::remove(&mut nft.allowed_addresses, remove_address);

        event::emit(AccessRevoked {
            nft_id: object::uid_to_inner(&nft.id),
            revoked_address: remove_address
        });

        event::emit(AdminActionPerformed {
            nft_id: object::uid_to_inner(&nft.id),
            action_type: string::utf8(b"remove_allowed_address"),
            admin: tx_context::sender(ctx)
        });
    }

    public entry fun update_model_hash(
        cap: &AdminCap,
        nft: &mut ModelNFT,
        new_original_hash: String,
        new_encrypted_hash: String,
        ctx: &TxContext
    ) {
        assert!(cap.nft_id == object::uid_to_inner(&nft.id), EInvalidAdminCap);
        nft.original_hash = new_original_hash;
        nft.encrypted_hash = new_encrypted_hash;

        event::emit(ModelHashUpdated {
            nft_id: object::uid_to_inner(&nft.id)
        });

        event::emit(AdminActionPerformed {
            nft_id: object::uid_to_inner(&nft.id),
            action_type: string::utf8(b"update_model_hash"),
            admin: tx_context::sender(ctx)
        });
    }

    public entry fun transfer(nft: &mut ModelNFT, recipient: address, ctx: &TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(sender == nft.owner, ENotOwner);
        nft.owner = recipient;
    }

    public fun get_model_info(nft: &ModelNFT): ModelInfo {
        ModelInfo {
            nft_name: nft.nft_name,
            model_id: nft.model_id,
            name: nft.name,
            description: nft.description,
            created_at: nft.created_at,
            owner: nft.owner,
            creator: nft.creator,
            project_url: nft.project_url,
            image_url: nft.image_url
        }
    }

    public fun get_encryption_key(nft: &ModelNFT, ctx: &TxContext): String {
        let sender = tx_context::sender(ctx);
        assert!(sender == nft.owner, ENotOwner);
        assert!(table::contains(&nft.allowed_addresses, sender), ENotAllowed);
        *df::borrow(&nft.id, EncryptionKeyField {})
    }

    public entry fun update_encryption_key(
        cap: &AdminCap,
        nft: &mut ModelNFT,
        new_key: String,
        ctx: &TxContext
    ) {
        assert!(cap.nft_id == object::uid_to_inner(&nft.id), EInvalidAdminCap);
        
        // Update the encryption key in dynamic fields
        *df::borrow_mut(&mut nft.id, EncryptionKeyField {}) = new_key;

        event::emit(EncryptionKeyUpdated {
            nft_id: object::uid_to_inner(&nft.id)
        });

        event::emit(AdminActionPerformed {
            nft_id: object::uid_to_inner(&nft.id),
            action_type: string::utf8(b"update_encryption_key"),
            admin: tx_context::sender(ctx)
        });
    }

    // ====== View Functions ======

    public fun is_allowed_address(nft: &ModelNFT, addr: address): bool {
        table::contains(&nft.allowed_addresses, addr)
    }

    public fun get_owner(nft: &ModelNFT): address {
        nft.owner
    }

    public fun get_creator(nft: &ModelNFT): address {
        nft.creator
    }

    public fun get_nft_name(nft: &ModelNFT): String {
        nft.nft_name
    }

    public fun get_project_url(nft: &ModelNFT): String {
        nft.project_url
    }

    public fun get_image_url(nft: &ModelNFT): String {
        nft.image_url
    }
}
