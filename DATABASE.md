# DATABASE.md - Database Schema Reference

> Last synced with code: v1.2.6 (`DatabaseConfig.version = 3`).

Database: SQLite (`app_database.db`) via `sqflite`

## Migration Strategy

Database version is maintained in `DatabaseConfig` (currently **version 3**). On every startup, `_applyMigrations()` in `DatabaseService` runs idempotent `ALTER TABLE ADD COLUMN IF NOT EXISTS` and `CREATE TABLE IF NOT EXISTS` statements. This means new columns/tables are added automatically without bumping the version number.

Source of truth: `lib/core/services/database/database_config.dart`. Seed data: 150 demo products on first install (`DatabaseService`).

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
| customerName        | TEXT     |                           |
| description         | TEXT     |                           |
| createdById         | TEXT     | FK → User(id)             |
| receivedAmount      | INTEGER  |                           |
| returnAmount        | INTEGER  |                           |
| totalAmount         | INTEGER  |                           |
| totalOrderedProduct | INTEGER  |                           |
| paymentStatus       | TEXT     | DEFAULT 'paid' (`pending`/`paid`/`failed` for QRIS) |
| paymentQR           | TEXT     | QR image base64 or URL (KlikQRIS) |
| paymentExternalId   | TEXT     | `orderId` = transaction id string (webhook matching key) |
| createdAt           | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt           | DATETIME | DEFAULT CURRENT_TIMESTAMP |

> Note: `DATABASE.md` revisions previously listed `paymentType`, `customerId`, `dueDate` — these columns
> are **not present** in `DatabaseConfig.createTransactionTable` (v1.2.6). Do not rely on them until a
> migration adds them.

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

### Customer

| Column    | Type     | Constraints               |
| --------- | -------- | ------------------------- |
| id        | TEXT     | PRIMARY KEY, NOT NULL     |
| name      | TEXT     | NOT NULL                  |
| phone     | TEXT     |                           |
| createdAt | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| updatedAt | DATETIME | DEFAULT CURRENT_TIMESTAMP |

### QueuedAction

| Column     | Type     | Constraints               |
| ---------- | -------- | ------------------------- |
| id         | INTEGER  | NOT NULL                  |
| repository | TEXT     |                           |
| method     | TEXT     |                           |
| param      | TEXT     |                           |
| isCritical | INTEGER  | (0 = false, 1 = true)     |
| createdAt  | DATETIME | DEFAULT CURRENT_TIMESTAMP |

## Remote Mirror (Supabase Postgres)

Local tables mirror remote tables defined in `docs/supabase/schema.sql` (snake_case, camelCase-preserving
quoted columns: `createdById`, `imageUrl`, `wholesalePrice`, ...). Remote adds `users`, `product_units`,
`product_tiered_prices`, `ordered_products`, `customers`, `queued_actions` with matching FKs.
Webhook matching: `transactions.paymentExternalId = orderId` (see KlikQRIS flow in `README.md`).
