

# STX-BlockGrounds

**STX-BlockGrounds** is a decentralized virtual land rental smart contract built on the **Stacks blockchain**, enabling users to mint, list, rent, and manage virtual land NFTs. The system ensures secure peer-to-peer rentals with time-limited tenancy enforced via on-chain logic.

---

## 📜 Contract Info

* **Name:** STX-BlockGrounds
* **Version:** 1.0.0
* **Language:** [Clarity](https://docs.stacks.co/docs/write-smart-contracts/clarity-overview)
* **Blockchain:** [Stacks](https://www.stacks.co/)
* **Implements:** SIP-009 NFT Trait *(add trait implementation when complete)*

---

## 📦 Features

* ✅ **Minting**: Admin can mint unique virtual land NFTs with metadata URI.
* ✅ **Listing for Rent**: NFT owners can list their land for rent with a price.
* ✅ **Renting**: Tenants can rent land for a specified block duration by paying STX.
* ✅ **Rental Expiry Enforcement**: Rental ends automatically after the specified time.
* ✅ **Tenant & Owner Protections**: Only authorized accounts can end a rental.
* ✅ **Read-only Queries**: Retrieve rental status, tenant info, and contract metadata.

---

## 📁 Contract Structure

### Constants

| Name                | Type   | Description                                                    |
| ------------------- | ------ | -------------------------------------------------------------- |
| `CONTRACT-NAME`     | string | Contract name                                                  |
| `CONTRACT-VERSION`  | string | Contract version                                               |
| `MAX-RENTAL-PERIOD` | uint   | Max allowed rental in blocks (default: 52,560 blocks ≈ 1 year) |

### Errors

| Code   | Name                        | Description                  |
| ------ | --------------------------- | ---------------------------- |
| `u100` | `err-owner-only`            | Only contract owner can mint |
| `u101` | `err-not-token-owner`       | Unauthorized NFT access      |
| `u102` | `err-token-not-found`       | NFT ID not found             |
| `u103` | `err-already-rented`        | NFT already rented           |
| `u104` | `err-not-rented`            | No active rental             |
| `u105` | `err-rental-expired`        | Rental expired               |
| `u106` | `err-invalid-rental-period` | Invalid rental duration      |
| `u404` | `err-exceeds-max-rental`    | Rental exceeds limit         |
| `u405` | `err-invalid-price`         | Rental price is 0            |
| `u406` | `ERR-NOT-AUTHORIZED`        | Caller not owner or tenant   |
| `u407` | `ERR-RENTAL-NOT-EXPIRED`    | Rental still active          |

---

## 🔨 Functions

### ✅ Public Functions

#### `mint-stx-virtual-land (recipient principal) (uri string)`

* Mint a new virtual land NFT.
* Only callable by contract owner.

#### `list-virtual-land-for-rent (token-id uint) (price uint)`

* List a land NFT for rent with a specified price in STX.
* Only callable by NFT owner.

#### `rent-virtual-land (token-id uint) (rental-period uint)`

* Pay in STX and start a rental for `rental-period` blocks.
* Ensures land is not already rented.

#### `end-virtual-land-rental (token-id uint)`

* Ends a rental after it expires.
* Callable by either the tenant or landowner.

### 📖 Read-only Functions

#### `get-contract-info`

* Returns contract name, version, and owner.

#### `get-token-uri (token-id uint)`

* Get metadata URI of an NFT.

#### `get-owner (token-id uint)`

* Returns owner of a specific token.

#### `get-rental-details (token-id uint)`

* Full rental information for a token.

#### `is-land-rented (token-id uint)`

* Boolean indicating if land is currently rented.

#### `get-land-tenant (token-id uint)`

* Returns the principal renting a given token (if any).

#### `get-rental-expiry (token-id uint)`

* Returns rental end block height.

#### `get-total-lands`

* Returns number of NFTs minted.

#### `get-active-rentals`

* Returns a count of currently rented lands. *(Static range in demo: token IDs 1–5)*

---

## 🧪 Example Workflow

1. **Admin mints virtual land:**

```clojure
(mint-stx-virtual-land 'SP...XYZ "ipfs://land-metadata-uri")
```

2. **Owner lists land for rent:**

```clojure
(list-virtual-land-for-rent u1 u5000)
```

3. **User rents land:**

```clojure
(rent-virtual-land u1 u1000) ;; Rents for 1,000 blocks
```

4. **Tenant or owner ends rental after expiration:**

```clojure
(end-virtual-land-rental u1)
```

---

## ⚠️ Security Notes

* Only the **contract deployer** can mint NFTs.
* Rental logic enforces block-based expiration; ensure block time aligns with expected durations (\~10 minutes per block).
* Token ownership does not transfer during rental.

---

## 📈 Future Improvements

* Add full SIP-009 trait compliance (currently implied, not implemented).
* Expand `get-active-rentals` to dynamically check all tokens.
* Integrate NFT transfers or marketplaces.
* Add events for rental activity (Clarity 2.1).

---

## 🤝 License

MIT License – Use freely with attribution.

---
