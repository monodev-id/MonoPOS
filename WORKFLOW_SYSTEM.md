# WORKFLOW Sistem POS - MonoPOS

> Last synced with code: v1.2.6 (Sep 2026). Payment = **KlikQRIS** (Doku retired),
> Supabase via runtime Settings, admin-only routes enforced in `AppRoutes`.

## 1. Alur Autentikasi (Login / Logout)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Splash Screen │────▶│ Cek Auth     │────▶│ Home Screen  │
│   (/)        │     │ (ada sesi?)  │     │  (/home)     │
└──────────────┘     └──────┬───────┘     └──────────────┘
                            │ Tidak
                     ┌──────▼───────┐
                     │ Login Screen │
                     │  (/login)    │
                     └──────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              ▼                           ▼
   ┌──────────────────┐      ┌──────────────────┐
   │ Login Google     │      │ Login Email/Pass  │
   │ (Supabase Auth)  │      │ (Local Auth)      │
   └────────┬─────────┘      └────────┬──────────┘
            │                         │
            ▼                         ▼
   ┌──────────────────────────────────────────┐
   │ AuthNotifier → AuthRepository            │
   │ → Simpan sesi → Redirect ke /home        │
   └──────────────────────────────────────────┘
```

**Role pengguna:**
- **Admin** — Akses penuh (kelola produk, transaksi, pengaturan, laporan)
- **Kasir** — Akses kasir (POS, transaksi)

---

## 2. Alur Penjualan (POS / Kasir)

```
┌─────────────────────────────────────────────────────────┐
│                   HOME SCREEN (/home)                    │
│                                                          │
│  ┌─────────────────────┐   ┌──────────────────────────┐ │
│  │   Daftar Produk     │   │     Cart Panel           │ │
│  │   (Grid)            │   │  ┌────────────────────┐  │ │
│  │                     │   │  │ Header             │  │ │
│  │ • Tap produk →      │──▶│  │ (Nama pelanggan,   │  │ │
│  │   tambah ke keranjang│   │  │  tipe harga)       │  │ │
│  │                     │   │  ├────────────────────┤  │ │
│  │ • Scan barcode →    │──▶│  │ Body               │  │ │
│  │   cari & tambah     │   │  │ (Daftar item,      │  │ │
│  │                     │   │  │  qty, harga)        │  │ │
│  │ • Search produk     │   │  ├────────────────────┤  │ │
│  │                     │   │  │ Footer             │  │ │
│  └─────────────────────┘   │  │ (Total, metode     │  │ │
│                             │  │  bayar, checkout)   │  │ │
│                             │  └────────────────────┘  │ │
│                             └──────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 2a. Tambah Produk ke Keranjang

```
User tap produk / scan barcode
  ↓
HomeNotifier.addOrderedProduct()
  ↓
Cek apakah produk sudah ada di keranjang
  ├── Ya  → Tambah quantity (+1)
  └── Tidak → Tambah item baru ke orderedProducts
  ↓
Update state (total, jumlah item)
```

### 2b. Pilih Tipe Harga

```
User toggle tipe harga di Cart Panel Header
  ├── Retail  → Gunakan harga retail (price)
  └── Grosir  → Gunakan harga grosir (wholesalePrice)
  ↓
HomeNotifier.setSelectedPriceType()
  ↓
Update harga semua item di keranjang
```

### 2c. Pilih Satuan Produk (Multi-Unit)

```
Produk bisa punya banyak satuan:
  Contoh: Teh Botol
    ├── pcs  (base unit, harga: Rp 5.000)
    ├── pack (isi 6 pcs, harga: Rp 28.000)
    └── dus  (isi 24 pcs, harga: Rp 100.000)
  ↓
User pilih satuan saat menambah ke keranjang
  ↓
Harga & konversi stok otomatis menyesuaikan
```

### 2d. Tiered Pricing (Bundle) + Live Preview

```
ProductTieredPrice per ProductUnit: minQty–maxQty → price
  ↓
Dialog add-to-cart menampilkan harga live sesuai qty
  ↓
OrderedProduct.isTieredPrice = 1 jika tier terpakai
  ↓
Struk & cart menampilkan badge tier
```

### 2e. Input Barcode (Kamera + HID)

```
Kamera: barcode_scanner_screen (mobile_scanner) → cari produk → tambah
HID: barcode_hid_listener (hardware scanner, fokus global) → tambah otomatis
Produk tidak ditemukan → snackbar error
```

### 2f. Validasi Stok Rendah

```
Qty diminta > stok → AppLowStockDialog konfirmasi
  ├── Lanjut → tambah dengan qty tersedia
  └── Batal → kembali ke dialog
```

---

## 3. Alur Checkout & Pembayaran

```
User tap tombol Checkout (CartPanelFooter)
  ↓
Sheet checkout: quick amounts (Uang Pas / 50rb / 100rb) + input custom
  ↓
Pilih metode pembayaran
  ├── Cash
  │     ↓
  │   Input jumlah diterima (receivedAmount)
  │     ↓
  │   Hitung kembalian (returnAmount = receivedAmount - totalAmount)
  │     ↓
  │   Simpan transaksi
  │     ↓
  │   Cetak struk manual dari detail (tidak auto-print)
  │     ↓
  │   Selesai ✅
  │
  └── QRIS (KlikQRIS)
        ↓
      ┌──────────────────────────────────────┐
      │ KlikQrisPaymentScreen (/payment/qris)│
      │                                       │
      │ 1. Simpan transaksi (status: pending) │
      │ 2. generateQris(orderId=trxId) → QR   │
      │ 3. Tampilkan QR + countdown (expiredMinutes) │
      │ 4. Auto-poll 3x @15s + tombol manual  │
      │    ├── Paid ✅ → suara kasir + TTS    │
      │    │     → update paid → detail       │
      │    ├── Pending → tombol Cek Pembayaran│
      │    └── Expired/failed ❌ → error      │
      │ 5. Back/close → dialog konfirmasi     │
      │    (hindari batal tak sengaja)        │
      │ 6. Webhook klikqris-notify (opsional) │
      │    mempercepat paid via Supabase      │
      └──────────────────────────────────────┘
```

### 3a. Simpan Transaksi (Detail)

```
HomeNotifier → CreateTransactionUsecase
  ↓
TransactionRepository.create()
  ↓
┌─ TransactionLocalDatasource.create() ✅ (SQLite)
│    ├── Insert Transaction
│    ├── Insert OrderedProducts (line items)
│    └── Update Product stock (kurangi stok)
│
├─ SyncService.isOnline?
│    ├── Ya  → TransactionRemoteDatasource.create() (Supabase)
│    │          ├── Sukses ✅ → Selesai
│    │          └── Gagal   → Queue action
│    └── Tidak → QueuedActionRepository.create() (simpan antrian)
│
└── Reset keranjang
```

---

## 4. Alur Manajemen Produk

```
┌────────────────────────────────────────────────────────┐
│              PRODUCTS SCREEN (/products)                 │
│                                                         │
│  • Daftar produk (grid, infinite scroll, search)        │
│  • Tap produk → Detail Produk                           │
│  • Tombol (+) → Tambah Produk Baru                      │
└───────────┬────────────────────────┬────────────────────┘
            ▼                        ▼
┌───────────────────┐    ┌───────────────────────────┐
│ Product Detail    │    │ Product Form (Create/Edit) │
│ (/products/:id)   │    │ (/products/product-create) │
│                   │    │ (/products/product-edit/:id)│
│ • Lihat detail    │    │                            │
│ • Edit produk     │───▶│ • Nama produk              │
│ • Hapus produk    │    │ • Harga retail & grosir    │
│                   │    │ • Stok                     │
└───────────────────┘    │ • Barcode                  │
                         │ • Satuan (multi-unit)      │
                         │ • Foto produk (upload S3)  │
                         │ • Deskripsi                │
                         └───────────────────────────┘
```

### 4a. CRUD Produk

```
Create:
  User isi form → ProductFormNotifier.createProduct()
  → CreateProductUsecase → ProductRepository.create()
  → Local (SQLite) + Remote (Supabase) / Queue

Update:
  User edit form → ProductFormNotifier.updateProduct()
  → UpdateProductUsecase → ProductRepository.update()
  → Local + Remote / Queue

Delete:
  User konfirmasi hapus → ProductDetailNotifier.deleteProduct()
  → DeleteProductUsecase → ProductRepository.delete()
  → Local + Remote / Queue
```

---

## 5. Alur Riwayat Transaksi

```
┌────────────────────────────────────────────────┐
│       TRANSACTIONS SCREEN (/transactions)       │
│                                                 │
│  • Daftar transaksi (list, infinite scroll)     │
│  • Search berdasarkan nama pelanggan            │
│  • Tap transaksi → Detail                       │
└──────────────────┬──────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────┐
│  TRANSACTION DETAIL (/transactions/:id)       │
│                                               │
│  • Info transaksi (tanggal, pelanggan)        │
│  • Daftar produk yang dibeli                  │
│  • Total, metode bayar, status pembayaran     │
│  • Cetak ulang struk                          │
│  • Hapus transaksi                            │
└──────────────────────────────────────────────┘
```

---

## 6. Alur Sinkronisasi Data (Online/Offline)

```
┌──────────────────────────────────────────────────┐
│                 MODE SINKRONISASI                  │
│                                                    │
│  Auto (default)  ←→  Offline  ←→  Online           │
│  [WiFi icon]         [WiFi-off]    [WiFi icon]     │
│  (auto detect)       (paksa lokal) (paksa remote)  │
│                                                    │
│  Toggle: Tap ikon WiFi di AppBar                   │
└──────────────┬───────────────────────────────────┘
               ▼

Saat ONLINE:
  Write data → SQLite ✅ → Supabase ✅ → Selesai

Saat OFFLINE:
  Write data → SQLite ✅ → Queue action → Selesai

Saat KEMBALI ONLINE:
  ┌────────────────────────────────────────────────┐
  │ ProcessQueuedActionUsecase                      │
  │                                                 │
  │ Loop semua antrian (urut: critical, createdAt): │
  │   → Parse repository + method + param           │
  │   → Dispatch ke remote datasource:              │
  │     • user/createUser                           │
  │     • product/updateProduct                     │
  │     • transaction/createTransaction             │
  │     • ... dll                                   │
  │   → Sukses → Hapus dari antrian                 │
  │   → Gagal  → Biarkan (coba lagi nanti)          │
  └────────────────────────────────────────────────┘
```

---

## 7. Alur Cetak Struk (Thermal Printer)

```
User checkout / tap cetak ulang (manual dari detail transaksi — tidak ada auto-print)
  ↓
PrinterService.printReceipt()
  ↓
Banner + badge status koneksi (real-time dari PrinterManager) di layar printer settings
  ↓
┌───────────────────────────────────────┐
│  Format Struk:                        │
│                                       │
│  ┌─────────────────────────────────┐  │
│  │  [Nama Toko]                    │  │
│  │  [Alamat Toko]                  │  │
│  │  ─────────────────────────────  │  │
│  │  Tanggal: 19/06/2026 10:30     │  │
│  │  Kasir: John                    │  │
│  │  Pelanggan: Budi               │  │
│  │  ─────────────────────────────  │  │
│  │  Teh Botol x3     Rp 15.000    │  │
│  │  (retail, pcs)                  │  │
│  │  Indomie x1 dus   Rp 100.000   │  │
│  │  (grosir)                       │  │
│  │  ─────────────────────────────  │  │
│  │  Total:           Rp 115.000   │  │
│  │  Bayar (Cash):    Rp 120.000   │  │
│  │  Kembali:         Rp   5.000   │  │
│  │  ─────────────────────────────  │  │
│  │  [QR Code QRIS (jika QRIS)]    │  │
│  │  [Footer text]                  │  │
│  └─────────────────────────────────┘  │
│                                       │
│  Koneksi printer:                     │
│  • USB / Bluetooth / BLE / Network    │
│  • Ukuran kertas: 58mm / 72mm / 80mm  │
└───────────────────────────────────────┘
```

---

## 8. Alur Pengaturan Akun

```
┌──────────────────────────────────────────┐
│          ACCOUNT SCREEN (/account)        │
│                                           │
│  ┌─────────────────────────────────────┐  │
│  │ 📋 Edit Profil     → /account/profile│ │
│  │ 🏪 Pengaturan Toko → /account/store  │ │
│  │ 🖨️ Pengaturan Printer → /account/...  │ │
│  │ 💳 Pengaturan Pembayaran → /account/..│ │
│  │ 📊 Laporan Pendapatan → /account/rev  │ │
│  │ ℹ️  Tentang          → /account/about │ │
│  │ 🚪 Logout                            │ │
│  └─────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### 8a. Pengaturan Toko
- Nama toko, alamat, footer struk
- Disimpan di SharedPreferences

### 8b. Pengaturan Printer
- Scan & connect printer (USB/Bluetooth/BLE/Network)
- Pilih ukuran kertas (58mm/72mm/80mm)
- Test print
### 8c. Pengaturan Pembayaran (KlikQRIS)

- API Key, Merchant ID, toggle Sandbox, toggle suara/TTS (`klikqris_tts_enabled`)
- Tombol **Save** eksplisit + `AppSuccessOverlay`; tidak ada write per ketikan
- Kosong (API key/merchant) = **mock mode** untuk development (QR mock, paid ±30s)

### 8d. Data Produk (Backup)

- `Account → Product Data` (admin only): export JSON (produk + unit + tier) dengan rincian
  per produk + progress; import dengan dialog konfirmasi, overwrite lokal
- File dibagikan via file picker/share; simpan salinan di tempat aman

### 8e. Pembaruan Aplikasi (App Update, Admin)

```
Account → App Update → checkForUpdate() (GitHub Releases API)
  ├── Versi terbaru → tampilkan changelog (Markdown) + tombol Download
  ├── Download APK (progress) → install via AppInstallerService/open_filex
  └── Sudah terbaru → status "up to date"
```

### 8f. Supabase Sync (Runtime Config)

- `Account → Supabase Sync` (admin only): input URL + anon key → simpan ke
  `SharedPreferences` (`SupabaseCredentials`) → **restart app** untuk aktif
- Indikator: `Aktif` / `Belum diatur`; tombol hapus konfigurasi tersedia
- Tanpa kredensial: app full offline, write di-queue, indikator `Pending`

---

## 9. Alur Laporan Pendapatan

```
┌──────────────────────────────────────────┐
│        REVENUE SCREEN (/account/revenue)  │
│                                           │
│  Pilih rentang tanggal                    │
│    ↓                                      │
│  RevenueNotifier.loadRevenue()            │
│    ↓                                      │
│  GetDailyRevenueUsecase                   │
│    ↓                                      │
│  Query transaksi berdasarkan tanggal      │
│    ↓                                      │
│  Tampilkan per hari:                      │
│  ┌─────────────────────────────────────┐  │
│  │ Tanggal    │ Transaksi │ Pendapatan │  │
│  │ 18/06/2026 │    15     │ Rp 2.5jt   │  │
│  │ 19/06/2026 │    23     │ Rp 4.1jt   │  │
│  │ ...        │    ...    │ ...        │  │
│  └─────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

---

## 10. Arsitektur Data (Database)

```
┌─────────┐       ┌─────────────┐       ┌────────────────┐
│  User   │──1:N──│  Product     │       │  ProductUnit   │
│         │       │             │──1:N──│  (multi-unit)   │
└────┬────┘       └──────┬──────┘       └────────────────┘
     │                   │
     │ 1:N               │ N:M (via OrderedProduct)
     │                   │
┌────▼────────────┐   ┌──▼──────────────┐
│  Transaction    │──1:N──│ OrderedProduct │
│                 │       │                │
│ • paymentMethod │       │ • quantity     │
│ • totalAmount   │       │ • priceType    │
│ • paymentStatus │       │ • unit         │
│ • paymentQR     │       │ • price        │
└─────────────────┘       └────────────────┘

┌──────────────┐
│ QueuedAction │  (offline sync queue)
│ • repository │
│ • method     │
│ • param JSON │
└──────────────┘
```

---

## 11. Stack Teknologi

| Komponen | Teknologi |
|----------|-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod (Notifier/State) |
| Routing | GoRouter |
| Database Lokal | SQLite (sqflite) |
| Backend Remote | Supabase |
| Autentikasi | Supabase Auth (Google + Email/Password) |
| Storage | S3-compatible (AWS Signature V4) |
| Pembayaran Digital | KlikQRIS QRIS API (sandbox + production) + webhook `klikqris-notify` |
| Suara & TTS | `flutter_tts` (id-ID) + `audioplayers` (`cashmasuk.mp3`, terbilang rupiah) |
| App Update | GitHub Releases API + `open_filex` installer (`AppUpdate` clean-arch module) |
| Scanner | `mobile_scanner` (kamera) + HID listener (hardware scanner) |
| Printer | unified_esc_pos_printer (USB/BT/BLE/Network) |
| Arsitektur | Clean Architecture (5 layer) |
| Pattern | Result type, Usecase pattern, Offline-first |

---

## 12. Diagram Alur Data (Data Flow)

```
┌─────────────────────────────────────────────────────────────┐
│                       USER INTERFACE                         │
│   (Screens / Widgets via ConsumerWidget / ConsumerStatefulWidget) │
└──────────────────────────┬──────────────────────────────────┘
                           │ ref.read(notifierProvider)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                        NOTIFIER (Riverpod)                   │
│   • Menerima event UI & memanggil Usecase / Repository      │
│   • Mengelola State (Loading / Success / Error)             │
│   • Contoh: HomeNotifier, ProductsNotifier, AuthNotifier    │
└──────────────────────────┬──────────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
┌─────────────────────┐ ┌──────────┐ ┌─────────────────────┐
│  USECASE (Opsional)  │ │ LANGSUNG │ │        USECASE       │
│  (Kompleks > 1 repo) │ │ KE REPO  │ │  (Kompleks > 1 repo) │
│  Contoh:             │ │(Sederhana)│ │  Contoh:             │
│  ProcessQueuedAction │ │          │ │  GetDailyRevenue     │
│  UploadUserPhoto     │ │          │ │                      │
└──────────┬──────────┘ └────┬─────┘ └──────────┬──────────┘
           │                 │                  │
           ▼                 ▼                  ▼
┌──────────────────────────────────────────────────────────────┐
│                     REPOSITORY IMPL                           │
│  • Koordinasi Local Datasource + Remote Datasource            │
│  • Cek SyncService.isOnline untuk write                       │
│  • Queue action jika offline                                  │
└──────────┬──────────────────────────┬────────────────────────┘
           │                          │
           ▼                          ▼
┌─────────────────────┐   ┌─────────────────────────────┐
│ LOCAL DATASOURCE     │   │ REMOTE DATASOURCE            │
│ (SQLite)             │   │ (Supabase REST API)          │
│ • Read/Write lokal   │   │ • Read/Write remote          │
│ • Cepat, offline     │   │ • Untuk backup & multi-device│
└─────────────────────┘   └─────────────────────────────┘
```

---

## 13. Routing Map

```
/                          → SplashScreen
/login                     → LoginScreen
/error                     → ErrorScreen

/payment/qris              → KlikQrisPaymentScreen (full-screen overlay, PopScope confirm-cancel)

ShellRoute (Bottom Navigation - MainScreen):
  /home                    → HomeScreen (POS kasir)
  /products                → ProductsScreen (daftar produk)
    /products/product-create          → ProductFormScreen (tambah, admin only)
    /products/product-edit/:id        → ProductFormScreen (edit, admin only)
    /products/product-detail/:id      → ProductDetailScreen
  /transactions            → TransactionsScreen (riwayat)
    /transactions/transaction-detail/:id → TransactionDetailScreen (cetak manual)
  /account                 → AccountScreen (pengaturan)
    /account/profile                  → ProfileFormScreen
    /account/store-settings           → StoreSettingsScreen (admin only)
    /account/printer-settings         → PrinterSettingsScreen
    /account/payment-settings         → PaymentSettingsScreen (KlikQRIS, admin only)
    /account/product-data             → ProductDataScreen (backup JSON, admin only)
    /account/app-update               → AppUpdateScreen (admin only)
    /account/revenue                  → RevenueScreen (admin only)
    /account/about                    → AboutScreen
    /account/customers                → CustomerScreen (+ customer-form)
    /account/employees                → EmployeesScreen (+ employee-form, admin only)
```

Admin-only paths (`AppRoutes._adminOnlyPaths`, kasir di-redirect ke `/home`):
`/account/employees`, `/account/store-settings`, `/account/revenue`,
`/account/payment-settings`, `/account/product-data`, `/account/app-update`,
`/products/product-create`, `/products/product-edit`.

---

## 14. Skenario End-to-End (Kasir)

```
1. KASIR BUKA APLIKASI
   Splash → Cek sesi → Login (email/password atau Google)
     ↓
2. Home Screen (POS)
   - Pilih tipe harga (Retail/Grosir)
   - Ketik nama pelanggan (opsional)
     ↓
3. TAMBAH PRODUK KE KERANJANG
   - Tap produk dari grid → otomatis masuk keranjang
   - Atau scan barcode → produk ditemukan & ditambahkan
   - Ubah qty, pilih satuan jika multi-unit
     ↓
4. CHECKOUT
   - Pilih metode bayar
     ├── CASH: quick amount (Uang Pas/50rb/100rb) atau custom → hitung kembalian
     └── QRIS: Generate QR → pelanggan scan → auto-poll 3x @15s / tombol manual /
         webhook klikqris-notify → suara kasir + TTS → detail transaksi
     ↓
5. TRANSAKSI TERSIMPAN
   - Local SQLite ✅
   - Remote Supabase (jika online) / Queue (jika offline)
   - Stok produk berkurang
     ↓
6. CETAK STRUK (opsional)
   - Printer thermal → struk keluar
     ↓
7. RESET → Kembali ke step 2 untuk transaksi berikutnya
```

---

## 15. Skenario End-to-End (Admin)

```
1. ADMIN LOGIN
   Splash → Login dengan akun admin
     ↓
2. KELOLA PRODUK
   - Tambah produk baru (nama, harga, stok, barcode, foto, multi-unit)
   - Edit produk yang sudah ada
   - Hapus produk
     ↓
3. LIHAT TRANSAKSI
   - Riwayat transaksi (search, filter)
   - Detail transaksi
   - Cetak ulang struk
   - Hapus transaksi jika perlu
     ↓
4. PENGATURAN
   - Edit profil toko (nama, alamat, footer struk)
   - Setup printer thermal
   - Konfigurasi pembayaran QRIS
     ↓
5. LAPORAN PENDAPATAN
   - Pilih rentang tanggal
   - Lihat rekap harian (total transaksi, total pendapatan)
     ↓
6. KONTROL SINKRONISASI
   - Cek status: Auto / Online / Offline
   - Lihat antrian yang pending
   - Trigger sinkronisasi manual jika perlu
     ↓
7. LOGOUT
   - Hapus sesi → Kembali ke Login Screen
```
