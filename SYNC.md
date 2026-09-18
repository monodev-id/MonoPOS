# Sinkronisasi Data (Online/Offline Mode)

> Last synced with code: v1.2.6. Supabase credentials via **Account → Supabase Sync**
> (runtime, `SupabaseCredentials` in SharedPreferences) — restart applies. No rebuild needed.

## Arsitektur

```
┌─────────────────────────────────────────────────────────────┐
│                        User Interface                        │
│   _NetworkInfo (toggle)    _SyncButton (status indicator)    │
└──────────────────────────┬──────────────────────────────────┘
                           │ tap
┌──────────────────────────▼──────────────────────────────────┐
│                      MainNotifier                            │
│  - toggleSyncMode() → SyncService.toggleMode()               │
│  - _processQueuedActions() → ProcessQueuedActionUsecase      │
│  - _onConnectionChanged() → trigger queue processing         │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                       SyncService                            │
│  - isOnline: bool (PingService + forced offline)             │
│  - mode: SyncMode (auto / online / offline)                  │
│  - toggleMode(): cycle auto → offline → online → auto        │
│  - ChangeNotifier (UI rebuild on mode change)                │
└─────────────┬─────────────────────────────┬──────────────────┘
              │                             │
     ┌────────▼────────┐          ┌─────────▼─────────┐
     │  PingService     │          │  Repository Layer  │
     │  (detect internet)│          │  _syncRemote()      │
     └─────────────────┘          │  - cek isOnline     │
                                   │  - queue if offline │
                                   └─────────┬──────────┘
                                             │
                          ┌──────────────────▼──────────────────┐
                          │         QueuedActionRepository       │
                          │  (SQLite: menunggu sinkronisasi)     │
                          └──────────────────┬──────────────────┘
                                             │ saat online
                          ┌──────────────────▼──────────────────┐
                          │    ProcessQueuedActionUsecase        │
                          │  dispatch ke remote datasource by    │
                          │  repository + method dari queue      │
                          └─────────────────────────────────────┘
```

## Mode Sinkronisasi

Ada 3 mode yang bisa dipilih user via ikon WiFi di pojok kanan atas beranda:

| Mode | Ikon | Warna | Perilaku |
|------|------|-------|----------|
| **Auto** (default) | WiFi | Primary (hijau) jika ada internet, abu-abu jika offline | Otomatis: sync jika ada koneksi, queue jika offline |
| **Offline** | WiFi-off | Merah | Paksa offline: semua write hanya ke SQLite, di-queue |
| **Online** | WiFi | Hijau | Paksa online: semua write ke SQLite + langsung sync ke Supabase |

**Cara toggle:** Tap ikon WiFi di AppBar beranda → mode berputar: Auto → Offline → Online → Auto

## Alur Write Data

### Saat Online (Auto mode + ada internet / Online mode)
```
User tambah data
  → Repository.writeLocal() ✅ (SQLite)
  → SyncService.isOnline == true
  → Repository.writeRemote() ✅ (Supabase)
  → Selesai
```

### Saat Offline (Auto mode + tidak ada internet / Offline mode)
```
User tambah data
  → Repository.writeLocal() ✅ (SQLite)
  → SyncService.isOnline == false
  → QueuedActionRepository.create() ✅ (simpan ke antrian)
  → Selesai
```

### Saat Remote Gagal (Online mode tapi Supabase error)
```
User tambah data
  → Repository.writeLocal() ✅ (SQLite)
  → SyncService.isOnline == true → coba remote
  → Remote gagal (error)
  → QueuedActionRepository.create() ✅ (simpan ke antrian)
  → Selesai
```

## Alur Sinkronisasi Ulang

Saat pindah dari offline → online (baik manual toggle atau koneksi pulih):

```
SyncService.isOnline berubah jadi true
  → _onSyncModeChanged() atau _onConnectionChanged()
  → MainNotifier._processQueuedActions()
  → Ambil semua QueuedAction dari SQLite (urut: critical ASC, createdAt ASC)
  → Untuk setiap action:
      → ProcessQueuedActionUsecase.execute():
        → Parse JSON param
        → Dispatch berdasarkan repository + method:
          - "user/createUser"   → UserRemoteDatasource.createUser()
          - "user/updateUser"   → UserRemoteDatasource.updateUser()
          - "user/deleteUser"   → UserRemoteDatasource.deleteUser()
          - "product/createProduct" → ProductRemoteDatasource.createProduct()
          - "product/updateProduct" → ProductRemoteDatasource.updateProduct()
          - "product/deleteProduct" → ProductRemoteDatasource.deleteProduct()
          - "transaction/..." → TransactionRemoteDatasource.*()
        → Jika sukses: delete dari queue
        → Jika gagal: biarkan di queue (akan dicoba lagi nanti)
  → Refresh status (isHasQueuedActions, isSyncronizing)
```

## Komponen UI

### `_NetworkInfo` (home_screen.dart ~L484)
- **Lokasi:** AppBar sebelah kanan
- **Fungsi:** Toggle mode sinkronisasi (tap untuk ganti mode)
- **State:** `mainNotifierProvider.select((p) => p.syncMode)` + `isHasInternet`

### `_SyncButton` (home_screen.dart ~L429)
- **Lokasi:** AppBar, di kiri `_NetworkInfo`
- **Fungsi:** Indikator status sinkronisasi
  - `Sync...` — sedang sinkronisasi
  - `Pending` — ada data yang belum tersinkronisasi
  - `Synced` — semua data sudah tersinkronisasi
- **Tap:** Refresh data (panggil `getUserData()`)
- **State:** `mainNotifierProvider.select((p) => p.isSyncronizing)` + `isHasQueuedActions`

## Struktur QueuedAction

Disimpan di tabel SQLite `QueuedAction`:

| Field | Tipe | Contoh |
|-------|------|--------|
| `id` | INTEGER | auto-increment |
| `repository` | TEXT | `"product"`, `"user"`, `"transaction"` |
| `method` | TEXT | `"createProduct"`, `"deleteUser"`, dll |
| `param` | TEXT (JSON) | `{"id":1,"name":"Teh Botol",...}` |
| `isCritical` | INTEGER (0/1) | prioritas tinggi |
| `createdAt` | DATETIME | urutan antrian |

## File yang Dimodifikasi

| File | Perubahan |
|------|-----------|
| `lib/core/services/sync/sync_service.dart` | Tambah enum `SyncMode`, forced offline, `ChangeNotifier`, `toggleMode()` |
| `lib/data/repositories/user_repository_impl.dart` | Tambah `SyncService` + `QueuedActionRepository`, `_syncRemote` jadi async + queue |
| `lib/data/repositories/product_repository_impl.dart` | Sama |
| `lib/data/repositories/transaction_repository_impl.dart` | Sama |
| `lib/domain/usecases/queued_action_usecases.dart` | `ProcessQueuedActionUsecase` sekarang dispatch remote call beneran |
| `lib/presentation/providers/main/main_notifier.dart` | Tambah `toggleSyncMode()`, `_listenSyncMode()`, update `_processQueuedActions()` |
| `lib/presentation/providers/main/main_state.dart` | Tambah field `syncMode` |
| `lib/presentation/screens/home/home_screen.dart` | `_NetworkInfo` jadi toggle, `_SyncButton` label diperbaiki |
| `lib/app/di/app_providers.dart` | Tambah `syncServiceProvider`, inject ke repos |

## Catatan

- **Auto-register user:** Saat login, jika user belum ada di Supabase Auth, otomatis di-register (di `AuthRemoteDataSourceImpl`)
- **Auto-confirm:** Email otomatis terkonfirmasi (setting `mailer_autoconfirm: true` di Supabase)
- **Upsert:** `UserRemoteDatasourceImpl` pakai `upsert` bukan `insert` biar idempotent
- **Duplicate-key guard:** Replay antrian offline menahan error `23505`/`21000` agar tidak duplikat (fix `03a29ce`)
- **Supabase Sync menu:** Hanya tampil untuk role **admin** (kasir disembunyikan)
- **Tanpa Supabase:** App full offline; semua write ke SQLite + queue; indikator `Pending` sampai kredensial diisi
- **KlikQRIS webhook:** `cloudflare/klikqris-notify` mempercepat `paymentStatus → paid` di Supabase; device melihat perubahan saat sync berikutnya (polling tetap sebagai fallback)
