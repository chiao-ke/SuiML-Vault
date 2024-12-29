# ModelNFT Smart Contract Guide

## Contract Details
- Package ID: `0xecc39d1e6c9b376a809d9f9035049a9d3410ded1301799d67887153ee6114220`
- Network: Sui Testnet

## Functions

### 1. Mint a New ModelNFT

```bash
# Mint a new NFT
sui client call --package 0xecc39d1e6c9b376a809d9f9035049a9d3410ded1301799d67887153ee6114220 \
  --module model_nft \
  --function mint_model_nft \
  --args "Test NFT 1" \                  # nft_name
         "EsR5u_n9rzuIoCglYWmviFK2Gv7VgiSCYGkNXbiGPDw" \  # model_id
         "Test Model" \                   # name
         "This is a test model" \         # description
         "encryption_key_here" \          # encryption_key
         "original_hash_here" \           # original_hash
         "encrypted_hash_here" \          # encrypted_hash
         "https://your-project-url.com" \ # project_url
         "https://your-image-url.com" \   # image_url
         "[]" \                          # initial_allowed_addresses (empty array)
  --gas-budget 100000000
```

### 2. Add Allowed Address

```bash
# Add an address that can access the model
sui client call --package 0xecc39d1e6c9b376a809d9f9035049a9d3410ded1301799d67887153ee6114220 \
  --module model_nft \
  --function add_allowed_address \
  --args "$ADMIN_CAP_ID" \      # AdminCap object ID
         "$NFT_ID" \            # NFT object ID
         "$ADDRESS_TO_ADD" \    # Address to grant access
  --gas-budget 100000000
```

### 3. Remove Allowed Address

```bash
# Remove an address from accessing the model
sui client call --package 0xecc39d1e6c9b376a809d9f9035049a9d3410ded1301799d67887153ee6114220 \
  --module model_nft \
  --function remove_allowed_address \
  --args "$ADMIN_CAP_ID" \      # AdminCap object ID
         "$NFT_ID" \            # NFT object ID
         "$ADDRESS_TO_REMOVE" \ # Address to remove access
  --gas-budget 100000000
```

### 4. Update Model Hash

```bash
# Update the model's hash (both original and encrypted)
sui client call --package 0xecc39d1e6c9b376a809d9f9035049a9d3410ded1301799d67887153ee6114220 \
  --module model_nft \
  --function update_model_hash \
  --args "$ADMIN_CAP_ID" \      # AdminCap object ID
         "$NFT_ID" \            # NFT object ID
         "$NEW_ORIGINAL_HASH" \ # New original hash
         "$NEW_ENCRYPTED_HASH" \ # New encrypted hash
  --gas-budget 100000000
```

### 5. Update Encryption Key

```bash
# Update the model's encryption key
sui client call --package 0xecc39d1e6c9b376a809d9f9035049a9d3410ded1301799d67887153ee6114220 \
  --module model_nft \
  --function update_encryption_key \
  --args "$ADMIN_CAP_ID" \      # AdminCap object ID
         "$NFT_ID" \            # NFT object ID
         "$NEW_KEY" \           # New encryption key
  --gas-budget 100000000
```

### 6. Transfer NFT

```bash
# Transfer the NFT to another address
sui client call --package 0xecc39d1e6c9b376a809d9f9035049a9d3410ded1301799d67887153ee6114220 \
  --module model_nft \
  --function transfer \
  --args "$NFT_ID" \           # NFT object ID
         "$RECIPIENT_ADDRESS" \ # Address to transfer to
  --gas-budget 100000000
```

## Display Standard
The NFT will display the following information on Suiscan and other NFT explorers:
- Name: The NFT name you provided
- Description: The description you provided
- Model ID: The Arweave transaction ID
- Creator: Your address
- Project URL: Custom URL you provided
- Image URL: Custom URL you provided

## Example Usage

1. First, mint a new NFT:
```bash
sui client call --package 0xecc39d1e6c9b376a809d9f9035049a9d3410ded1301799d67887153ee6114220 \
  --module model_nft \
  --function mint_model_nft \
  --args "Test NFT 1" \
         "EsR5u_n9rzuIoCglYWmviFK2Gv7VgiSCYGkNXbiGPDw" \
         "Test Model" \
         "This is a test model" \
         "e1938460c11217dca63248647d9fc34d5987e293c9e2d6b4277cc6d2fced91fb" \
         "original_hash_here" \
         "encrypted_hash_here" \
         "https://arweave.net/EsR5u_n9rzuIoCglYWmviFK2Gv7VgiSCYGkNXbiGPDw" \
         "https://arweave.net/EsR5u_n9rzuIoCglYWmviFK2Gv7VgiSCYGkNXbiGPDw" \
         "[]" \
  --gas-budget 100000000
```

2. After minting, you'll receive:
   - An NFT object ID
   - An AdminCap object ID

3. Use these IDs to perform other operations like adding allowed addresses or updating the model.