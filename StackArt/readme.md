# StackArt NFT Protocol

A comprehensive NFT marketplace smart contract built on the Stacks blockchain using Clarity smart contract language. This protocol enables minting, trading, and managing non-fungible tokens with built-in marketplace functionality.

## Features

### Core NFT Functionality
- **Mint NFTs**: Create new unique digital assets with metadata
- **Transfer Assets**: Secure ownership transfers between users
- **Asset Registry**: Complete tracking of ownership and metadata

### Marketplace Features
- **Create Listings**: List NFTs for sale with custom pricing and duration
- **Buy Assets**: Purchase listed NFTs with automatic fee handling
- **Cancel Listings**: Remove assets from marketplace
- **Extend Listings**: Prolong listing duration for existing entries

### Administrative Controls
- **Commission Management**: Adjustable platform fees (max 15%)
- **Market Toggle**: Emergency pause/resume functionality
- **Access Control**: Admin-only administrative functions

## Smart Contract Structure

### Constants
- `admin`: Contract deployer with administrative privileges
- Error codes for various failure scenarios (100-109)

### Data Variables
- `market-active`: Global marketplace status
- `commission-rate`: Platform fee percentage (basis points)
- `total-minted`: Counter for total NFTs created

### Maps
- `asset-registry`: Stores NFT ownership and metadata
- `market-listings`: Active marketplace listings

## Function Reference

### Public Functions

#### Asset Management
```clarity
(mint-asset (uri-data (string-utf8 256)))
```
Creates a new NFT with specified metadata URI.

```clarity
(transfer-asset (asset-id uint) (from principal) (to principal))
```
Transfers NFT ownership between addresses.

#### Marketplace Operations
```clarity
(create-listing (asset-id uint) (ask-price uint) (duration uint))
```
Lists an NFT for sale with price and expiration.

```clarity
(buy-asset (asset-id uint))
```
Purchases a listed NFT, handling payments and transfers.

```clarity
(cancel-listing (asset-id uint))
```
Removes an NFT from marketplace listings.

```clarity
(prolong-listing (asset-id uint) (additional-time uint))
```
Extends the duration of an existing listing.

#### Administrative Functions
```clarity
(update-commission (new-rate uint))
```
Admin-only: Updates platform commission rate.

```clarity
(toggle-market)
```
Admin-only: Pauses/resumes marketplace operations.

### Read-Only Functions

```clarity
(get-asset-info (asset-id uint))
```
Returns complete asset information including owner and metadata.

```clarity
(get-listing-info (asset-id uint))
```
Returns marketplace listing details for an asset.

```clarity
(get-asset-owner (asset-id uint))
```
Returns the current owner of an asset.

```clarity
(get-total-supply)
```
Returns total number of minted NFTs.

```clarity
(get-asset-uri (asset-id uint))
```
Returns metadata URI for an asset.

## Security Features

### Input Validation
- Asset existence verification before operations
- Ownership verification for transfers and listings
- Price and duration validation
- Balance checks before purchases

### Access Control
- Owner-only transfers and listings
- Admin-only configuration changes
- Seller verification in marketplace operations

### Economic Safeguards
- Commission rate caps (maximum 15%)
- Automatic fee calculation and distribution
- Balance verification before transactions

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `err-unauthorized` | Insufficient permissions |
| 101 | `err-invalid-holder` | Invalid asset ownership |
| 102 | `err-missing-asset` | Asset does not exist |
| 103 | `err-no-listing` | No active marketplace listing |
| 104 | `err-low-balance` | Insufficient STX balance |
| 105 | `err-invalid-amount` | Invalid price or amount |
| 106 | `err-system-paused` | Marketplace is paused |
| 107 | `err-missing-uri` | Empty metadata URI |
| 108 | `err-invalid-duration` | Invalid listing duration |
| 109 | `err-admin-transfer` | Cannot transfer to admin |

## Usage Examples

### Minting an NFT
```clarity
;; Mint a new NFT with metadata
(contract-call? .stackart mint-asset "https://metadata.example.com/nft/1")
```

### Creating a Marketplace Listing
```clarity
;; List NFT #1 for 1000000 microSTX (1 STX) for 1000 blocks
(contract-call? .stackart create-listing u1 u1000000 u1000)
```

### Purchasing an NFT
```clarity
;; Buy NFT #1 from marketplace
(contract-call? .stackart buy-asset u1)
```

## Deployment

1. Deploy the contract to Stacks blockchain
2. The deployer becomes the admin automatically
3. Market is active by default with 3% commission rate
4. Users can immediately start minting and trading

## Fee Structure

- Default commission: 3% (300 basis points)
- Maximum commission: 15% (1500 basis points)
- Fees are automatically deducted during sales
- Revenue goes to contract admin

## Development

### Prerequisites
- Stacks blockchain development environment
- Clarity language support
- Stacks CLI tools

### Testing
Run the contract through Clarity checker:
```bash
clarity-cli check contract.clar
```

### Security Considerations
- All user inputs are validated
- Ownership checks prevent unauthorized operations
- Economic safeguards protect against common attacks
- Admin functions are properly restricted

## Contributing

1. Fork the repository
2. Create feature branch
3. Add comprehensive tests
4. Submit pull request with detailed description
