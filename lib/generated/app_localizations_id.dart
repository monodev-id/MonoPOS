// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Mono POS';

  @override
  String get home => 'Beranda';

  @override
  String get products => 'Produk';

  @override
  String get transactions => 'Transaksi';

  @override
  String get settings => 'Pengaturan';

  @override
  String get home_searchHint => 'Cari Produk...';

  @override
  String get home_syncronizing => 'Menyinkronkan';

  @override
  String get home_synced => 'Tersinkron';

  @override
  String get home_pending => 'Menunggu';

  @override
  String get home_onlineMode => 'Mode daring';

  @override
  String get home_noInternet =>
      'Tidak ada koneksi internet, berjalan dalam mode luring';

  @override
  String get home_enterAmount => 'Masukkan Jumlah';

  @override
  String get home_addToCart => 'Tambah ke Keranjang';

  @override
  String get home_cancel => 'Batal';

  @override
  String get home_noProducts =>
      'Tidak ada produk, tambah produk untuk melanjutkan';

  @override
  String get home_addProduct => 'Tambah Produk';

  @override
  String get home_transaction => 'Transaksi';

  @override
  String get home_pay => 'Bayar';

  @override
  String get home_retail => 'Eceran';

  @override
  String get home_grosir => 'Grosir';

  @override
  String cart_products(Object count) {
    return '$count Produk';
  }

  @override
  String get cart_confirm => 'Konfirmasi';

  @override
  String get cart_removeAllConfirm => 'Yakin ingin menghapus semua produk?';

  @override
  String get cart_remove => 'Hapus';

  @override
  String get cart_removeAll => 'Hapus Semua';

  @override
  String get cart_empty => 'Kosong';

  @override
  String get cart_noProducts => 'Belum ada produk di keranjang';

  @override
  String cart_total(Object count) {
    return 'Total ($count)';
  }

  @override
  String get cart_back => 'Kembali';

  @override
  String get cart_receivedAmount => 'Jumlah Diterima';

  @override
  String get cart_receivedAmountHint => 'Jumlah yang diterima...';

  @override
  String get cart_paymentMethod => 'Metode Pembayaran';

  @override
  String get cart_bank => 'Bank';

  @override
  String get cart_cash => 'Tunai';

  @override
  String get cart_customerName => 'Nama Pelanggan (Opsional)';

  @override
  String get cart_customerNameHint => 'Misal: Budi Santoso';

  @override
  String get cart_description => 'Deskripsi (Opsional)';

  @override
  String get cart_descriptionHint => 'Deskripsi...';

  @override
  String cart_stock(Object count) {
    return 'Stok: $count';
  }

  @override
  String get cart_removeProductConfirm => 'Yakin ingin menghapus produk ini?';

  @override
  String get cart_paymentType => 'Tipe Pembayaran';

  @override
  String get cart_credit => 'Kredit';

  @override
  String get cart_dueDate => 'Jatuh Tempo';

  @override
  String get cart_dueDateHint => 'Pilih tanggal jatuh tempo...';

  @override
  String product_stockSold(Object stock, Object sold) {
    return 'Stok $stock | Terjual $sold';
  }

  @override
  String product_retailPrice(Object price) {
    return 'Eceran: $price';
  }

  @override
  String product_grosirPrice(Object price) {
    return 'Grosir: $price';
  }

  @override
  String get product_outOfStock => 'Stok habis';

  @override
  String get product_searchHint => 'Cari Produk...';

  @override
  String get product_noProducts =>
      'Tidak ada produk, tambah produk untuk melanjutkan';

  @override
  String get product_createTitle => 'Buat Produk';

  @override
  String get product_editTitle => 'Edit Produk';

  @override
  String get product_image => 'Gambar Produk';

  @override
  String get product_nameLabel => 'Nama';

  @override
  String get product_nameHint => 'Nama produk...';

  @override
  String get product_retailPriceLabel => 'Harga Eceran';

  @override
  String get product_retailPriceHint => 'Harga eceran...';

  @override
  String get product_wholesalePriceLabel => 'Harga Grosir (Opsional)';

  @override
  String get product_wholesalePriceHint => 'Harga grosir...';

  @override
  String get product_stockLabel => 'Stok';

  @override
  String get product_stockHint => 'Stok produk...';

  @override
  String get product_barcodeLabel => 'Barcode';

  @override
  String get product_barcodeHint => 'Scan atau ketik barcode...';

  @override
  String get product_barcode => 'Barcode';

  @override
  String get product_unitLabel => 'Satuan';

  @override
  String get product_descriptionLabel => 'Deskripsi';

  @override
  String get product_descriptionHint => 'Deskripsi produk...';

  @override
  String get product_addButton => 'Tambah Produk';

  @override
  String get product_updateButton => 'Perbarui Produk';

  @override
  String get product_deleteButton => 'Hapus';

  @override
  String get product_deleteConfirm => 'Yakin ingin menghapus produk ini?';

  @override
  String get product_deleted => 'Produk dihapus';

  @override
  String get product_created => 'Produk dibuat';

  @override
  String get product_updated => 'Produk diperbarui';

  @override
  String get product_detailTitle => 'Detail Produk';

  @override
  String get product_editProduct => 'Edit Produk';

  @override
  String get product_noName => '(Tanpa nama)';

  @override
  String product_addedAt(Object date) {
    return 'Ditambahkan pada $date';
  }

  @override
  String product_lastUpdated(Object date) {
    return 'Terakhir diperbarui pada $date';
  }

  @override
  String get product_price => 'Harga';

  @override
  String get product_stock => 'Stok';

  @override
  String get product_sold => 'Terjual';

  @override
  String get product_description => 'Deskripsi';

  @override
  String get product_noDescription => '(Tidak ada deskripsi)';

  @override
  String get product_notFound => 'Tidak Ditemukan';

  @override
  String get transaction_searchHint => 'Cari ID Transaksi...';

  @override
  String get transaction_noTransaction => 'Tidak ada transaksi';

  @override
  String get transaction_detailTitle => 'Detail Transaksi';

  @override
  String get transaction_reprint => 'Cetak Ulang';

  @override
  String get transaction_created => 'Transaksi Dibuat';

  @override
  String get transaction_id => 'ID Transaksi';

  @override
  String get transaction_paymentMethod => 'Metode Pembayaran';

  @override
  String get transaction_createdBy => 'Dibuat Oleh';

  @override
  String get transaction_createdAt => 'Dibuat Pada';

  @override
  String get transaction_customerName => 'Nama Pelanggan';

  @override
  String get transaction_description => 'Deskripsi';

  @override
  String get transaction_orderedProducts => 'Produk Dipesan';

  @override
  String get transaction_total => 'Total';

  @override
  String get transaction_paymentReceived => 'Pembayaran Diterima';

  @override
  String get transaction_change => 'Kembalian';

  @override
  String get transaction_notFound => 'Tidak Ditemukan';

  @override
  String get revenue_title => 'Laporan Pendapatan';

  @override
  String get revenue_totalRevenue => 'Total Pendapatan';

  @override
  String revenue_transactions(Object count) {
    return '$count Transaksi';
  }

  @override
  String revenue_products(Object count) {
    return '$count Produk';
  }

  @override
  String get revenue_noData => 'Belum ada data pendapatan';

  @override
  String transaction_products(Object count) {
    return '$count Produk';
  }

  @override
  String get storeSettings_title => 'Pengaturan Toko';

  @override
  String get storeSettings_storeNameLabel => 'Nama Toko';

  @override
  String get storeSettings_storeNameHint => 'Nama toko Anda...';

  @override
  String get storeSettings_storeAddressLabel => 'Alamat';

  @override
  String get storeSettings_storeAddressHint => 'Alamat toko Anda...';

  @override
  String get storeSettings_receiptFooterLabel => 'Pesan Struk';

  @override
  String get storeSettings_receiptFooterHint =>
      'Pesan di bagian bawah struk, misal: Terima kasih telah berbelanja';

  @override
  String get storeSettings_save => 'Simpan';

  @override
  String get storeSettings_saving => 'Menyimpan...';

  @override
  String get storeSettings_saved => 'Pengaturan toko tersimpan';

  @override
  String get settings_title => 'Pengaturan';

  @override
  String get settings_profile => 'Profil';

  @override
  String get settings_theme => 'Tema';

  @override
  String get settings_close => 'Tutup';

  @override
  String get settings_darkMode => 'Mode Gelap';

  @override
  String get settings_printerSettings => 'Pengaturan Printer';

  @override
  String get settings_about => 'Tentang';

  @override
  String get settings_language => 'Bahasa';

  @override
  String get settings_english => 'Inggris';

  @override
  String get settings_indonesian => 'Indonesia';

  @override
  String get settings_noName => '(Tanpa Nama)';

  @override
  String get settings_appUpdate => 'Pembaruan Aplikasi';

  @override
  String get settings_printBarcodeLabels => 'Cetak Barcode Barang';

  @override
  String get product_labelSearchHint => 'Cari nama / kode...';

  @override
  String get product_labelFilterAll => 'Semua';

  @override
  String get product_labelFilterWith => 'Ada barcode';

  @override
  String get product_labelFilterWithout => 'Tanpa barcode';

  @override
  String get product_labelGenerate => 'Generate';

  @override
  String get product_labelSave => 'Simpan';

  @override
  String get product_labelPrint => 'Cetak';

  @override
  String get product_labelCopies => 'Copy';

  @override
  String get product_labelSelectAll => 'Pilih semua';

  @override
  String get product_labelClear => 'Bersihkan';

  @override
  String get product_labelHasBarcode => 'Sudah ada';

  @override
  String get product_labelNoBarcode => 'Belum ada barcode';

  @override
  String product_labelNewCode(Object code) {
    return 'Baru: $code';
  }

  @override
  String get product_labelRegenerate => 'Generate ulang';

  @override
  String get product_labelEmptySelection =>
      'Pilih dulu produk yang mau diproses';

  @override
  String get product_labelEmptyGenerated =>
      'Belum ada kode generate. Pilih produk lalu tekan Generate.';

  @override
  String get product_labelEmptyPrintable =>
      'Tidak ada label valid untuk dicetak. Generate & simpan dulu.';

  @override
  String product_labelMissingBarcode(Object name) {
    return '$name: belum punya barcode';
  }

  @override
  String product_labelInvalidBarcode(Object name) {
    return '$name: barcode tidak valid (harus EAN-13)';
  }

  @override
  String product_labelSaved(Object count) {
    return '$count barcode tersimpan';
  }

  @override
  String get product_labelPrinted => 'Label terkirim ke printer';

  @override
  String product_labelSkipped(Object count) {
    return '$count produk dilewati (tanpa barcode valid)';
  }

  @override
  String get product_labelNeedPrinter =>
      'Printer belum terhubung. Hubungkan dulu di Pengaturan Printer.';

  @override
  String get product_labelGoPrinter => 'Ke Printer';

  @override
  String get product_labelNewProduct => 'Produk Baru';

  @override
  String get product_labelPreview => 'Preview Barcode';

  @override
  String get product_labelTapGenerate =>
      'Isi nama barang, lalu tekan Generate untuk buat kode batang.';

  @override
  String get product_labelSaveProduct => 'Simpan Produk';

  @override
  String get product_labelPrintLabel => 'Cetak Label';

  @override
  String get product_labelNewForm => 'Nama barang wajib diisi dulu.';

  @override
  String get product_labelInvalidCode =>
      'Barcode belum valid. Tekan Generate atau ketik 13 digit.';

  @override
  String get product_labelDuplicateName => 'Produk dengan nama ini sudah ada';

  @override
  String get product_labelDuplicateBarcode =>
      'Produk dengan barcode ini sudah ada';

  @override
  String get product_labelExistingTitle => 'Produk Tanpa Barcode';

  @override
  String get product_labelSavedOne => 'Produk tersimpan dengan barcode';

  @override
  String get dataProduct_title => 'Data Produk';

  @override
  String get dataProduct_export => 'Export Data';

  @override
  String get dataProduct_import => 'Import Data';

  @override
  String get dataProduct_exporting => 'Mengekspor...';

  @override
  String get dataProduct_importing => 'Mengimpor...';

  @override
  String dataProduct_exportSuccess(Object count) {
    return '$count produk berhasil diekspor';
  }

  @override
  String dataProduct_importSuccess(Object count) {
    return '$count produk berhasil diimpor';
  }

  @override
  String get dataProduct_exportFailed => 'Ekspor gagal';

  @override
  String get dataProduct_importFailed => 'Impor gagal';

  @override
  String get dataProduct_importTitle => 'Impor Produk';

  @override
  String get dataProduct_importConfirm =>
      'Ini akan menambahkan produk dari file backup. Lanjutkan?';

  @override
  String get dataProduct_cancel => 'Batal';

  @override
  String get dataProduct_confirm => 'Impor';

  @override
  String get dataProduct_noFile => 'Tidak ada file dipilih';

  @override
  String get dataProduct_invalidFile => 'File backup tidak valid';

  @override
  String get profile_editTitle => 'Edit Profil';

  @override
  String get profile_image => 'Gambar Profil';

  @override
  String get profile_nameLabel => 'Nama';

  @override
  String get profile_nameHint => 'Nama Anda...';

  @override
  String get profile_emailLabel => 'Email';

  @override
  String get profile_emailHint => 'Email Anda...';

  @override
  String get profile_phoneLabel => 'Nomor Telepon';

  @override
  String get profile_phoneHint => 'Nomor telepon Anda...';

  @override
  String get profile_update => 'Perbarui';

  @override
  String get profile_cropPhoto => 'Pangkas Foto';

  @override
  String get profile_updated => 'Profil diperbarui';

  @override
  String get printer_title => 'Pengaturan Printer';

  @override
  String get printer_paperSize => 'Ukuran Kertas';

  @override
  String get printer_connectionTypes => 'Tipe Koneksi';

  @override
  String get printer_selectConnection => 'Pilih tipe koneksi';

  @override
  String get printer_usb => 'USB';

  @override
  String get printer_bluetooth => 'Bluetooth';

  @override
  String get printer_ble => 'BLE';

  @override
  String get printer_network => 'Jaringan';

  @override
  String get printer_allConnections => 'Semua tipe koneksi';

  @override
  String get printer_availableDevices => 'Perangkat Tersedia';

  @override
  String get printer_scanning => 'Memindai printer...';

  @override
  String get printer_noDevice => '(Tidak ada printer terdeteksi)';

  @override
  String printer_connected(Object name) {
    return 'Terhubung ke $name';
  }

  @override
  String get printer_notConnected =>
      'Tidak terhubung. Pilih printer untuk menghubungkan.';

  @override
  String printer_connectingTo(Object name) {
    return 'Menghubungkan ke $name...';
  }

  @override
  String get printer_connectedBadge => 'Terhubung';

  @override
  String get printer_connectingBadge => 'Menghubungkan...';

  @override
  String get printer_disconnecting => 'Memutuskan koneksi...';

  @override
  String get about_title => 'Tentang';

  @override
  String get about_appName => 'Mono POS';

  @override
  String about_version(Object version) {
    return 'versi $version';
  }

  @override
  String get about_description =>
      'Mono POS adalah aplikasi Point of Sale (POS) berbasis Flutter untuk mengelola produk, transaksi penjualan, pelanggan, dan karyawan. Mendukung pembayaran QRIS (Klik QRIS) dan laporan pendapatan, menyimpan data secara lokal dengan SQLite, serta dapat disinkronkan ke server REST API.';

  @override
  String get about_developedBy => 'Dikembangkan dengan ❤️ oleh';

  @override
  String get about_developerName => 'Fakhri Aditia Rahman';

  @override
  String get about_github => 'GitHub';

  @override
  String get about_website => 'Situs Web';

  @override
  String get update_title => 'Pembaruan Aplikasi';

  @override
  String get update_currentVersion => 'Versi terpasang';

  @override
  String get update_latestVersion => 'Versi terbaru';

  @override
  String get update_check => 'Periksa Pembaruan';

  @override
  String get update_checking => 'Memeriksa...';

  @override
  String get update_downloadInstall => 'Download & Install';

  @override
  String update_downloading(Object percent) {
    return 'Mengunduh... $percent%';
  }

  @override
  String get update_installing => 'Membuka installer...';

  @override
  String get update_upToDate => 'Aplikasi sudah versi terbaru';

  @override
  String get update_available => 'Versi baru tersedia';

  @override
  String update_changelogTitle(Object version) {
    return 'Yang baru di $version';
  }

  @override
  String get update_noChangelog => 'Tidak ada catatan rilis.';

  @override
  String get update_noApk => 'Release ini tidak menyertakan file APK.';

  @override
  String update_releaseDate(Object date) {
    return 'Dirilis $date';
  }

  @override
  String get update_retry => 'Coba Lagi';

  @override
  String get update_androidOnly =>
      'Instalasi otomatis hanya tersedia di Android.';

  @override
  String get error_backToHome => 'Kembali ke beranda';

  @override
  String get shared_oops => 'Oops!';

  @override
  String get shared_somethingWrong =>
      'Terjadi kesalahan, silakan hubungi pengembang.';

  @override
  String get shared_close => 'Tutup';

  @override
  String get shared_nothingToShow => 'Tidak ada yang ditampilkan';

  @override
  String get shared_somethingWrongRetry =>
      'Terjadi kesalahan.\nSilakan coba lagi nanti.';

  @override
  String get lowStock_title => 'Peringatan Stok Menipis';

  @override
  String lowStock_message(Object count) {
    return '$count produk stok menipis';
  }

  @override
  String lowStock_item(Object name, Object stock) {
    return '$name — sisa $stock';
  }

  @override
  String get lowStock_ok => 'OK';

  @override
  String get receipt_date => 'Tanggal';

  @override
  String get receipt_trxId => 'ID Transaksi';

  @override
  String get receipt_customer => 'Pelanggan';

  @override
  String get receipt_cashier => 'Kasir';

  @override
  String get receipt_item => 'Barang';

  @override
  String get receipt_qty => 'Jml';

  @override
  String get receipt_price => 'Harga';

  @override
  String get receipt_subtotal => 'Subtotal';

  @override
  String get receipt_total => 'Total';

  @override
  String get receipt_pay => 'Bayar';

  @override
  String get receipt_change => 'Kembali';

  @override
  String get receipt_paymentMethod => 'Pembayaran';

  @override
  String get receipt_grosir => 'Grosir';

  @override
  String get receipt_retail => 'Eceran';

  @override
  String get receipt_testTitle => 'MONO POS TEST PRINT OK';

  @override
  String get receipt_testTopLeft => 'kiri atas';

  @override
  String get receipt_testTopRight => 'kanan atas';

  @override
  String get receipt_testBottomLeft => 'kiri bawah';

  @override
  String get receipt_testBottomRight => 'kanan bawah';

  @override
  String get receipt_testThanks => 'Terima Kasih';

  @override
  String get receipt_storeName => 'TOKO ANDA';

  @override
  String get receipt_merchant => 'Merchant';

  @override
  String get receipt_qrisTotal => 'Total Pembayaran';

  @override
  String get receipt_qrisScan => 'Scan QRIS untuk membayar';

  @override
  String get receipt_qrisNote => '* Pembayaran akan terdeteksi otomatis *';
}
