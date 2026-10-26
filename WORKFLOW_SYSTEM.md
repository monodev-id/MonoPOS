# WORKFLOW Sistem POS - MonoPOS

> Last synced with code: v1.3.7 (Oct 2026). Payment = **KlikQRIS** (Doku retired) with cart checkout
> and direct-nominal QRIS. Supabase via runtime Settings, admin-only routes enforced in `AppRoutes`.
> Supplier/purchase/HPP data is local-only.

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

### 2e. Input Barcode (Kamera + HID + Kolom Pencarian)

```
Kamera: barcode_scanner_screen (mobile_scanner) → lookup database → tambah langsung
HID: barcode_hid_listener (hardware scanner, fokus global) → lookup database → tambah langsung
Kolom pencarian: query 6+ digit dianggap barcode → lookup database → tambah langsung
Lookup: GetProductByBarcodeUsecase (SQLite dulu) → fallback cache daftar produk
Sukses: keranjang +1 satuan dasar (tanpa dialog), SystemSound, snackbar nama/qty
Produk tidak ditemukan → snackbar error; fokus HID dikembalikan untuk scan berikutnya
```

### 2f. Snapshot Satuan di Keranjang

```
Saat item masuk keranjang, HomeNotifier menyimpan snapshot ProductUnit produk
  ↓
Dropdown satuan & perhitungan tiered price memakai snapshot item (bukan cache paginasi)
  ↓
Produk legacy tanpa baris ProductUnit memakai satu unit sintetis (base unit)
```

### 2g. Validasi Stok Rendah

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
      │    └── Expired ❌ → update expired    │
      │ 5. Back/close → dialog konfirmasi     │
      │    (hindari batal tak sengaja)        │
      │ 6. Webhook klikqris-notify (opsional) │
      │    mempercepat paid via Supabase      │
      └──────────────────────────────────────┘
```

### 3a. Direct QRIS (Nominal Langsung)

```
Home/Transactions AppBar → ikon QR (/payment/direct)
  ↓
DirectQrisScreen: nominal + quick amount (10rb/25rb/50rb/100rb)
  + keterangan & nama pelanggan (opsional)
  ↓
Belum dikonfigurasi?
  ├── Admin → tombol Buka Pengaturan (Payment Settings)
  └── Kasir → pesan hubungi admin
  ↓
Create QRIS → simpan transaksi qris (pending, tanpa kurangi stok)
  → generateQris → KlikQrisPaymentScreen
  ↓
Nominal transaksi = nominal input; kode unik KlikQRIS hanya ditampilkan
```

### 3b. Simpan Transaksi (Detail)

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

> Form produk juga menyimpan **HPP** (`costPrice`, opsional). Nilai ini otomatis diperbarui dari nota
> pembelian terbaru. Detail produk menampilkan HPP, estimasi untung, harga terakhir per supplier, dan
> riwayat pembelian khusus admin.

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

### 4b. Alur Pembelian & Supplier (HPP)

Fitur pembelian menyimpan nota pembelian multi-item dari supplier/grosir, mengingat harga terakhir
per supplier, menambah stok (opsional per nota), dan memperbarui HPP produk. Semua data pembelian
dan supplier saat ini **lokal (SQLite)** — belum disinkronkan ke Supabase.

```
┌──────────────────────────────────────────────────────────┐
│           PURCHASES SCREEN (/account/purchases)           │
│                                                           │
│  • Daftar nota pembelian (search, pull-to-refresh)        │
│  • Tap → Detail Pembelian                                │
│  • Long-press → Hapus nota                               │
│  • Tombol (+ Catat) → Form Pembelian                     │
│  • Ikon toko → Supplier / Grosir                         │
└───────────┬───────────────────────────────┬───────────────┘
            ▼                               ▼
┌───────────────────────────┐   ┌──────────────────────────┐
│ Purchase Form             │   │ Supplier Screen          │
│ (/account/purchases/create)│  │ (/account/suppliers)     │
│                           │   │                          │
│ • Pilih supplier (+ baru) │   │ • Daftar supplier        │
│ • Tanggal pembelian       │   │ • Search nama/telepon/   │
│ • Switch tambah stok      │   │   alamat                 │
│ • Tambah barang (picker)  │   │ • Tambah / edit          │
│ • Satuan, qty, harga beli │   │ • Hapus (diblokir jika   │
│ • Hint harga terakhir     │   │   masih dipakai nota)    │
│ • Simpan → Detail         │   └──────────────────────────┘
└───────────┬───────────────┘
            ▼
┌──────────────────────────────────────────────────────────┐
│           PURCHASE DETAIL (/account/purchases/detail/:id) │
│  • Supplier, tanggal, catatan, total, jumlah item         │
│  • Rincian barang + HPP satuan dasar                     │
│  • Hapus nota → stok & HPP dihitung ulang                │
│  • "Catat Pembelian Lagi"                                 │
└──────────────────────────────────────────────────────────┘
```

Aturan perhitungan:

```
Stok bertambah        = round(quantity / conversionValue)
                        (sama dengan aturan pengurangan stok saat penjualan)
HPP satuan dasar      = round(unitPrice / conversionValue)
Product.costPrice     = baseUnitPrice dari PurchaseItem terbaru
                        (purchaseDate DESC, Purchase.id DESC, PurchaseItem.id DESC)
Hapus nota            = stok dikurangi hanya jika Purchase.addStock = 1,
                        lalu HPP dihitung ulang dari nota yang tersisa (0 jika habis)
Harga terakhir        = PurchaseItem terbaru untuk produk + supplier terpilih;
                        jika belum ada, fallback ke supplier lain
```

Catatan:
- Nama supplier unik case-insensitive; menghapus supplier ditolak selama masih ada nota yang memakai `supplierId`.
- Satu nota tidak boleh berisi baris produk + satuan yang sama (ditambahkan sebagai baris terpisah).
- Form produk menyimpan `costPrice`; sinkronisasi produk ke Supabase tetap membuang `costPrice` karena
  kolom tersebut belum ada di tabel remote.

### 4c. Cetak Label Barcode (Admin)

```
Account → Barcode Labels (/account/barcode-labels)
  ↓
Generate kode EAN-13 unik untuk produk tanpa barcode
  (BarcodeGenerator + cek duplikat via product repository)
  ↓
Simpan massal → update Product.barcode lewat UpdateProductUsecase
  (produk + refresh daftar produk/beranda, tetap masuk alur sync produk)
  ↓
Pilih produk (search/filter with/without barcode) + jumlah salinan
  ↓
Print label → PrinterService (butuh printer terhubung)
  ├── Belum terhubung → dialog → Printer Settings
  └── Terhubung → kirim label batch, sukses overlay
```

Produk baru juga bisa dibuat langsung dari layar ini: isi nama → Generate kode → Save Product → Print Label.

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
│  │ 👥 Karyawan        → /account/employees │
│  │ 🏪 Pengaturan Toko → /account/store  │ │
│  │ 📊 Laporan Pendapatan → /account/rev  │ │
│  │ 🧑 Pelanggan       → /account/customers │
│  │ 🏬 Supplier/Grosir → /account/suppliers │
│  │ 📦 Pembelian       → /account/purchases │
│  │ 🎨 Tema / 🌐 Bahasa                  │ │
│  │ 🖨️ Pengaturan Printer → /account/...  │ │
│  │ 🏷️ Label Barcode   → /account/barcode-labels │
│  │ 💳 Pengaturan Pembayaran → /account/..│ │
│  │ 💾 Data Produk     → /account/product-data │
│  │ ⬆️  App Update     → /account/app-update │
│  │ ☁️  Supabase Sync  → dialog runtime   │ │
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
- Auto-reconnect printer tersimpan saat app start/resume; banner + badge mengikuti `PrinterManager`

### 8c. Pengaturan Pembayaran (KlikQRIS)

- API Key, Merchant ID, toggle Sandbox (default **Production**), toggle suara/TTS (`klikqris_tts_enabled`)
- Tombol **Save** eksplisit + `AppSuccessOverlay`; tidak ada write per ketikan
- Kosong (API key/merchant) = **mock mode** untuk development (QR mock, paid ±30s)

### 8d. Data Produk (Backup)

- `Account → Product Data` (admin only): export JSON (produk + unit + tier) dengan rincian
  per produk + progress; import dengan dialog konfirmasi, overwrite lokal
- File dibagikan via file picker/share; simpan salinan di tempat aman

### 8e. Label Barcode (Admin)

- `Account → Barcode Labels`: generate/save EAN-13 untuk produk tanpa barcode, filter
  with/without barcode, pilih semua, atur jumlah salinan, lalu print batch
- Produk baru bisa langsung dibuat + disimpan dari layar ini
- Print membutuhkan printer terhubung; jika belum, arahkan ke Printer Settings

### 8f. Supplier & Pembelian (Admin)

- `Account → Suppliers`: daftar/cari supplier, tambah/edit, hapus ditolak jika masih dipakai nota
- `Account → Purchases`: daftar nota, detail, hapus; form mendukung supplier baru, tanggal,
  switch tambah stok, multi-item, dan hint harga terakhir per supplier
- Data lokal saja; HPP produk berasal dari `PurchaseItem.baseUnitPrice` terbaru

### 8g. Pembaruan Aplikasi (App Update, Admin)

```
Account → App Update → checkForUpdate() (GitHub Releases API)
  ├── Versi terbaru → tampilkan changelog (Markdown) + tombol Download
  ├── Download APK (progress) → install via AppInstallerService/open_filex
  └── Sudah terbaru → status "up to date"
```

### 8h. Supabase Sync (Runtime Config)

- `Account → Supabase Sync` (admin only): input URL + anon key → simpan ke
  `SharedPreferences` (`SupabaseCredentials`) → **restart app** untuk aktif
- Indikator: `Aktif` / `Belum diatur`; tombol hapus konfigurasi tersedia
- Tanpa kredensial: app full offline, write di-queue, tombol sync menampilkan `Sync off`

---

## 9. Alur Laporan Pendapatan

```
┌──────────────────────────────────────────┐
│        REVENUE SCREEN (/account/revenue)  │
│                                           │
│  Pilih rentang tanggal (default 30 hari)  │
│    ↓                                      │
│  RevenueNotifier.loadRevenue()            │
│    ↓                                      │
│  GetDailyRevenueUsecase                   │
│    ↓                                      │
│  Query transaksi paid (admin: semua user) │
│    ↓                                      │
│  Tampilkan summary + per hari:            │
│  ┌─────────────────────────────────────┐  │
│  │ Total │ Transaksi │ Produk           │  │
│  │ Cash  │ QRIS      │ Lainnya          │  │
│  │ 18/06/2026 │    15     │ Rp 2.5jt   │  │
│  │ 19/06/2026 │    23     │ Rp 4.1jt   │  │
│  └─────────────────────────────────────┘  │
│    ↓ tap hari                             │
│  REVENUE DAY (/account/revenue/day/:date) │
│  • Ringkasan hari + rincian cash/QRIS/other│
│  • Daftar transaksi hari tersebut         │
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

Relasi pembelian (lokal, belum disinkronkan):

```
┌────────────┐       ┌──────────────┐       ┌────────────────┐
│  Supplier  │──1:N──│   Purchase   │──1:N──│  PurchaseItem  │
│  (lokal)   │       │   (lokal)    │       │    (lokal)     │
└────────────┘       └──────┬───────┘       └───────┬────────┘
                            │ createdById           │ productId
                            ▼                       ▼
                          User                   Product
                                                    │
                                                    ▼
                                              Product.costPrice
                                              (HPP terbaru)
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
| Scanner | `mobile_scanner` (kamera) + HID listener (hardware scanner) + lookup SQLite by barcode |
| Barcode Label | `barcode_widget` + EAN-13 generator (`BarcodeGenerator`) |
| Printer | unified_esc_pos_printer (USB/BT/BLE/Network) |
| Data Pembelian | Supplier/Purchase/PurchaseItem **lokal (SQLite)** — belum disinkronkan |
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
/payment/direct            → DirectQrisScreen (QRIS nominal langsung, entry dari Home/Transactions)

ShellRoute (Bottom Navigation - MainScreen):
  /home                    → HomeScreen (POS kasir; direct QRIS + scan di AppBar)
  /products                → ProductsScreen (daftar produk)
    /products/product-create          → ProductFormScreen (tambah, admin only)
    /products/product-edit/:id        → ProductFormScreen (edit, admin only)
    /products/product-detail/:id      → ProductDetailScreen
  /transactions            → TransactionsScreen (riwayat; direct QRIS di AppBar)
    /transactions/transaction-detail/:id → TransactionDetailScreen (cetak manual)
  /account                 → AccountScreen (pengaturan)
    /account/profile                  → ProfileFormScreen
    /account/store-settings           → StoreSettingsScreen (admin only)
    /account/printer-settings         → PrinterSettingsScreen
    /account/barcode-labels           → ProductBarcodeLabelScreen (admin only)
    /account/payment-settings         → PaymentSettingsScreen (KlikQRIS, admin only)
    /account/product-data             → ProductDataScreen (backup JSON, admin only)
    /account/app-update               → AppUpdateScreen (admin only)
    /account/revenue                  → RevenueScreen (admin only)
      /account/revenue/day/:date      → RevenueDayScreen (admin only)
    /account/about                    → AboutScreen
    /account/customers                → CustomerScreen (+ customer-form)
    /account/employees                → EmployeesScreen (+ employee-form, admin only)
    /account/suppliers                → SupplierScreen (+ suppliers/create, suppliers/edit/:id, admin only)
    /account/purchases                → PurchaseScreen (admin only)
      /account/purchases/create?productId=...  → PurchaseFormScreen
      /account/purchases/detail/:id            → PurchaseDetailScreen
```

Admin-only paths (`AppRoutes._adminOnlyPaths`, kasir di-redirect ke `/home`):
`/account/employees`, `/account/store-settings`, `/account/revenue`,
`/account/payment-settings`, `/account/product-data`, `/account/barcode-labels`,
`/account/app-update`, `/account/suppliers`, `/account/purchases`,
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
   - Tap produk dari grid → dialog qty/satuan/tier
   - Scan barcode (kamera/HID) atau submit barcode di search → lookup DB → +1 langsung
   - Ubah qty, pilih satuan jika multi-unit (snapshot satuan per item)
     ↓
4. CHECKOUT
   - Pilih metode bayar
     ├── CASH: quick amount (Uang Pas/50rb/100rb) atau custom → hitung kembalian
     └── QRIS: Generate QR → pelanggan scan → auto-poll 3x @15s / tombol manual /
         webhook klikqris-notify → suara kasir + TTS → detail transaksi
   - Alternatif tanpa keranjang: tombol QR di AppBar → /payment/direct → input nominal
     ↓
5. TRANSAKSI TERSIMPAN
   - Local SQLite ✅
   - Remote Supabase (jika online) / Queue (jika offline)
   - Stok produk berkurang (kecuali Direct QRIS tanpa produk)
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
   - Tambah produk baru (nama, harga, stok, barcode, HPP, foto, multi-unit, tier)
   - Edit produk yang sudah ada
   - Hapus produk
   - Cetak label barcode untuk produk tanpa barcode (batch + jumlah salinan)
     ↓
3. CATAT PEMBELIAN & SUPPLIER
   - Tambah supplier / grosir (nama unik)
   - Catat nota pembelian multi-item (supplier, tanggal, satuan, qty, harga)
   - Harga terakhir per supplier ditampilkan dan diisikan otomatis
   - Stok bertambah (dapat dimatikan per nota) dan HPP produk diperbarui
   - Hapus nota → stok & HPP dihitung ulang
     ↓
4. LIHAT TRANSAKSI
   - Riwayat transaksi (search, filter)
   - Detail transaksi
   - Cetak ulang struk
   - Hapus transaksi jika perlu
   - Buat QRIS langsung dari nominal (tanpa keranjang)
     ↓
5. PENGATURAN
   - Edit profil toko (nama, alamat, footer struk)
   - Setup printer thermal (+ auto-reconnect)
   - Konfigurasi pembayaran QRIS
   - Backup/import data produk (JSON)
     ↓
6. LAPORAN PENDAPATAN
   - Pilih rentang tanggal
   - Lihat rekap harian + rincian cash/QRIS/other
   - Buka detail transaksi per hari
     ↓
7. KONTROL SINKRONISASI
   - Cek status: Auto / Online / Offline
   - Lihat antrian yang pending
   - Trigger sinkronisasi manual jika perlu
     ↓
8. LOGOUT
   - Hapus sesi → Kembali ke Login Screen
```
