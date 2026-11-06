# AGENTS.md — MonoPOS

Flutter POS app (offline-first). SQLite (`sqflite`, `app_database.db`) is source of truth; Supabase Postgres is synced mirror. Current version lives in `pubspec.yaml` — keep `README.md`/`CLAUDE.md`/reference docs in sync when it or architecture changes.

## Commands

```bash
flutter pub get
flutter run                                            # app runs fully offline without Supabase
flutter run --dart-define-from-file config.json        # pre-baked backend (see config.example.json)
flutter test test/path/to_file_test.dart               # single test — always prefer this first
flutter test --coverage                                # full suite
dart format lib/ test/ --line-length=120               # required after every .dart edit
flutter analyze                                        # ONLY for large changes (slow); skip for few files, rely on IDE + dart format
flutter gen-l10n                                       # after editing ARB files
dart run build_runner build --delete-conflicting-outputs  # codegen (json_serializable/mockito)
```

No CI/CD, no pre-commit hooks. Formatting is developer discipline.

## Env / Supabase config (precedence matters)

1. Runtime: **Account → Supabase Sync** (URL + anon key in `SharedPreferences`, restart applies). Wins over everything; one binary serves many stores.
2. Build-time: `--dart-define` / `--dart-define-from-file config.json` (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`/`SUPABASE_ANON_KEY`, `GOOGLE_SERVER_CLIENT_ID`).
3. Unconfigured → full offline, sync button shows `Sync off`.

Never commit `.env`/`config.json`/credentials. Service-role key lives only in Cloudflare Workers, never in the app.

## Architecture (Clean, 5 layers)

`lib/app` (DI in `app/di/app_providers.dart`, routes in `app/routes`) → `lib/core` (services: `database/`, `sync/`, `supabase/`, `payment/`, `printer/`, `tts/`, `update/`) → `lib/data` (datasources `interfaces/` shared by `local/`+`remote/`, `models/`, `repositories/`) → `lib/domain` (entities, repo interfaces, grouped `*_usecases.dart`) → `lib/presentation` (`providers/`, `screens/`, `widgets/app_*.dart`).

- UI never touches repositories/datasources — always via a Notifier. Every data-loading screen has its own notifier+state.
- Notifiers instantiate usecases on-demand: `await GetUserUsecase(repo).call(params)`. Group one class per operation in `*_usecases.dart` extending `Usecase<Result, Params>`; use `NoParam` for parameterless. Class suffix is `Usecase`, not `UseCase`.
- Riverpod: `NotifierProvider` global, `AutoDisposeNotifier` for ephemeral (forms/dialogs). State in separate `*_state.dart`. Screens are `ConsumerWidget`/`ConsumerStatefulWidget`. Cache `ref.read(p)` in a local var; never inline repeated `ref.read` in args.
- Routing: GoRouter + `ShellRoute`, auth-aware redirects. `context.push/go/pop`.
- Follow the existing module before writing new code — replicate its structure/verbs (`loadX` vs `fetchX`) exactly. Never take the "simplest" shortcut that breaks the layer flow.

## Sync / offline-first (see `SYNC.md`)

- Repositories: `writeLocal()` → if `SyncService.isOnline` then `writeRemote()` else queue in `QueuedAction` SQLite table. Replay ordered by `isCritical ASC, createdAt ASC`; duplicate-key `23505` is swallowed.
- `SyncService` modes cycle via WiFi icon: `auto → offline → online → auto`.
- **Local-only, never synced** (stripped in remote datasource before upsert): `Supplier`, `Purchase`/`PurchaseItem`, `Product.costPrice` (HPP), DANA payment metadata (`paymentProvider`, `paymentExpectedAmount`, `paymentUniqueCode`, `paymentExpiresAt`, `paymentPaidAt`) + `PaymentNotification` table. Supplier/purchase repos use no `SyncService`/queue.
- `OrderedProduct.units` is a runtime cart snapshot — never persisted.

## Database (see `DATABASE.md`)

- Source of truth: `lib/core/services/database/database_config.dart` (currently **version 4**). Migrations are idempotent `ALTER TABLE`/`CREATE TABLE IF NOT EXISTS` run on every startup.
- Debug first-install seeds 150 demo products + local users (`admin`/`kasir1`/`kasir2`). Unique indexes: `Product(name)`, `Supplier(name COLLATE NOCASE)`.

## Payments — DANA Bisnis QRIS only

Static merchant QRIS string (in `SharedPreferences`) → dynamic payload at checkout (`convertQris`, EMVCo TLV + CRC16). Only the payload string persists in `Transaction.paymentQR`; uploaded images are decoded on-device (MLKit, zxing2 fallback) then deleted; dynamic uploads are normalized to static before save. Confirmation via native `NotificationListenerService` (`id.dana`, `id.dana.kasir`) matched by `paymentExpectedAmount`; `Tandai Lunas`/expiry-countdown are fallbacks. Doku SNAP and KlikQRIS are **retired** — `DOKU_PAYMENT_GATEWAY.md`, `cloudflare/*-notify/`, and KlikQRIS services are reference-only; do not build on them.

## Conventions that differ from defaults

- Line length **120**, trailing commas preserved, `flutter_lints`. Excluded: `*.g.dart`, `*.mocks.dart`, `*.freezed.dart`.
- Imports order: `dart:*` → `package:flutter/*` → third-party alphabetical → relative local.
- No decorative/separator comments; blank line between `if`/`return`/`for`/functions/logical groups, but none between `child`/`children` widgets. Never `Widget _foo()` builders — use `_FooWidget` classes. No `setState` except tiny leaf widgets. Spacing via `AppSizes`, never hardcoded numbers.
- Errors via `Result<T>` (Success/Failure), not exceptions. Entities/states use `Equatable`.
- Shared dialogs: static class + static `show()`. Utility services: static class + private constructor.
- Form screens: track initial values, `_hasChanges`, `PopScope` confirm-discard. Detail screens: load by ID via notifier, reload after edit/delete. List screens: scroll pagination (`NotificationListener<ScrollNotification>` + `loadMore()`) + `onSearchChanged()`.
- i18n: edit `lib/l10n/app_en.arb` / `app_id.arb`, run `flutter gen-l10n`. Never hand-edit `lib/generated/`.
- File/class names per `CLAUDE.md` table (`*_screen.dart`, `*_notifier.dart`, `product_local_datasource_impl.dart`, `app_*.dart` shared vs `components/` scoped, `Usecase` suffix).

## Testing

`mockito` + `sqflite_common_ffi` with per-suite `initTestDatabase()` isolation. Mirror `lib/` layout under `test/` (`data/`, `domain/`, `presentation/providers/`, `core/services/`). Fixture image: `test/fixtures/qrisduaputri.jpeg`.

## Git (see `WORKFLOW.md`)

Conventional commits, description in **Bahasa Indonesia**: `feat: ...`, `fix: ...`, `refactor:`, `chore:`, `docs:`, `test:`, `style:` (e.g. `feat(qris): tambah transaksi QRIS langsung dari nominal`). Branches `<type>/<kebab-desc>` (`feature/`, `fix/`, `refactor/`, `chore/`). Merge via merge commit; direct-to-`main` OK only for small/urgent fixes. When architecture/schema/routes/flows change, update the matching Markdown docs (`README`, `CLAUDE`, `UI`, `DATABASE`, `SYNC`, `WORKFLOW_SYSTEM`) in the same PR.

## Reference docs (trust code over prose on conflict)

- `CLAUDE.md` — full conventions; `UI.md` — layouts/components; `DATABASE.md` — schema; `SYNC.md` — sync/queue; `WORKFLOW_SYSTEM.md` — end-to-end flows + route map; `WORKFLOW.md` — git; `DOKU_PAYMENT_GATEWAY.md` — retired archive.
