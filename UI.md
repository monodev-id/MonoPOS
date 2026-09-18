# UI.md - UI Reference

> Last synced with code: v1.2.6 (Sep 2026). Covers KlikQRIS payment screen, product-data/app-update
> screens, printer status banner, and new shared widgets.

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

Other screen-scoped components: `products/components/` (product cards, tiered-price editor),
`transactions/components/`, `revenue/components/`.

## Key Screens (implemented)

| Route | Screen | Notes |
| ----- | ------ | ----- |
| `/payment/qris` | `KlikQrisPaymentScreen` | QR display, expiry countdown, auto-poll 3× @15s + manual check, cancel-confirm `PopScope`, TTS section hidden in prod |
| `/account/product-data` | `ProductDataScreen` | JSON export/import with per-product breakdown + progress |
| `/account/app-update` | `AppUpdateScreen` | GitHub release check, Markdown changelog, download progress, install (admin only) |
| `/account/payment-settings` | `PaymentSettingsScreen` | KlikQRIS API key / merchant ID / sandbox toggle / TTS toggle, Save button |
| `/account/printer-settings` | `PrinterSettingsScreen` | Scan/connect, paper size, test print, live status banner + badge |
| `/account/store-settings` | `StoreSettingsScreen` | Store name/address/receipt footer, Save button with caret fix |
| `/home` | `HomeScreen` | POS grid with auto-fill pagination, `_NetworkInfo` sync-mode toggle + `_SyncButton` status |

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
- **Success feedback**: `AppSuccessOverlay.show()` after save/export/import (not just snackbar)
- **Currency**: Display via `CurrencyFormatter.withoutSymbol(...)` (no `Rp` prefix, no decimals); inputs use thousand-separator formatter
- **Checkout sheet**: Quick amount buttons (`Uang Pas`, 50rb, 100rb) + custom amount field; Pay button label shows item count + total
- **Tiered pricing**: Add-to-cart dialog shows live price per qty break; cart line shows tier badge
- **Printer status**: Banner in printer settings + badge on printer menu; state synced from `PrinterManager` (not cached prefs)
- **Adaptive layout**: `AppSizes.isTablet/isDesktop` → centered `maxWidth: 600` columns, nav rail on wide screens; dialogs use constrained width to avoid overflow
- **Animations**: `AnimatedContainer`, `AnimatedSwitcher` for state transitions
- **Performance**: `RepaintBoundary` on repeated list/grid items
- **Pagination**: `hasMore` + auto-fill — if first page doesn't fill viewport, next page loads automatically (home + products)
