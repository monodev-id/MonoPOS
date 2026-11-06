# Plan: Ubah format cetak struk jadi "qty x nama produk : nama satuan"

## Goal
Ubah baris item pada struk cetak dari format saat ini (`harga x qty satuan` + nama produk terpisah) menjadi satu baris: `qty x nama produk : nama satuan`, sambil tetap menjamin `conversionValue` tidak dicetak.

## File yang diubah
- `lib/core/services/printer/printer_service.dart` — method `printTransaction`

## Perubahan teknis

### 1. grosirItems loop (baris ~274–289)
- Hapus `ticket.text(product.name);` — nama produk sudah ada di baris baru, tidak perlu dicetak dua kali.
- Hapus variabel `unitPrice` (tidak lagi dipakai setelah format diubah).
- Ubah teks `PrintColumn` pertama dari:
  ```
  '$unitPrice x ${_formatReceiptQuantity(product.quantity, product.unit)}'
  ```
  menjadi:
  ```
  '$qty x ${product.name} : ${product.unit}'
  ```
  dengan `qty` diformat: `product.quantity.toInt().toString()` jika bilangan bulat, else `product.quantity.toStringAsFixed(1)`.
- Subtotal tetap di kolom kanan.

### 2. retailItems loop (baris ~301–317)
- Sama seperti perubahan 1.

### Contoh output baru
```
2 x Beras : pcs          10000
```
(kiri: qty x nama produk : satuan; kanan: subtotal)

## Contoh cetak struk lengkap (ASCII)

Sebelum:
```
──────────────────────────────────────
           NAMA TOKO
       Alamat Toko, Kota

Tanggal : 26/10/2026 14:30
ID Trx  : #1729920000
Pelanggan : Umum
Kasir   : Admin
──────────────────────────────────────
Beras
5000 x 2 pcs          10000
──────────────────────────────────────
Total             10000

Bayar (Cash)      10000
Kembali           0

Terima kasih telah berbelanja
──────────────────────────────────────
```

Sesudah:
```
──────────────────────────────────────
           NAMA TOKO
       Alamat Toko, Kota

Tanggal : 26/10/2026 14:30
ID Trx  : #1729920000
Pelanggan : Umum
Kasir   : Admin
──────────────────────────────────────
2 x Beras : pcs          10000
──────────────────────────────────────
Total             10000

Bayar (Cash)      10000
Kembali           0

Terima kasih telah berbelanja
──────────────────────────────────────
```

Note: `conversionValue` tidak muncul di mana pun dalam teks struk (sebelum maupun sesudah). Angka di depannya adalah quantity, bukan konversi.

## Tidak berubah
- `conversionValue` tetap tidak ada di teks struk (tidak ada referensi di `printer_service.dart`).
- Header struk (nama toko, alamat, tanggal, ID transaksi, pelanggan, kasir) tidak berubah.
- Subtotal, total, pembayaran, kembalian, footer tidak berubah.
- `conversionValue` tetap dipakai internal: potongan stok, HPP, UI keranjang, detail pembelian.

## Validasi
- `dart analyze lib/core/services/printer/printer_service.dart` — tidak ada error/lint baru (khususnya unused variable `unitPrice`).
- `flutter test` existing suite — tidak ada regresi.
- Konfirmasi visual: baris item cetak `qty x nama produk : nama satuan`, tidak ada angka konversi.

## Pertanyaan terbuka (disetujui)
- Unit price tidak lagi ditampilkan per baris item (subtotal tetap ada). Disetujui oleh user berdasarkan permintaan format `qty x nama produk : nama satuan`.
