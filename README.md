# Mono POS

[![License: MIT](https://img.shields.io/badge/license-MIT-orange)](./LICENSE)
[![Made with Flutter](https://img.shields.io/badge/made%20with-Flutter-blue)](https://flutter.dev/)

> **Current release:** `1.3.14` (`versionCode 31`).

> 🚀 This project is the base model of [Zirel POS](https://zirelpos.com/). If you want a ready-to-use, feature-complete POS app, you might want to check it out, it's free, no card required.

A Point of Sale (POS) application built with Flutter, demonstrating **Clean Architecture** principles and **offline-first** design patterns. This project serves as a learning resource and reference implementation for building Flutter apps with proper architecture and automatic data synchronization between local storage (SQLite) and a cloud backend (Supabase Postgres).

The app prioritizes local-first operations, storing all data in SQLite and automatically syncing with Supabase when online. When offline, all user actions (create, update, delete) are recorded as `QueuedActions` in the local database and automatically executed in sequence when internet connectivity is restored.

<br/>
<p align="left">
  <img src="docs/screenshoot_2.jpeg" alt="Image 2" height="350" style="margin-right: 10px;">
  <img src="docs/screenshoot_1.jpeg" alt="Image 1" height="350" style="margin-right: 10px;">
  <img src="docs/screenshoot_3.jpeg" alt="Image 2" height="350" style="margin-right: 10px;">
  <img src="docs/screenshoot_4.jpeg" alt="Image 2" height="350" style="margin-right: 10px;">
  <img src="docs/screenshoot_5.jpeg" alt="Image 2" height="350">
</p>

## Demo APK

[Download Demo APK](https://github.com/monodev-id/MonoPOS/releases)

## Features

### Core Functionality

- **Product Management**: Full CRUD operations for products with image upload support, multi-unit definitions, tiered (retail/grosir) pricing, manual HPP (`costPrice`), and barcode support
- **Bundle-Based Tiered Pricing**: Per-unit quantity breaks (`ProductTieredPrice`) with live price preview in the add-to-cart dialog
- **Product Data Backup**: JSON export/import of products + units + tiered prices with per-product breakdown, success overlay, and confirm-import dialog (admin only, `Account → Product Data`)
- **Barcode Label Printing (Admin)**: Generate unique EAN-13 codes for products without barcodes, save them in bulk, and batch-print labels with per-product copy counts (`Account → Barcode Labels`); printing requires a connected printer
- **Sales Transactions**: POS interface with cart management, per-item retail/grosir toggle, custom price input, and transaction history
- **Quick Checkout Amounts**: `Uang Pas` / 50rb / 100rb shortcut buttons plus custom amount field in the checkout sheet
- **Barcode Input**: Camera scanner (`mobile_scanner`) plus HID hardware-scanner listener; both look up the product in SQLite first and add the scanned product straight to the cart (+1 base unit) without opening a dialog
- **Low-Stock Warning**: `AppLowStockDialog` blocks/adds with confirmation when stock is insufficient
- **Thermal Receipt Printing**: Print transaction receipts via USB, Bluetooth, BLE, or network printers with configurable paper sizes (58mm, 72mm, 80mm); live connection banner + badge synced from `PrinterManager`, saved-printer auto-reconnect on startup/resume, and manual print from transaction detail (no auto-print)
- **Payments (DANA Bisnis QRIS)**: Upload your static DANA Bisnis QRIS once in `Account → Payment Settings`; at checkout Mono POS converts it to a dynamic QRIS with the exact amount (EMVCo TLV + CRC16, ported from BITS-QRIS-Converter) and renders the payload directly. A native Android notification listener always watches DANA notifications and marks the matching `pending` transaction as `paid` automatically, with expiry countdown, unique code matching, manual "Tandai Lunas" fallback, and cash-register sound + TTS
- **Direct QRIS**: Amount-first QRIS payment without adding products to the cart (`/payment/direct`), reachable from the Home and Transactions app bars; includes quick amounts, optional description/customer, merchant badge, and a configuration guard. The recorded transaction uses the scanned amount plus an auto-generated unique code
- **Supplier & Purchase Management (Admin, local-only)**: Supplier/wholesaler directory plus multi-item purchase notes; shows/auto-fills the last purchase price per supplier, can add stock per note, and updates product HPP (`costPrice`) from the latest purchase. Deleting a note recalculates stock and HPP. Supplier/purchase data is not synced to Supabase yet
- **Payment Sound & Voice**: Cash-register sound (`cashmasuk.mp3`) + Indonesian TTS announcement (`terbilang` amount) on successful QRIS payment, toggleable in payment settings
- **Customer Management**: Customer directory with forms integrated into the sales flow
- **Employee Management**: Role-based access control (admin / kasir) with employee accounts; admin-only routes and menus are hidden/redirected for kasir
- **Revenue Reporting**: Daily revenue reports filtered by paid status with cash/QRIS/other breakdowns, product counts, per-day transaction detail, and all-user totals for admins
- **App Update (Admin)**: Check GitHub releases, view changelog (Markdown), download progress, and install APK via `Account → App Update`
- **Supabase Runtime Config**: `Account → Supabase Sync` dialog stores URL + anon key in `SharedPreferences` — no rebuild needed; restart applies the new connection
- **User Authentication**: Supabase Auth with Google Sign-In and email/password
- **Account & Store Management**: User profile, store name/address/receipt footer settings, and printer settings
- **Localization**: Indonesian and English via `flutter_localizations` (ARB files)
- **Adaptive UI**: Tablet/desktop breakpoints (`AppSizes.isTablet/isDesktop`), centered max-width dialogs, navigation rail on wide screens

### Technical Implementation

- **Offline-First Architecture**: Works seamlessly without internet connection
- **Automatic Data Sync**: SQLite ↔ Supabase (Postgres) bidirectional synchronization
- **Queued Actions**: Automatic retry mechanism for offline operations (create, update, delete)
- **Clean Architecture**: Separation between presentation, domain, and data layers
- **State Management**: Riverpod for safer, more testable state management
- **Dependency Injection**: Centralized DI setup for better code organization
- **Cloud Backend**: Supabase (Postgres + Auth + Storage) replacing Firebase/Firestore
- **Object Storage**: Product images and receipts stored via S3-compatible storage
- **Local-Only Domain Modules**: Suppliers and purchases use the same clean-architecture flow (datasource → repository → usecase → notifier) but write only to SQLite for now
- **Barcode Labels**: EAN-13 generation via `BarcodeGenerator` and label rendering with `barcode_widget`
- **App Update Service**: GitHub Releases API + APK download/install (`open_filex`, `package_info_plus`)
- **Audio Feedback**: `flutter_tts` (id-ID/en-US) + `audioplayers` for payment confirmation
- **Unit Testing**: Tests for datasources, repositories, and use cases
- **Material Design 3**: Material Design 3 with Dark & Light theme switching support
- **Customizable Theming**: Adjustable colors and typography
- **Multi-Platform**: Supports Android, iOS, Windows, macOS, and Linux
- **Error Handling**: User-friendly error messages and states
- **Reusable Widgets**: Custom UI components for consistent design

## Architecture

<img src="docs/architecture.png" alt="Architecture">

## Project Structure

```
mono_pos/
├── lib/
│   ├── app/                          # Application setup and configuration
│   │   ├── di/                       # Dependency injection
│   │   ├── error/                    # Error handling
│   │   └── routes/                   # App routing and navigation
│   │
│   ├── core/                         # Core utilities and shared resources
│   │   ├── assets/                   # Asset management
│   │   ├── common/                   # Common utilities (Result wrapper)
│   │   ├── constants/                # App constants
│   │   ├── extensions/               # Dart extensions
│   │   ├── locale/                   # Localization helpers
│   │   ├── services/                 # Core services
│   │   │   ├── connectivity/         # Network connectivity checking
│   │   │   ├── database/             # Local database service (sqflite)
│   │   │   ├── info/                 # Device info service
│   │   │   ├── logger/               # Error logging service
│   │   │   ├── payment/              # DANA QRIS (static→dynamic) + notification listener
│   │   │   ├── printer/              # Thermal printer service + saved-printer reconnect
│   │   │   ├── storage/              # S3-compatible object storage
│   │   │   ├── supabase/             # Supabase client config/service + runtime credentials
│   │   │   ├── sync/                 # Sync / queued-action processing
│   │   │   ├── tts/                  # TTS voice + cash-register sound
│   │   │   └── update/               # GitHub release check + APK installer
│   │   ├── themes/                   # App theming (colors, sizes, themes)
│   │   ├── usecase/                  # Base usecase interface
│   │   └── utilities/                # Helper utilities (formatters, loggers, etc.)
│   │
│   ├── data/                         # Data layer
│   │   ├── datasources/              # Data sources
│   │   │   ├── interfaces/           # Datasource interfaces (auth, product, transaction, purchase, supplier, app-update, ...)
│   │   │   ├── local/                # Local datasources (sqflite; products, transactions, customers, suppliers, purchases, queue)
│   │   │   └── remote/               # Remote datasources (Supabase, Auth, Storage, AppUpdate/GitHub)
│   │   ├── models/                   # Data models with JSON serialization (incl. purchase, purchase_item, supplier, app_update)
│   │   └── repositories/             # Repository implementations (incl. purchase, supplier, app_update)
│   │
│   ├── domain/                       # Domain layer (Business logic)
│   │   ├── entities/                 # Business entities (incl. purchase, purchase_item, supplier, app_update)
│   │   ├── repositories/             # Repository interfaces (incl. purchase, supplier, app_update)
│   │   └── usecases/                 # Use cases (incl. purchase, supplier, app_update)
│   │
│   ├── presentation/                 # Presentation layer (UI)
│   │   ├── providers/                # State management (Riverpod)
│   │   │   ├── account/              # Account, store, printer, payment, product-data, barcode-label & app-update state
│   │   │   ├── auth/                 # Authentication state
│   │   │   ├── customer/             # Customer management state
│   │   │   ├── employees/            # Employee / RBAC state
│   │   │   ├── home/                 # Home screen state (cart, barcode scan)
│   │   │   ├── language/             # Localization state
│   │   │   ├── main/                 # Main navigation state
│   │   │   ├── payment/              # QRIS payment state + DANA listener
│   │   │   ├── products/             # Products management state (+ purchase info)
│   │   │   ├── purchases/            # Purchase list, form, and detail state
│   │   │   ├── revenue/              # Revenue reporting + day-detail state
│   │   │   ├── splash/               # Splash state
│   │   │   ├── suppliers/            # Supplier list/form state
│   │   │   ├── theme/                # Theme state
│   │   │   └── transactions/         # Transactions state
│   │   ├── screens/                  # UI screens
│   │   │   ├── account/              # Account, store/printer/payment settings, product-data, barcode-labels, app-update, About
│   │   │   ├── auth/                 # Authentication screens
│   │   │   ├── customer/             # Customer screens
│   │   │   ├── employees/            # Employee management screens
│   │   │   ├── error/                # Error screens
│   │   │   ├── home/                 # Home/POS screen (+ barcode scanner, HID listener, cart panel)
│   │   │   ├── main/                 # Main navigation screen
│   │   │   ├── payment/              # QRIS payment screen + direct QRIS screen
│   │   │   ├── products/             # Product management screens (+ purchase info)
│   │   │   ├── purchases/            # Purchase list/form/detail screens
│   │   │   ├── revenue/              # Revenue report + per-day detail screens
│   │   │   ├── splash/               # Splash screen
│   │   │   ├── suppliers/            # Supplier list/form screens
│   │   │   └── transactions/         # Transaction history screens
│   │   └── widgets/                  # Reusable UI components (`app_*`: button, dialog, text field,
│   │                                  # success overlay, low-stock dialog, price-type toggle, ...)
│   │
│   ├── l10n/                         # Localization ARB files (app_en, app_id)
│   ├── generated/                    # Generated localization code (flutter gen-l10n)
│   └── main.dart                     # App entry point
│
├── test/                             # Unit and widget tests
│   ├── core/services/                # Service tests
│   ├── data/                         # Data layer tests
│   │   ├── datasources/              # Datasource tests (local + remote)
│   │   ├── models/                   # Model tests
│   │   └── repositories/             # Repository tests
│   ├── domain/                       # Entity + usecase tests
│   ├── presentation/                 # Provider, screen, and widget tests
│   │   ├── providers/                # Notifier tests (incl. home cart, purchase form)
│   │   └── screens/                  # Screen/widget tests
│   └── ...
│
├── assets/                           # Static assets
├── android/                          # Android platform files
├── ios/                              # iOS platform files
├── linux/                            # Linux platform files
├── macos/                            # macOS platform files
├── web/                              # Web platform files
├── windows/                          # Windows platform files
├── cloudflare/                       # Payment webhook workers (klikqris-notify, doku-notify archive)
├── supabase/                         # Supabase config & edge functions
│
├── analysis_options.yaml             # Dart analyzer configuration
├── pubspec.yaml                      # Package dependencies
└── README.md                         # Project documentation
```

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install)
- [Dart](https://dart.dev/get-dart)
- A [Supabase](https://supabase.com/) project for the cloud backend

### Installation

1. **Clone the repository:**

   ```sh
   git clone https://github.com/monodev-id/MonoPOS.git
   cd MonoPOS
   ```

2. **Install dependencies:**

   ```sh
   flutter pub get
   ```

3. **Set up Supabase:**
   - Create a new project on [Supabase](https://supabase.com/).
   - The local SQLite schema (see [`DATABASE.md`](DATABASE.md)) mirrors the remote Postgres tables. Create matching tables in your Supabase project (see `docs/supabase/schema.sql`), or let the sync layer populate them after first run.
   - Enable the **Google** auth provider and configure the OAuth redirect/callback.
   - (Optional) Configure Row Level Security so that rows are scoped to the authenticated user.

   > **Recommended (runtime config):** after installing the app, open **Account → Supabase Sync**,
   > enter the project URL + anon/publishable key, tap Save, then restart the app. No rebuild needed —
   > one binary can serve many stores.

4. **(Optional) Build-time `config.json`**

   For pre-baked builds you can still pass backend configuration via `--dart-define-from-file`.
   Create a `config.json` in the project root (see `config.example.json`):

   ```json
   {
     "SUPABASE_URL": "https://your-project.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "your-publishable-anon-key",
     "GOOGLE_SERVER_CLIENT_ID": "xxxxx.apps.googleusercontent.com"
   }
   ```

   | Key | Description |
   | --- | --- |
   | `SUPABASE_URL` | URL of your Supabase project |
   | `SUPABASE_PUBLISHABLE_KEY` | Supabase anon/publishable key (legacy alias: `SUPABASE_ANON_KEY`) |
   | `SUPABASE_SECRET_KEY` | Optional service-role key for privileged server tasks |
   | `GOOGLE_SERVER_CLIENT_ID` | Web client ID from the Google Sign-In provider in Supabase |

   If `Supabase` is not configured, the app still runs fully offline — sync and remote features are disabled automatically.
   Runtime credentials entered in the app take precedence over build-time values.

5. **Run the application:**

   ```sh
   flutter run
   # or with pre-baked config:
   flutter run --dart-define-from-file config.json
   ```

### Test

To test the application, run the following command:

```sh
flutter test --coverage
```

To view the test coverage you can use `genhtml` or [test_cov_console](https://pub.dev/packages/test_cov_console)

## Payments (DANA Bisnis QRIS)

Mono POS uses a **static DANA Bisnis merchant QRIS** that is converted into a **dynamic QRIS** at checkout. There is no payment API, webhook, or polling: the merchant QRIS string is the source of truth and an Android `NotificationListenerService` reads DANA payment notifications to confirm payments.

Setup:

1. Open `Account → Payment Settings` (admin).
2. Upload a screenshot of the static DANA Bisnis QRIS, scan it with the camera, or paste the QRIS payload. The image is decoded on-device and deleted; only the payload string is stored in `SharedPreferences`.
3. Validate the merchant info (name, city, NMID) shown by the app and save.

Two flows share the same screen (`/payment/qris`):

- **Cart checkout** — builds the transaction from the cart, then converts the static QRIS with `amount = total + unique code` before saving, so no half-created transaction or stock deduction is left behind if the QRIS is invalid.
- **Direct QRIS** — open `/payment/direct`, enter an amount (plus optional description/customer), and create a `qris` transaction without touching product stock.

Common flow:

1. At checkout the app allocates a unique code (1–99, fallback 100–999) for the amount, converts the static QRIS to a dynamic payload, saves the transaction as `pending`, and shows the QR (rendered from the payload, not an image).
2. The customer scans and pays with any QRIS-compatible app.
3. DANA posts a notification; the native listener queues it durably and Flutter parses the amount. When exactly one `pending` transaction matches `paymentExpectedAmount`, it is marked `paid`, the app plays the cash-register sound and announces the amount via Indonesian TTS.
4. `Cek Pembayaran` drains the notification queue on demand; `Tandai Lunas` is available as a manual fallback.
5. When the countdown ends the transaction becomes `expired`; cancelling deletes the transaction and restores the reserved stock. Payments that arrive late (up to 60 minutes) still match expired transactions.

Payment preferences (`dana_qris_static`, `dana_unique_code_enabled`, `dana_expiry_minutes`, `dana_tts_enabled`, `dana_listener_enabled`) are stored locally. Notification access must be granted from the listener card (`Buka Akses Notifikasi`). DANA packages listened to: `id.dana` and `id.dana.kasir`.

> **Local-only data:** supplier, purchase, product HPP (`costPrice`), DANA payment metadata, and the `PaymentNotification` table are stored in SQLite only. Sync strips them before writing to Supabase.

> **Legacy:** Doku SNAP and KlikQRIS are retired — see [`DOKU_PAYMENT_GATEWAY.md`](DOKU_PAYMENT_GATEWAY.md). Their services/providers may still exist for reference; do not build new features on them.

## AI Agent Guidelines

This project includes documentation files designed for AI coding agents (e.g., Claude Code) to keep code consistent when modifying the project:

- [`CLAUDE.md`](CLAUDE.md) — Project conventions (architecture, naming, code style)
- [`UI.md`](UI.md) — UI reference (layouts, components, design specs)
- [`DATABASE.md`](DATABASE.md) — Database schema reference (tables, columns)
- [`WORKFLOW.md`](WORKFLOW.md) — Git workflow (commits, branches, PRs)
- [`WORKFLOW_SYSTEM.md`](WORKFLOW_SYSTEM.md) — Workflow/sync system reference
- [`SYNC.md`](SYNC.md) — Offline-first sync architecture
- [`DOKU_PAYMENT_GATEWAY.md`](DOKU_PAYMENT_GATEWAY.md) — Deprecated (Doku SNAP and KlikQRIS retired; QRIS now uses DANA Bisnis)

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any bugs, feature requests, or improvements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
