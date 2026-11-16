# Mono POS

[![License: MIT](https://img.shields.io/badge/license-MIT-orange)](./LICENSE)
[![Made with Flutter](https://img.shields.io/badge/made%20with-Flutter-blue)](https://flutter.dev/)

> **Rilis saat ini:** `1.3.17` (`versionCode 34`).

> 🚀 Proyek ini adalah model dasar dari [Zirel POS](https://zirelpos.com/). Jika Anda ingin aplikasi POS yang siap pakai dan lengkap fiturnya, Anda bisa mencobanya — gratis, tanpa perlu kartu kredit.

Aplikasi Point of Sale (POS) berbasis Flutter yang menerapkan prinsip **Clean Architecture** dan pola **offline-first**. Proyek ini berfungsi sebagai bahan belajar dan implementasi referensi untuk membangun aplikasi Flutter dengan arsitektur yang rapi serta sinkronisasi data otomatis antara penyimpanan lokal (SQLite) dan backend cloud (Supabase Postgres).

Aplikasi mengutamakan operasi lokal: semua data disimpan di SQLite sebagai sumber kebenaran lalu didorong otomatis ke Supabase saat online. Ketika offline, seluruh aksi pengguna (create, update, delete) dicatat sebagai `QueuedActions` di database lokal dan dieksekusi berurutan secara otomatis saat koneksi internet kembali.

<br/>
<p align="left">
  <img src="docs/screenshoot_2.jpeg" alt="Image 2" height="350" style="margin-right: 10px;">
  <img src="docs/screenshoot_1.jpeg" alt="Image 1" height="350" style="margin-right: 10px;">
  <img src="docs/screenshoot_3.jpeg" alt="Image 2" height="350" style="margin-right: 10px;">
  <img src="docs/screenshoot_4.jpeg" alt="Image 2" height="350" style="margin-right: 10px;">
  <img src="docs/screenshoot_5.jpeg" alt="Image 2" height="350">
</p>

## APK Demo

[Unduh APK Demo](https://github.com/monodev-id/MonoPOS/releases)

## Fitur

### Fungsionalitas Inti

- **Manajemen Produk**: CRUD lengkap produk dengan dukungan gambar produk, definisi multi-satuan, harga bertingkat (ecer/grosir), HPP manual (`costPrice`), dan dukungan barcode
- **Harga Bertingkat per Bundel**: pemecahan kuantitas per satuan (`ProductTieredPrice`) dengan pratinjau harga langsung di dialog tambah-ke-keranjang
- **Backup Data Produk**: export/import JSON untuk produk + satuan + harga bertingkat, lengkap dengan rincian per produk, overlay sukses, dan dialog konfirmasi import (khusus admin, `Akun → Data Produk`)
- **Cetak Label Barcode (Admin)**: generate kode EAN-13 unik untuk produk yang belum punya barcode, simpan sekaligus, lalu cetak label secara batch dengan jumlah salinan per produk (`Akun → Label Barcode`); pencetakan memerlukan printer yang terhubung
- **Transaksi Penjualan**: antarmuka POS dengan manajemen keranjang, toggle ecer/grosir per item, input harga kustom, dan riwayat transaksi
- **Nominal Cepat Checkout**: tombol pintas `Uang Pas` / 50rb / 100rb serta kolom nominal kustom di sheet checkout
- **Input Barcode**: pemindai kamera (`mobile_scanner`) plus listener hardware scanner HID; keduanya mencari produk di SQLite terlebih dahulu lalu langsung menambahkan produk hasil pindai ke keranjang (+1 satuan dasar) tanpa membuka dialog
- **Peringatan Stok Rendah**: `AppLowStockDialog` memblokir/mengonfirmasi ketika stok tidak mencukupi
- **Cetak Struk Thermal**: cetak struk transaksi via printer USB, Bluetooth, BLE, atau jaringan dengan ukuran kertas yang bisa diatur (58mm, 72mm, 80mm); banner + badge status koneksi tersinkron dari `PrinterManager`, printer tersimpan otomatis reconnect saat startup/resume, dan cetak manual dari detail transaksi (tanpa auto-print)
- **Pembayaran (QRIS DANA Bisnis)**: unggah QRIS statis DANA Bisnis Anda sekali di `Akun → Pengaturan Pembayaran`; saat checkout Mono POS mengubahnya menjadi QRIS dinamis dengan nominal yang tepat (EMVCo TLV + CRC16, hasil porting dari BITS-QRIS-Converter) lalu merender payload tersebut secara langsung. Listener notifikasi Android native selalu memantau notifikasi DANA dan otomatis menandai transaksi `pending` yang cocok sebagai `paid`, dengan hitung mundur kedaluwarsa, pencocokan kode unik, fallback manual "Tandai Lunas", serta suara kasir + TTS
- **Onboarding Akses Notifikasi DANA**: Android tidak menyediakan dialog izin runtime untuk Notification Listener, jadi aplikasi menampilkan dialog sendiri setelah login (`Aktifkan Akses Notifikasi`) dengan pilihan `Nanti` (snooze 24 jam) atau `Buka Pengaturan`. Jika izin masih ditolak setelah kembali dari Settings, muncul panduan **Restricted Settings** dengan tombol `Buka Info Aplikasi`. Selama izin belum ada atau service belum tersambung, banner pengingat persisten tampil di Beranda; status di-refresh, service di-rebind, dan antrean notifikasi diproses ulang setiap aplikasi resume
- **QRIS Langsung**: pembayaran QRIS nominal-first tanpa menambah produk ke keranjang (`/payment/direct`), dapat diakses dari app bar Beranda dan Transaksi; mencakup nominal cepat, deskripsi/pelanggan opsional, badge merchant, dan penjagaan konfigurasi. Transaksi yang tercatat memakai nominal hasil pindai ditambah kode unik otomatis
- **Insight Bisnis (Admin, di perangkat)**: layar `Akun → Insight AI` (`/account/insights`) menghitung insight langsung di perangkat dari transaksi `paid` + data produk — **tanpa panggilan jaringan dan tanpa LLM**. Filter periode 7/14/30 hari, kartu ringkasan performa (omzet, jumlah transaksi, pcs terjual, rata-rata struk, tren 7 hari, porsi ecer, porsi QRIS), lalu kartu insight yang diurutkan berdasarkan severity: tren omzet, produk terlaris, lambat laku (14 hari), margin rendah (<10%), prediksi restock (7/14 hari), jam ramai, peluang pembayaran QRIS, dan komposisi ecer vs grosir. Tersedia tombol `Lihat produk`, serta penjaga data minim (minimal 5 transaksi / 10 pcs) sebelum insight ditampilkan
- **Manajemen Supplier & Pembelian (Admin, lokal saja)**: direktori supplier/grosir plus nota pembelian multi-item; menampilkan/mengisi otomatis harga beli terakhir per supplier, bisa menambah stok per nota, dan memperbarui HPP produk (`costPrice`) dari pembelian terbaru. Menghapus nota menghitung ulang stok dan HPP. Data supplier/pembelian belum disinkronkan ke Supabase
- **Suara & Voice Pembayaran**: suara kasir (`cashmasuk.mp3`) + pengumuman TTS bahasa Indonesia (nominal terbilang) saat pembayaran QRIS berhasil, dapat diaktifkan/dinonaktifkan di pengaturan pembayaran
- **Manajemen Pelanggan**: direktori pelanggan dengan formulir yang terintegrasi ke alur penjualan
- **Manajemen Karyawan**: kontrol akses berbasis peran (admin / kasir) dengan akun karyawan; route dan menu khusus admin disembunyikan/dialihkan untuk kasir
- **Laporan Pendapatan**: laporan pendapatan harian yang difilter berdasarkan status lunas, dengan rincian tunai/QRIS/lainnya, jumlah produk, detail transaksi per hari, dan total semua pengguna untuk admin
- **Pembaruan Aplikasi (Admin)**: cek rilis GitHub, lihat changelog (Markdown), progres unduhan, dan instal APK via `Akun → Pembaruan Aplikasi`
- **Konfigurasi Supabase Runtime**: dialog `Akun → Supabase Sync` menyimpan URL + anon key di `SharedPreferences` — tanpa perlu rebuild; restart menerapkan koneksi baru
- **Autentikasi Pengguna**: Supabase Auth dengan Google Sign-In dan email/password
- **Akun & Manajemen Toko**: profil pengguna, pengaturan nama/alamat toko, footer struk, dan pengaturan printer
- **Lokalisasi**: bahasa Indonesia dan Inggris via `flutter_localizations` (file ARB)
- **UI Adaptif**: breakpoint tablet/desktop (`AppSizes.isTablet/isDesktop`), dialog max-width terpusat, navigation rail pada layar lebar

### Implementasi Teknis

- **Arsitektur Offline-First**: berjalan tanpa koneksi internet
- **Sinkronisasi Data Otomatis**: SQLite → Supabase (Postgres) satu arah; SQLite tetap menjadi sumber kebenaran, Supabase adalah mirror hasil sinkronisasi
- **Queued Actions**: mekanisme retry otomatis untuk operasi offline (create, update, delete), diputar ulang berurutan dengan `isCritical ASC, createdAt ASC`
- **Clean Architecture**: pemisahan lapisan presentation, domain, dan data
- **State Management**: Riverpod untuk manajemen state yang lebih aman dan mudah diuji
- **Dependency Injection**: setup DI terpusat agar kode lebih terorganisir
- **Backend Cloud**: Supabase (Postgres + Auth) menggantikan Firebase/Firestore
- **Layanan Domain QRIS**: paket `core/services/qris/` berisi `qris_converter` (statis → dinamis), `qris_normalizer` (membuang nominal/biaya lama dan mengubah QRIS dinamis hasil unggahan menjadi statis), `qris_validator`, serta helper `qris_tlv`, `qris_crc16`, dan `qris_merchant_info`
- **Pemrosesan Gambar Lokal**: gambar produk dipilih/di-crop di perangkat dan di-cache di penyimpanan aplikasi; QRIS yang diunggah didekode di perangkat (MLKit dengan fallback `zxing2`/decoder Dart) lalu file gambarnya dihapus — hanya string payload yang disimpan
- **InsightCalculator**: kalkulator insight berupa static class yang deterministik dan teruji unit (`insight_calculator_test.dart`), membaca transaksi + produk langsung dari repository tanpa layanan eksternal
- **Modul Domain Lokal Saja**: supplier dan pembelian memakai alur clean-architecture yang sama (datasource → repository → usecase → notifier) tetapi hanya menulis ke SQLite untuk saat ini; HPP produk (`costPrice`) dan metadata pembayaran DANA juga disimpan lokal
- **Label Barcode**: pembuatan EAN-13 via `BarcodeGenerator` dan render label dengan `barcode_widget`
- **App Update Service**: GitHub Releases API + unduh/instal APK (`open_filex`, `package_info_plus`)
- **Audio Feedback**: `flutter_tts` (id-ID/en-US) + `audioplayers` untuk konfirmasi pembayaran
- **Unit Testing**: tes untuk datasource, repository, dan use case (termasuk kalkulator insight, konversi/normalisasi QRIS, dan kebijakan prompt izin DANA)
- **Material Design 3**: Material Design 3 dengan dukungan pergantian tema Gelap & Terang
- **Tema yang Dapat Dikustomisasi**: warna dan tipografi yang bisa diatur
- **Multi-Platform**: mendukung Android, iOS, Windows, macOS, dan Linux
- **Penanganan Error**: pesan error dan state yang ramah pengguna
- **Widget Reusable**: komponen UI kustom untuk desain yang konsisten

## Arsitektur

<img src="docs/architecture.png" alt="Arsitektur">

## Struktur Proyek

```
mono_pos/
├── lib/
│   ├── app/                          # Setup dan konfigurasi aplikasi
│   │   ├── di/                       # Dependency injection
│   │   ├── error/                    # Penanganan error
│   │   └── routes/                   # Routing dan navigasi aplikasi
│   │
│   ├── core/                         # Utilitas inti dan resource bersama
│   │   ├── assets/                   # Manajemen aset
│   │   ├── common/                   # Utilitas umum (wrapper Result)
│   │   ├── constants/                # Konstanta aplikasi
│   │   ├── extensions/               # Ekstensi Dart
│   │   ├── locale/                   # Helper lokalisasi
│   │   ├── services/                 # Layanan inti
│   │   │   ├── connectivity/         # Pengecekan konektivitas jaringan
│   │   │   ├── database/             # Layanan database lokal (sqflite)
│   │   │   ├── info/                 # Layanan info perangkat
│   │   │   ├── insight/              # Kalkulator insight bisnis di perangkat
│   │   │   ├── logger/               # Layanan logging error
│   │   │   ├── payment/              # Layanan DANA (parser, store, listener, decoder QRIS)
│   │   │   ├── printer/              # Layanan printer thermal
│   │   │   ├── qris/                 # Konversi, normalisasi, validasi QRIS (TLV + CRC16)
│   │   │   ├── supabase/             # Konfigurasi klien Supabase + kredensial runtime
│   │   │   ├── sync/                 # Sinkronisasi / pemrosesan queued action
│   │   │   ├── tts/                  # Voice TTS + suara kasir
│   │   │   └── update/               # Cek rilis GitHub + installer APK
│   │   ├── themes/                   # Tema aplikasi (warna, ukuran, tema)
│   │   ├── usecase/                  # Interface usecase dasar
│   │   └── utilities/                # Utilitas pembantu (formatter, logger, dll.)
│   │
│   ├── data/                         # Lapisan data
│   │   ├── datasources/              # Sumber data
│   │   │   ├── interfaces/           # Interface datasource (auth, product, transaction, purchase, supplier, app-update, ...)
│   │   │   ├── local/                # Datasource lokal (sqflite; produk, transaksi, pelanggan, supplier, pembelian, queue)
│   │   │   └── remote/               # Datasource remote (Supabase, Auth, AppUpdate/GitHub)
│   │   ├── models/                   # Model data dengan serialisasi JSON (termasuk purchase, purchase_item, supplier, app_update)
│   │   └── repositories/             # Implementasi repository (termasuk purchase, supplier, app_update)
│   │
│   ├── domain/                       # Lapisan domain (logika bisnis)
│   │   ├── entities/                 # Entity bisnis (termasuk purchase, purchase_item, supplier, app_update, ai_insight)
│   │   ├── repositories/             # Interface repository (termasuk purchase, supplier, app_update)
│   │   └── usecases/                 # Use case (termasuk purchase, supplier, app_update, insight)
│   │
│   ├── presentation/                 # Lapisan presentation (UI)
│   │   ├── providers/                # Manajemen state (Riverpod)
│   │   │   ├── account/              # State akun, toko, printer, pembayaran, data produk, label barcode & pembaruan aplikasi
│   │   │   ├── auth/                 # State autentikasi
│   │   │   ├── customer/             # State manajemen pelanggan
│   │   │   ├── employees/            # State karyawan / RBAC
│   │   │   ├── home/                 # State layar Beranda (keranjang, pindai barcode)
│   │   │   ├── insights/             # State insight bisnis (AI insight notifier + state)
│   │   │   ├── language/             # State lokalisasi
│   │   │   ├── main/                 # State navigasi utama
│   │   │   ├── payment/              # State pembayaran QRIS + listener DANA + kebijakan prompt izin
│   │   │   ├── products/             # State manajemen produk (+ info pembelian)
│   │   │   ├── purchases/            # State list, form, dan detail pembelian
│   │   │   ├── revenue/              # State laporan pendapatan + detail harian
│   │   │   ├── splash/               # State splash
│   │   │   ├── suppliers/            # State list/form supplier
│   │   │   ├── theme/                # State tema
│   │   │   └── transactions/         # State transaksi
│   │   ├── screens/                  # Layar UI
│   │   │   ├── account/              # Akun, pengaturan toko/printer/pembayaran, data produk, label barcode, pembaruan aplikasi, Tentang
│   │   │   ├── auth/                 # Layar autentikasi
│   │   │   ├── customer/             # Layar pelanggan
│   │   │   ├── employees/            # Layar manajemen karyawan
│   │   │   ├── error/                # Layar error
│   │   │   ├── home/                 # Layar Beranda/POS (+ pemindai barcode, listener HID, panel keranjang, banner izin DANA)
│   │   │   ├── insights/             # Layar Insight AI + komponen kartu insight & ringkasan
│   │   │   ├── main/                 # Layar navigasi utama (+ onboarding izin DANA)
│   │   │   ├── payment/              # Layar pembayaran QRIS + QRIS langsung
│   │   │   ├── products/             # Layar manajemen produk (+ info pembelian)
│   │   │   ├── purchases/            # Layar list/form/detail pembelian
│   │   │   ├── revenue/              # Layar laporan pendapatan + detail harian
│   │   │   ├── splash/               # Layar splash
│   │   │   ├── suppliers/            # Layar list/form supplier
│   │   │   └── transactions/         # Layar riwayat transaksi
│   │   └── widgets/                  # Komponen UI reusable (`app_*`: button, dialog, text field,
│   │                                  # success overlay, low-stock dialog, price-type toggle, ...)
│   │
│   ├── l10n/                         # File ARB lokalisasi (app_en, app_id)
│   ├── generated/                    # Kode lokalisasi hasil generate (flutter gen-l10n)
│   └── main.dart                     # Entry point aplikasi
│
├── test/                             # Unit dan widget test
│   ├── core/
│   │   ├── services/                 # Tes layanan (connectivity, database, info, logger, payment, qris)
│   │   └── utilities/                # Tes utilitas
│   ├── data/                         # Tes lapisan data
│   │   ├── datasources/              # Tes datasource (local + remote)
│   │   ├── models/                   # Tes model
│   │   └── repositories/             # Tes repository
│   ├── domain/                       # Tes entity + usecase
│   ├── presentation/                 # Tes provider, layar, dan widget
│   │   ├── providers/                # Tes notifier (termasuk home cart, payment, purchase form)
│   │   └── screens/                  # Tes layar/widget (auth/sign_in, purchases)
│   ├── fixtures/                     # Fixture pengujian (mis. gambar QRIS)
│   └── ...
│
├── assets/                           # Aset statis
├── android/                          # File platform Android
├── ios/                              # File platform iOS
├── linux/                            # File platform Linux
├── macos/                            # File platform macOS
├── web/                              # File platform Web
├── windows/                          # File platform Windows
├── cloudflare/                       # Worker webhook pembayaran lama (referensi saja, sudah tidak dipakai)
├── supabase/                         # Konfigurasi Supabase & edge function
│
├── analysis_options.yaml             # Konfigurasi analyzer Dart
├── pubspec.yaml                      # Dependensi package
└── README.md                         # Dokumentasi proyek
```

## Memulai

### Prasyarat

- [Flutter](https://flutter.dev/docs/get-started/install)
- [Dart](https://dart.dev/get-dart)
- Proyek [Supabase](https://supabase.com/) untuk backend cloud

### Instalasi

1. **Clone repository:**

   ```sh
   git clone https://github.com/monodev-id/MonoPOS.git
   cd MonoPOS
   ```

2. **Pasang dependensi:**

   ```sh
   flutter pub get
   ```

3. **Siapkan Supabase:**
   - Buat proyek baru di [Supabase](https://supabase.com/).
   - Skema SQLite lokal (lihat [`DATABASE.md`](DATABASE.md)) mencerminkan tabel Postgres remote. Buat tabel yang sesuai di proyek Supabase Anda (lihat `docs/supabase/schema.sql`), atau biarkan lapisan sync mengisinya setelah run pertama.
   - Aktifkan penyedia auth **Google** dan konfigurasikan redirect/callback OAuth.
   - (Opsional) Konfigurasikan Row Level Security agar baris dibatasi ke pengguna yang terautentikasi.

   > **Disarankan (konfigurasi runtime):** setelah aplikasi terpasang, buka **Akun → Supabase Sync**,
   > masukkan URL proyek + anon/publishable key, tekan Simpan, lalu restart aplikasi. Tidak perlu rebuild —
   > satu binary dapat melayani banyak toko.

4. **(Opsional) `config.json` saat build**

   Untuk build yang sudah dibekali konfigurasi, Anda tetap bisa mengirim konfigurasi backend via `--dart-define-from-file`.
   Buat `config.json` di root proyek (contoh di `config.example.json`):

   ```json
   {
     "SUPABASE_URL": "https://your-project.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "your-publishable-anon-key",
     "GOOGLE_SERVER_CLIENT_ID": "xxxxx.apps.googleusercontent.com"
   }
   ```

   | Key | Deskripsi |
   | --- | --- |
   | `SUPABASE_URL` | URL proyek Supabase Anda |
   | `SUPABASE_PUBLISHABLE_KEY` | Anon/publishable key Supabase (alias lama: `SUPABASE_ANON_KEY`) |
   | `SUPABASE_SECRET_KEY` | Service-role key opsional untuk tugas server yang istimewa |
   | `GOOGLE_SERVER_CLIENT_ID` | Web client ID dari penyedia Google Sign-In di Supabase |

   Jika `Supabase` belum dikonfigurasi, aplikasi tetap berjalan penuh secara offline — fitur sync dan remote dinonaktifkan otomatis.
   Kredensial runtime yang dimasukkan di aplikasi diprioritaskan di atas nilai saat build.

5. **Jalankan aplikasi:**

   ```sh
   flutter run
   # atau dengan konfigurasi yang sudah dibekali:
   flutter run --dart-define-from-file config.json
   ```

### Pengujian

Untuk menguji aplikasi, jalankan perintah berikut:

```sh
flutter test --coverage
```

Untuk melihat cakupan pengujian Anda bisa menggunakan `genhtml` atau [test_cov_console](https://pub.dev/packages/test_cov_console)

## Pembayaran (QRIS DANA Bisnis)

Mono POS memakai **QRIS statis merchant DANA Bisnis** yang dikonversi menjadi **QRIS dinamis** saat checkout. Tidak ada payment API, webhook, atau polling: string QRIS merchant adalah sumber kebenaran dan `NotificationListenerService` Android membaca notifikasi pembayaran DANA untuk mengonfirmasi pembayaran.

Setup:

1. Buka `Akun → Pengaturan Pembayaran` (admin).
2. Unggah tangkapan layar QRIS statis DANA Bisnis, pindai dengan kamera, atau tempel payload QRIS. Gambar didekode di perangkat lalu dihapus; hanya string payload yang disimpan di `SharedPreferences`.
3. Validasi info merchant (nama, kota, NMID) yang ditampilkan aplikasi lalu simpan.

Dua alur berbagi layar yang sama (`/payment/qris`):

- **Checkout keranjang** — transaksi dibangun dari keranjang, lalu QRIS statis dikonversi dengan `nominal = total + kode unik` sebelum disimpan, sehingga tidak ada transaksi setengah jadi atau pengurangan stok yang tertinggal jika QRIS tidak valid.
- **QRIS langsung** — buka `/payment/direct`, masukkan nominal (plus deskripsi/pelanggan opsional), dan buat transaksi `qris` tanpa menyentuh stok produk.

### Akses notifikasi

Android tidak memiliki dialog izin runtime untuk Notification Listener, sehingga aplikasi mengelolanya sendiri:

- Setelah login, dialog `Aktifkan Akses Notifikasi` muncul sekali per sesi bila listener aktif tetapi izin belum diberikan.
- Tombol `Nanti` menyimpan snooze **24 jam**; tombol `Buka Pengaturan` melakukan deep-link ke detail listener (Android 11+) dengan fallback ke daftar listener dan info aplikasi.
- Jika izin masih diblokir setelah kembali dari Settings, muncul panduan **Restricted Settings** dengan tombol `Buka Info Aplikasi`.
- Banner pengingat persisten di Beranda tampil selama izin belum ada atau service belum tersambung.
- Setiap aplikasi resume, status izin di-refresh, service di-rebind, dan antrean notifikasi diproses ulang.

Alur umum:

1. Saat checkout aplikasi mengalokasikan kode unik (1–99, fallback 100–999) untuk nominal, mengonversi QRIS statis menjadi payload dinamis, menyimpan transaksi sebagai `pending`, lalu menampilkan QR (dirender dari payload, bukan gambar).
2. Pelanggan memindai dan membayar dengan aplikasi apa pun yang mendukung QRIS.
3. DANA mengirim notifikasi; listener native mengantrekannya secara durable dan Flutter mem-parse nominalnya. Ketika tepat satu transaksi `pending` cocok dengan `paymentExpectedAmount`, transaksi ditandai `paid`, aplikasi memutar suara kasir dan mengumumkan nominal via TTS bahasa Indonesia.
4. `Cek Pembayaran` menguras antrean notifikasi sesuai permintaan; `Tandai Lunas` tersedia sebagai fallback manual.
5. Saat hitung mundur berakhir, transaksi menjadi `expired`; membatalkan akan menghapus transaksi dan mengembalikan stok yang direservasi. Pembayaran yang datang terlambat (hingga 60 menit) tetap dicocokkan dengan transaksi kedaluwarsa.

Preferensi pembayaran (`dana_qris_static`, `dana_unique_code_enabled`, `dana_expiry_minutes`, `dana_tts_enabled`, `dana_listener_enabled`) disimpan secara lokal. Akses notifikasi harus diberikan dari kartu listener (`Buka Akses Notifikasi`). Paket DANA yang dipantau: `id.dana` dan `id.dana.kasir`.

> **Data lokal saja:** supplier, pembelian, HPP produk (`costPrice`), metadata pembayaran DANA, dan tabel `PaymentNotification` hanya disimpan di SQLite. Lapisan sync membuangnya sebelum menulis ke Supabase.

> **Legacy:** Doku SNAP dan KlikQRIS sudah tidak dipakai — lihat [`DOKU_PAYMENT_GATEWAY.md`](DOKU_PAYMENT_GATEWAY.md). Service/provider-nya mungkin masih ada sebagai referensi; jangan membangun fitur baru di atasnya.

## Panduan Agen AI

Proyek ini menyertakan file dokumentasi yang dirancang agar agen coding AI (misalnya Claude Code) tetap konsisten saat memodifikasi proyek:

- [`CLAUDE.md`](CLAUDE.md) — Konvensi proyek (arsitektur, penamaan, gaya kode)
- [`UI.md`](UI.md) — Referensi UI (layout, komponen, spesifikasi desain)
- [`DATABASE.md`](DATABASE.md) — Referensi skema database (tabel, kolom)
- [`WORKFLOW.md`](WORKFLOW.md) — Alur kerja Git (commit, branch, PR)
- [`WORKFLOW_SYSTEM.md`](WORKFLOW_SYSTEM.md) — Referensi alur kerja/sistem sync
- [`SYNC.md`](SYNC.md) — Arsitektur sync offline-first
- [`DOKU_PAYMENT_GATEWAY.md`](DOKU_PAYMENT_GATEWAY.md) — Deprecated (Doku SNAP dan KlikQRIS tidak dipakai; QRIS kini memakai DANA Bisnis)

## Kontribusi

Kontribusi sangat diterima! Silakan buka issue atau kirim pull request untuk bug, permintaan fitur, atau perbaikan.

## Lisensi

Proyek ini dilisensikan di bawah MIT License - lihat file [LICENSE](LICENSE) untuk detailnya.
