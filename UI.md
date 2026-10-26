# UI.md - UI Reference

> Last synced with code: v1.3.7 (Oct 2026). Covers direct QRIS, cart/unit snapshot, barcode label
> printing, KlikQRIS payment screen, product-data/app-update screens, printer status banner,
> supplier/purchase screens, and revenue day detail.

## Reusable Widgets (`lib/presentation/widgets/`)

| Widget                     | Purpose                                      | Key Props                                                                 |
| -------------------------- | -------------------------------------------- | ------------------------------------------------------------------------- |
| `AppButton`                | Primary action button                        | text, onTap, buttonColor, textColor, borderColor, enabled, child          |
| `AppIconButton`            | Circular icon button                         | icon, onTap, iconSize, enabled, padding                                   |
| `AppTextField`             | Text input with variants                     | controller, hintText, labelText, type (general/search/currency), onChanged |
| `AppDropDown`              | Single or multi-select dropdown              | selectedValue, dropdownItems, onChanged, labelText                        |
| `AppDialog`                | Modal dialog (static: show, showError, showProgress) | title, text, child, leftButtonText, rightButtonText, dismissible  |
| `AppSnackBar`              | Snackbar (static: show, showError)           | message, context                                                          |
| `AppProgressIndicator`     | Centered loading spinner                     | message, showMessage                                                      |
| `AppLoadingMoreIndicator`  | Animated loading indicator for infinite scroll | isLoading, padding                                                       |
| `AppEmptyState`            | Empty state placeholder                      | title, subtitle, buttonText, onTapButton                                  |
| `AppErrorWidget`           | Error display (full or text-only)            | error, message, textOnly                                                  |
| `AppSuccessOverlay`        | Full-screen success check overlay            | message (static `show`)                                                   |
| `AppPriceTypeToggle`       | Retail/grosir segmented toggle               | selectedType, onChanged                                                   |
| `AppLowStockDialog`        | Low-stock confirm dialog (static: show)      | productName, stock, requestedQty                                          |

## Screen Structure

Screens follow a consistent pattern:

- `ConsumerWidget` or `ConsumerStatefulWidget` for Riverpod access
- `Scaffold` with custom `AppBar`
- `RefreshIndicator` for pull-to-refresh
- `CustomScrollView` with `SliverGrid` for list/grid layouts
- Infinite scroll via `ScrollController` listener
- Empty/loading/error states handled inline

### Grid Layout

```dart
SliverGrid(
  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200,
    childAspectRatio: 1 / 1.5,
    crossAxisSpacing: AppSizes.padding / 2,
    mainAxisSpacing: AppSizes.padding / 2,
  ),
)
```

## Screen Components

Each screen can have a `components/` subfolder for private sub-widgets specific to that screen.

```
screens/
└── home/
    ├── home_screen.dart
    ├── barcode_scanner_screen.dart     # camera scanner (mobile_scanner)
    └── components/
        ├── cart_panel_header.dart
        ├── cart_panel_body.dart
        ├── cart_panel_footer.dart      # checkout sheet: quick amounts, pay button
        ├── order_card.dart             # cart line item (tiered price aware)
        └── barcode_hid_listener.dart   # HID hardware-scanner listener
```

Other screen-scoped components: `products/components/` (product cards, tiered-price editor,
purchase info), `transactions/components/`, `revenue/components/` (summary card, payment stat,
day transaction tile), `purchases/components/` (purchase card, item editor, product picker sheet),
`suppliers/` (list + form screens).

## Key Screens (implemented)

| Route | Screen | Notes |
| ----- | ------ | ----- |
| `/payment/direct` | `DirectQrisScreen` | Amount-first QRIS (no cart), quick amounts, optional description/customer, config guard + sandbox badge; entry points in Home/Transactions app bars |
| `/payment/qris` | `KlikQrisPaymentScreen` | QR display (base64/url), total + unique-code breakdown, expiry countdown, auto-poll 3× @15s + always-available manual check (with failure/pending feedback), expired view with retry/close, cancel-confirm `PopScope`, TTS on paid |
| `/account/barcode-labels` | `ProductBarcodeLabelScreen` | Admin-only: generate/save EAN-13 for products without barcodes, search/filter, select-all, per-product copies, batch print labels (requires connected printer) |
| `/account/product-data` | `ProductDataScreen` | JSON export/import with per-product breakdown + progress |
| `/account/app-update` | `AppUpdateScreen` | GitHub release check, Markdown changelog, download progress, install (admin only) |
| `/account/payment-settings` | `PaymentSettingsScreen` | KlikQRIS API key / merchant ID / sandbox toggle / TTS toggle, Save button |
| `/account/printer-settings` | `PrinterSettingsScreen` | Scan/connect, paper size, test print, live status banner + badge, saved-printer reconnect |
| `/account/store-settings` | `StoreSettingsScreen` | Store name/address/receipt footer, Save button with caret fix |
| `/home` | `HomeScreen` | POS grid with auto-fill pagination, cart panel, direct QRIS + scan buttons, `_NetworkInfo` sync-mode toggle + `_SyncButton` status |
| `/account/suppliers` | `SupplierScreen` | Supplier/grosir list + search, create/edit form (admin only) |
| `/account/purchases` | `PurchaseScreen` | Purchase history, search, long-press delete (admin only) |
| `/account/purchases/create` | `PurchaseFormScreen` | Supplier, date, stock toggle, multi-item entry, last-price hints, quick-add supplier (admin only) |
| `/account/purchases/detail/:id` | `PurchaseDetailScreen` | Header totals, item list with HPP, delete + "catat lagi" (admin only) |
| `/account/revenue/day/:date` | `RevenueDayScreen` | Day summary (cash/QRIS/other + product count) and transaction list for that day (admin only) |

## Sizing & Spacing (`AppSizes`)

| Constant       | Value | Usage                          |
| -------------- | ----- | ------------------------------ |
| `padding`      | 18    | Standard padding/margin        |
| `margin`       | 18    | Standard margin                |
| `radius`       | 8     | Border radius                  |
| `padding / 2`  | 9     | Tight spacing                  |
| `padding / 4`  | 4.5   | Minimal spacing                |
| `padding * 2`  | 36    | Large spacing                  |

Responsive helpers: `screenWidth(context)`, `screenHeight(context)`, `viewPadding(context)`, `appBarHeight()`

## Color Usage

Always reference colors via `Theme.of(context).colorScheme`:

```dart
colorScheme.primary
colorScheme.surface
colorScheme.surfaceContainer
colorScheme.surfaceContainerLowest
colorScheme.onSurface
colorScheme.onSurfaceVariant
colorScheme.outline
colorScheme.error
colorScheme.tertiary
colorScheme.secondary
```

Text styles via `Theme.of(context).textTheme`: `bodySmall`, `bodyMedium`, `bodyLarge`, `labelSmall`, `labelLarge`, `titleMedium`, `titleLarge`.

## UI Patterns

- **Disabled state**: 0.5 opacity on buttons/cards
- **Out-of-stock overlay**: Semi-transparent white layer with badge
- **Dialogs/Snackbars**: Use `AppRoutes.rootNavigatorKey` for global context access
- **Feedback**: errors → `AppSnackBar.showError` or `AppDialog.showError` (blocking); success after save/delete/export/import → `AppSuccessOverlay.show()`; repeated/transient feedback (barcode scan, add to cart, printer/sync status) → `AppSnackBar.show` or an inline indicator, never the success overlay
- **Currency**: Display via `CurrencyFormatter.withoutSymbol(...)` (no `Rp` prefix, no decimals); inputs use thousand-separator formatter
- **Checkout sheet**: Quick amount buttons (`Uang Pas`, 50rb, 100rb) + custom amount field; Pay button label shows item count + total
- **Cart unit snapshot**: Each cart line carries the product's unit snapshot (`OrderedProductEntity.units`) so the unit dropdown still works when the paginated product cache does not contain that product; legacy products get a synthetic base unit
- **Barcode scan**: Camera scan and HID/search submissions use `GetProductByBarcodeUsecase` (SQLite first), then add +1 base unit straight to the cart without an intermediate dialog; focus returns to the hidden HID listener for the next scan
- **Barcode labels**: Admin screen generates unique EAN-13 codes, saves them via the product repository, and prints label batches (per-product copies) using the connection status from `PrinterManager`
- **Direct QRIS**: Amount-only payment from the Home/Transactions app bar; records a `qris` transaction at the entered amount (unique code from KlikQRIS is display-only), blocked with an admin shortcut when KlikQRIS is not configured
- **Tiered pricing**: Add-to-cart dialog shows live price per qty break; cart line shows tier badge
- **Printer status**: Banner in printer settings + badge on printer menu; state synced from `PrinterManager` (not cached prefs); saved printer reconnects on app start/resume
- **Revenue detail**: Summary card shows total, transaction/product counts, and cash/QRIS/other breakdowns; tapping a day opens the per-day transaction list
- **Adaptive layout**: `AppSizes.isTablet/isDesktop` → centered `maxWidth: 600` columns, nav rail on wide screens; dialogs use constrained width to avoid overflow
- **Animations**: `AnimatedContainer`, `AnimatedSwitcher` for state transitions
- **Performance**: `RepaintBoundary` on repeated list/grid items
- **Pagination**: `hasMore` + auto-fill — if first page doesn't fill viewport, next page loads automatically (home + products)
- **Purchase entry**: supplier dropdown + inline quick-add, date picker, "tambah stok otomatis" switch, product picker
  bottom sheet, per-item unit/qty/price with subtotal; the last price from the selected supplier (or another
  supplier as fallback) is shown and auto-filled, and HPP is updated from the latest purchase
- **Product purchase info**: admin-only section on product detail showing HPP, estimated profit, last purchase,
  latest price per supplier, and recent purchase history
