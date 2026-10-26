# DATABASE.md - Database Schema Reference

> Last synced with code: v1.3.8 (`DatabaseConfig.version = 3`). Supplier, purchase, and product `costPrice`
> data are stored locally only and are not mirrored to Supabase yet.

Database: SQLite (`app_database.db`) via `sqflite`

## Migration Strategy

Database version is maintained in `DatabaseConfig` (currently **version 3**). On every startup, `_applyMigrations()`, `_applyMigrationsV3()`, and `_applyPurchaseMigrations()` in `DatabaseService` run idempotent `ALTER TABLE ADD COLUMN IF NOT EXISTS` / `CREATE TABLE IF NOT EXISTS` statements, normalize legacy barcodes, and create indexes. This means new columns/tables are added automatically without bumping the version number.

Source of truth: `lib/core/services/database/database_config.dart`. Seed data: 150 demo products on first install in debug builds only (`DatabaseService`), plus local seed users (`admin` / `kasir1` / `kasir2`) and the Supabase admin user.

## Tables

### User

| Column       | Type     | Constraints                |
| ------------ | -------- | -------------------------- |
| id           | TEXT     | PRIMARY KEY, NOT NULL      |
| email        | TEXT     |                            |
| phone        | TEXT     |                            |
| name         | TEXT     |                            |
| gender       | TEXT     |                            |
| birthdate    | TEXT     |                            |
| imageUrl     | TEXT     |                            |
| authProvider | TEXT     |                            |
| password     | TEXT     |                            |
| role         | TEXT     | DEFAULT 'kasir'            |
| createdAt    | DATETIME | DEFAULT CURRENT_TIMESTAMP  |
| updatedAt    | DATETIME | DEFAULT CURRENT_TIMESTAMP  |

### Product

| Column         | Type     | Constraints                       |
| -------------- | -------- | --------------------------------- |
| id             | INTEGER  | PRIMARY KEY, NOT NULL             |
| createdById    | TEXT     | FK → User(id)                     |
| name           | TEXT     |                                   |
| imageUrl       | TEXT     |                                   |
| stock          | INTEGER  |                                   |
| sold           | INTEGER  |                                   |
| price          | INTEGER  |                                   |
| wholesalePrice | INTEGER  |                                   |
| costPrice      | INTEGER  | NOT NULL, DEFAULT 0 (HPP satuan dasar, otomatis dari pembelian terakhir) |
| isCustomPrice  | INTEGER  | NOT NULL, DEFAULT 0 (ditambahkan oleh migrasi v3; dikirim di payload sync) |
| unit           | TEXT     | DEFAULT 'pcs'                     |
| barcode        | TEXT     |                                   |
| description    | TEXT     |                                   |
| createdAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP         |
| updatedAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP         |

### ProductUnit

| Column         | Type     | Constraints                         |
| -------------- | -------- | ----------------------------------- |
| id             | INTEGER  | PRIMARY KEY, NOT NULL               |
| productId      | INTEGER  | FK → Product(id), NOT NULL          |
| unitName       | TEXT     | NOT NULL                            |
| conversionValue| INTEGER  | NOT NULL, DEFAULT 1                 |
| price          | INTEGER  | NOT NULL                            |
| wholesalePrice | INTEGER  |                                     |
| isBase         | INTEGER  | NOT NULL, DEFAULT 0                 |
| createdAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP           |
| updatedAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP           |

### ProductTieredPrice

| Column        | Type     | Constraints                         |
| ------------- | -------- | ----------------------------------- |
| id            | INTEGER  | PRIMARY KEY, NOT NULL               |
| productUnitId | INTEGER  | FK → ProductUnit(id), NOT NULL      |
| minQty        | INTEGER  | NOT NULL, DEFAULT 1                 |
| maxQty        | INTEGER  |                                     |
| price         | INTEGER  | NOT NULL                            |
| createdAt     | DATETIME | DEFAULT CURRENT_TIMESTAMP           |
| updatedAt     | DATETIME | DEFAULT CURRENT_TIMESTAMP           |

### Transaction

| Column              | Type     | Constraints               |
| ------------------- | -------- | ------------------------- |
| id                  | INTEGER  | PRIMARY KEY, NOT NULL     |
| paymentMethod       | TEXT     |                           |
| paymentType         | TEXT     | DEFAULT 'cash' (legacy, added by migration) |
| customerName        | TEXT     |                           |
| customerId          | TEXT     | (legacy, added by migration) |
| description         | TEXT     |                           |
| createdById         | TEXT     | FK → User(id)             |
| receivedAmount      | INTEGER  |                           |
| returnAmount        | INTEGER  |                           |
| totalAmount         | INTEGER  |                           |
| totalOrderedProduct | INTEGER  |                           |
| paymentStatus       | TEXT     | DEFAULT 'paid' (`pending`/`paid`/`expired`; webhook can set `failed`) |
| paymentQR           | TEXT     | QR image base64 or URL (KlikQRIS) |
| paymentExternalId   | TEXT     | `orderId` = transaction id string (webhook matching key) |
| dueDate             | TEXT     | (legacy, added by migration) |
| createdAt           | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt           | DATETIME | DEFAULT CURRENT_TIMESTAMP |

> Note: `createTransactionTable` does not declare `paymentType`, `customerId`, or `dueDate`; `_applyMigrations()`
> adds them on every startup for backward compatibility. They are legacy columns and should not be used by new
> features. Direct QRIS transactions use a synthetic `OrderedProduct` named `Transaksi Direct` with
> `productId = 0`, so they do not decrement product stock.

### OrderedProduct

| Column         | Type     | Constraints               |
| -------------- | -------- | ------------------------- |
| id             | INTEGER  | PRIMARY KEY, NOT NULL     |
| transactionId  | INTEGER  | FK → Transaction(id)      |
| productId      | INTEGER  | FK → Product(id)          |
| quantity       | REAL     | NOT NULL, DEFAULT 1       |
| stock          | INTEGER  |                           |
| name           | TEXT     |                           |
| imageUrl       | TEXT     |                           |
| price          | INTEGER  |                           |
| priceType      | TEXT     | DEFAULT 'retail'          |
| unit           | TEXT     | DEFAULT 'pcs'             |
| conversionValue| INTEGER  | NOT NULL, DEFAULT 1       |
| isTieredPrice  | INTEGER  | NOT NULL, DEFAULT 0 (1 = bundle tier price applied) |
| createdAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP |

> `OrderedProductEntity.units` is a runtime snapshot of the product's units used by the cart unit
> dropdown. It is intentionally **not** persisted to SQLite or Supabase.

### Customer

| Column    | Type     | Constraints               |
| --------- | -------- | ------------------------- |
| id        | TEXT     | PRIMARY KEY, NOT NULL     |
| name      | TEXT     | NOT NULL                  |
| phone     | TEXT     |                           |
| createdAt | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt | DATETIME | DEFAULT CURRENT_TIMESTAMP |

### Supplier

| Column    | Type     | Constraints               |
| --------- | -------- | ------------------------- |
| id        | TEXT     | PRIMARY KEY, NOT NULL     |
| name      | TEXT     | NOT NULL                  |
| phone     | TEXT     |                           |
| address   | TEXT     |                           |
| note      | TEXT     |                           |
| createdAt | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt | DATETIME | DEFAULT CURRENT_TIMESTAMP |

Index: `idx_supplier_name_unique` — `UNIQUE (name COLLATE NOCASE)`, so supplier names are unique
case-insensitively.

### Purchase

| Column       | Type     | Constraints                              |
| ------------ | -------- | ---------------------------------------- |
| id           | INTEGER  | PRIMARY KEY, NOT NULL                    |
| supplierId   | TEXT     | FK → Supplier(id)                        |
| supplierName | TEXT     | Snapshot of supplier name at purchase time |
| purchaseDate | TEXT     | NOT NULL (`YYYY-MM-DD`)                  |
| note         | TEXT     |                                          |
| totalAmount  | INTEGER  | NOT NULL, DEFAULT 0                      |
| totalItems   | INTEGER  | NOT NULL, DEFAULT 0                      |
| addStock     | INTEGER  | NOT NULL, DEFAULT 1 (0 = jangan tambah stok) |
| createdById  | TEXT     | FK → User(id)                            |
| createdAt    | DATETIME | DEFAULT CURRENT_TIMESTAMP                |
| updatedAt    | DATETIME | DEFAULT CURRENT_TIMESTAMP                |

Indexes: `idx_purchase_date` (`purchaseDate DESC, id DESC`), `idx_purchase_supplier` (`supplierId`).

### PurchaseItem

| Column         | Type     | Constraints                     |
| -------------- | -------- | ------------------------------- |
| id             | INTEGER  | PRIMARY KEY, NOT NULL           |
| purchaseId     | INTEGER  | FK → Purchase(id), NOT NULL     |
| productId      | INTEGER  | FK → Product(id), NOT NULL      |
| productName    | TEXT     | Snapshot of product name        |
| unitName       | TEXT     | NOT NULL                        |
| conversionValue| INTEGER  | NOT NULL, DEFAULT 1             |
| quantity       | REAL     | NOT NULL, DEFAULT 1             |
| unitPrice      | INTEGER  | NOT NULL, DEFAULT 0             |
| totalPrice     | INTEGER  | NOT NULL, DEFAULT 0             |
| baseUnitPrice  | INTEGER  | NOT NULL, DEFAULT 0 (HPP satuan dasar) |
| createdAt      | DATETIME | DEFAULT CURRENT_TIMESTAMP       |

Index: `idx_purchase_item_product` (`productId, purchaseId`).

> Purchase behavior: stok bertambah sebesar `round(quantity / conversionValue)` — aturan yang sama
> dengan pengurangan stok saat penjualan. `Product.costPrice` diisi `baseUnitPrice` dari
> `PurchaseItem` terbaru (`purchaseDate DESC, Purchase.id DESC, PurchaseItem.id DESC`), dan dihitung
> ulang saat nota pembelian dihapus. Hapus nota hanya mengurangi stok jika `Purchase.addStock = 1`.

### QueuedAction

| Column     | Type     | Constraints               |
| ---------- | -------- | ------------------------- |
| id         | INTEGER  | NOT NULL                  |
| repository | TEXT     |                           |
| method     | TEXT     |                           |
| param      | TEXT     |                           |
| isCritical | INTEGER  | (0 = false, 1 = true)     |
| createdAt  | DATETIME | DEFAULT CURRENT_TIMESTAMP |

### Indexes

| Index                          | Definition / purpose                                      |
| ------------------------------ | --------------------------------------------------------- |
| `idx_product_name_unique`      | `UNIQUE (name)` — product names are unique               |
| `idx_product_barcode`          | `Product(barcode)` — barcode lookup/camera/HID scans      |
| `idx_supplier_name_unique`     | `UNIQUE (name COLLATE NOCASE)` — supplier names unique    |
| `idx_purchase_date`            | `Purchase(purchaseDate DESC, id DESC)`                    |
| `idx_purchase_supplier`        | `Purchase(supplierId)`                                    |
| `idx_purchase_item_product`    | `PurchaseItem(productId, purchaseId)`                     |

## Remote Mirror (Supabase Postgres)

Local tables mirror remote tables defined in `docs/supabase/schema.sql` (snake_case, camelCase-preserving
quoted columns: `createdById`, `imageUrl`, `wholesalePrice`, ...). Remote adds `users`, `product_units`,
`product_tiered_prices`, `ordered_products`, `customers`, `queued_actions` with matching FKs.
Webhook matching: `transactions.paymentExternalId = orderId` (see KlikQRIS flow in `README.md`).

`Product.costPrice`, `Supplier`, `Purchase`, and `PurchaseItem` are **local-only** for now. Product
sync strips `costPrice` before create/update. `isCustomPrice` (product) and `isTieredPrice`
(ordered product) are included in sync payloads; make sure those columns exist in your remote schema
before enabling sync for schemas created from an older `docs/supabase/schema.sql`.
