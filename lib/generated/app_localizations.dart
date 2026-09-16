import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mono POS'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @home_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Products...'**
  String get home_searchHint;

  /// No description provided for @home_syncronizing.
  ///
  /// In en, this message translates to:
  /// **'Syncronizing'**
  String get home_syncronizing;

  /// No description provided for @home_synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get home_synced;

  /// No description provided for @home_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get home_pending;

  /// No description provided for @home_onlineMode.
  ///
  /// In en, this message translates to:
  /// **'Online mode'**
  String get home_onlineMode;

  /// No description provided for @home_noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection, running in offline mode'**
  String get home_noInternet;

  /// No description provided for @home_enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get home_enterAmount;

  /// No description provided for @home_addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add To Cart'**
  String get home_addToCart;

  /// No description provided for @home_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get home_cancel;

  /// No description provided for @home_noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products available, add product to continue'**
  String get home_noProducts;

  /// No description provided for @home_addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get home_addProduct;

  /// No description provided for @home_transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get home_transaction;

  /// No description provided for @home_pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get home_pay;

  /// No description provided for @home_retail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get home_retail;

  /// No description provided for @home_grosir.
  ///
  /// In en, this message translates to:
  /// **'Grosir'**
  String get home_grosir;

  /// No description provided for @cart_products.
  ///
  /// In en, this message translates to:
  /// **'{count} Products'**
  String cart_products(Object count);

  /// No description provided for @cart_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get cart_confirm;

  /// No description provided for @cart_removeAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to remove all product?'**
  String get cart_removeAllConfirm;

  /// No description provided for @cart_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cart_remove;

  /// No description provided for @cart_removeAll.
  ///
  /// In en, this message translates to:
  /// **'Remove All'**
  String get cart_removeAll;

  /// No description provided for @cart_empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get cart_empty;

  /// No description provided for @cart_noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products added to cart'**
  String get cart_noProducts;

  /// No description provided for @cart_total.
  ///
  /// In en, this message translates to:
  /// **'Total ({count})'**
  String cart_total(Object count);

  /// No description provided for @cart_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cart_back;

  /// No description provided for @cart_receivedAmount.
  ///
  /// In en, this message translates to:
  /// **'Received Amount'**
  String get cart_receivedAmount;

  /// No description provided for @cart_receivedAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Received amount...'**
  String get cart_receivedAmountHint;

  /// No description provided for @cart_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get cart_paymentMethod;

  /// No description provided for @cart_bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get cart_bank;

  /// No description provided for @cart_cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cart_cash;

  /// No description provided for @cart_customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name (Optional)'**
  String get cart_customerName;

  /// No description provided for @cart_customerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Jhone Doe'**
  String get cart_customerNameHint;

  /// No description provided for @cart_description.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get cart_description;

  /// No description provided for @cart_descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description...'**
  String get cart_descriptionHint;

  /// No description provided for @cart_stock.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String cart_stock(Object count);

  /// No description provided for @cart_removeProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to remove this product?'**
  String get cart_removeProductConfirm;

  /// No description provided for @cart_paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get cart_paymentType;

  /// No description provided for @cart_credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get cart_credit;

  /// No description provided for @cart_dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get cart_dueDate;

  /// No description provided for @cart_dueDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select due date...'**
  String get cart_dueDateHint;

  /// No description provided for @product_stockSold.
  ///
  /// In en, this message translates to:
  /// **'Stock {stock} | Sold {sold}'**
  String product_stockSold(Object stock, Object sold);

  /// No description provided for @product_retailPrice.
  ///
  /// In en, this message translates to:
  /// **'Retail: {price}'**
  String product_retailPrice(Object price);

  /// No description provided for @product_grosirPrice.
  ///
  /// In en, this message translates to:
  /// **'Grosir: {price}'**
  String product_grosirPrice(Object price);

  /// No description provided for @product_outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get product_outOfStock;

  /// No description provided for @product_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Products...'**
  String get product_searchHint;

  /// No description provided for @product_noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products available, add product to continue'**
  String get product_noProducts;

  /// No description provided for @product_createTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Product'**
  String get product_createTitle;

  /// No description provided for @product_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get product_editTitle;

  /// No description provided for @product_image.
  ///
  /// In en, this message translates to:
  /// **'Product Image'**
  String get product_image;

  /// No description provided for @product_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get product_nameLabel;

  /// No description provided for @product_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Product name...'**
  String get product_nameHint;

  /// No description provided for @product_retailPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Retail Price'**
  String get product_retailPriceLabel;

  /// No description provided for @product_retailPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Retail price...'**
  String get product_retailPriceHint;

  /// No description provided for @product_wholesalePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Wholesale Price (Optional)'**
  String get product_wholesalePriceLabel;

  /// No description provided for @product_wholesalePriceHint.
  ///
  /// In en, this message translates to:
  /// **'Wholesale price...'**
  String get product_wholesalePriceHint;

  /// No description provided for @product_stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get product_stockLabel;

  /// No description provided for @product_stockHint.
  ///
  /// In en, this message translates to:
  /// **'Product stock...'**
  String get product_stockHint;

  /// No description provided for @product_barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get product_barcodeLabel;

  /// No description provided for @product_barcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Scan or type barcode...'**
  String get product_barcodeHint;

  /// No description provided for @product_barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get product_barcode;

  /// No description provided for @product_unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get product_unitLabel;

  /// No description provided for @product_descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get product_descriptionLabel;

  /// No description provided for @product_descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Product description...'**
  String get product_descriptionHint;

  /// No description provided for @product_addButton.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get product_addButton;

  /// No description provided for @product_updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get product_updateButton;

  /// No description provided for @product_deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get product_deleteButton;

  /// No description provided for @product_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to delete this product?'**
  String get product_deleteConfirm;

  /// No description provided for @product_deleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get product_deleted;

  /// No description provided for @product_created.
  ///
  /// In en, this message translates to:
  /// **'Product created'**
  String get product_created;

  /// No description provided for @product_updated.
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get product_updated;

  /// No description provided for @product_detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Detail'**
  String get product_detailTitle;

  /// No description provided for @product_editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get product_editProduct;

  /// No description provided for @product_noName.
  ///
  /// In en, this message translates to:
  /// **'(No name)'**
  String get product_noName;

  /// No description provided for @product_addedAt.
  ///
  /// In en, this message translates to:
  /// **'Added at {date}'**
  String product_addedAt(Object date);

  /// No description provided for @product_lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated at {date}'**
  String product_lastUpdated(Object date);

  /// No description provided for @product_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get product_price;

  /// No description provided for @product_stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get product_stock;

  /// No description provided for @product_sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get product_sold;

  /// No description provided for @product_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get product_description;

  /// No description provided for @product_noDescription.
  ///
  /// In en, this message translates to:
  /// **'(No description)'**
  String get product_noDescription;

  /// No description provided for @product_notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get product_notFound;

  /// No description provided for @transaction_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Transaction ID...'**
  String get transaction_searchHint;

  /// No description provided for @transaction_noTransaction.
  ///
  /// In en, this message translates to:
  /// **'No transaction available'**
  String get transaction_noTransaction;

  /// No description provided for @transaction_detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction Detail'**
  String get transaction_detailTitle;

  /// No description provided for @transaction_reprint.
  ///
  /// In en, this message translates to:
  /// **'Reprint'**
  String get transaction_reprint;

  /// No description provided for @transaction_created.
  ///
  /// In en, this message translates to:
  /// **'Transaction Created'**
  String get transaction_created;

  /// No description provided for @transaction_id.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transaction_id;

  /// No description provided for @transaction_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get transaction_paymentMethod;

  /// No description provided for @transaction_createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created By'**
  String get transaction_createdBy;

  /// No description provided for @transaction_createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get transaction_createdAt;

  /// No description provided for @transaction_customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get transaction_customerName;

  /// No description provided for @transaction_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get transaction_description;

  /// No description provided for @transaction_orderedProducts.
  ///
  /// In en, this message translates to:
  /// **'Ordered Products'**
  String get transaction_orderedProducts;

  /// No description provided for @transaction_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get transaction_total;

  /// No description provided for @transaction_paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get transaction_paymentReceived;

  /// No description provided for @transaction_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get transaction_change;

  /// No description provided for @transaction_notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get transaction_notFound;

  /// No description provided for @revenue_title.
  ///
  /// In en, this message translates to:
  /// **'Revenue Report'**
  String get revenue_title;

  /// No description provided for @revenue_totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get revenue_totalRevenue;

  /// No description provided for @revenue_transactions.
  ///
  /// In en, this message translates to:
  /// **'{count} Transactions'**
  String revenue_transactions(Object count);

  /// No description provided for @revenue_products.
  ///
  /// In en, this message translates to:
  /// **'{count} Products'**
  String revenue_products(Object count);

  /// No description provided for @revenue_noData.
  ///
  /// In en, this message translates to:
  /// **'No revenue data available'**
  String get revenue_noData;

  /// No description provided for @transaction_products.
  ///
  /// In en, this message translates to:
  /// **'{count} Products'**
  String transaction_products(Object count);

  /// No description provided for @storeSettings_title.
  ///
  /// In en, this message translates to:
  /// **'Store Settings'**
  String get storeSettings_title;

  /// No description provided for @storeSettings_storeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeSettings_storeNameLabel;

  /// No description provided for @storeSettings_storeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your store name...'**
  String get storeSettings_storeNameHint;

  /// No description provided for @storeSettings_storeAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get storeSettings_storeAddressLabel;

  /// No description provided for @storeSettings_storeAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Your store address...'**
  String get storeSettings_storeAddressHint;

  /// No description provided for @storeSettings_receiptFooterLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt Footer'**
  String get storeSettings_receiptFooterLabel;

  /// No description provided for @storeSettings_receiptFooterHint.
  ///
  /// In en, this message translates to:
  /// **'Message at the bottom of receipt, e.g: Thank you for shopping'**
  String get storeSettings_receiptFooterHint;

  /// No description provided for @storeSettings_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get storeSettings_save;

  /// No description provided for @storeSettings_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get storeSettings_saving;

  /// No description provided for @storeSettings_saved.
  ///
  /// In en, this message translates to:
  /// **'Store settings saved'**
  String get storeSettings_saved;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settings_profile;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settings_close;

  /// No description provided for @settings_darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settings_darkMode;

  /// No description provided for @settings_printerSettings.
  ///
  /// In en, this message translates to:
  /// **'Printer Settings'**
  String get settings_printerSettings;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settings_english;

  /// No description provided for @settings_indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get settings_indonesian;

  /// No description provided for @settings_noName.
  ///
  /// In en, this message translates to:
  /// **'(No Name)'**
  String get settings_noName;

  /// No description provided for @settings_appUpdate.
  ///
  /// In en, this message translates to:
  /// **'App Updates'**
  String get settings_appUpdate;

  /// No description provided for @dataProduct_title.
  ///
  /// In en, this message translates to:
  /// **'Product Data'**
  String get dataProduct_title;

  /// No description provided for @dataProduct_export.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get dataProduct_export;

  /// No description provided for @dataProduct_import.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get dataProduct_import;

  /// No description provided for @dataProduct_exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get dataProduct_exporting;

  /// No description provided for @dataProduct_importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get dataProduct_importing;

  /// No description provided for @dataProduct_exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} products'**
  String dataProduct_exportSuccess(Object count);

  /// No description provided for @dataProduct_importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} products'**
  String dataProduct_importSuccess(Object count);

  /// No description provided for @dataProduct_exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get dataProduct_exportFailed;

  /// No description provided for @dataProduct_importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get dataProduct_importFailed;

  /// No description provided for @dataProduct_importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Products'**
  String get dataProduct_importTitle;

  /// No description provided for @dataProduct_importConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will add the products from the backup file. Continue?'**
  String get dataProduct_importConfirm;

  /// No description provided for @dataProduct_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dataProduct_cancel;

  /// No description provided for @dataProduct_confirm.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get dataProduct_confirm;

  /// No description provided for @dataProduct_noFile.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get dataProduct_noFile;

  /// No description provided for @dataProduct_invalidFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get dataProduct_invalidFile;

  /// No description provided for @profile_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profile_editTitle;

  /// No description provided for @profile_image.
  ///
  /// In en, this message translates to:
  /// **'Profile Image'**
  String get profile_image;

  /// No description provided for @profile_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profile_nameLabel;

  /// No description provided for @profile_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name...'**
  String get profile_nameHint;

  /// No description provided for @profile_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profile_emailLabel;

  /// No description provided for @profile_emailHint.
  ///
  /// In en, this message translates to:
  /// **'Your email...'**
  String get profile_emailHint;

  /// No description provided for @profile_phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profile_phoneLabel;

  /// No description provided for @profile_phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Your phone number...'**
  String get profile_phoneHint;

  /// No description provided for @profile_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get profile_update;

  /// No description provided for @profile_cropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Crop Photo'**
  String get profile_cropPhoto;

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profile_updated;

  /// No description provided for @printer_title.
  ///
  /// In en, this message translates to:
  /// **'Printer Settings'**
  String get printer_title;

  /// No description provided for @printer_paperSize.
  ///
  /// In en, this message translates to:
  /// **'Paper Size'**
  String get printer_paperSize;

  /// No description provided for @printer_connectionTypes.
  ///
  /// In en, this message translates to:
  /// **'Connection Types'**
  String get printer_connectionTypes;

  /// No description provided for @printer_selectConnection.
  ///
  /// In en, this message translates to:
  /// **'Select connection types'**
  String get printer_selectConnection;

  /// No description provided for @printer_usb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get printer_usb;

  /// No description provided for @printer_bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get printer_bluetooth;

  /// No description provided for @printer_ble.
  ///
  /// In en, this message translates to:
  /// **'BLE'**
  String get printer_ble;

  /// No description provided for @printer_network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get printer_network;

  /// No description provided for @printer_allConnections.
  ///
  /// In en, this message translates to:
  /// **'All connection types'**
  String get printer_allConnections;

  /// No description provided for @printer_availableDevices.
  ///
  /// In en, this message translates to:
  /// **'Available Devices'**
  String get printer_availableDevices;

  /// No description provided for @printer_scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning for printers...'**
  String get printer_scanning;

  /// No description provided for @printer_noDevice.
  ///
  /// In en, this message translates to:
  /// **'(No printer detected)'**
  String get printer_noDevice;

  /// No description provided for @printer_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected to {name}'**
  String printer_connected(Object name);

  /// No description provided for @printer_notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected. Select a printer to connect.'**
  String get printer_notConnected;

  /// No description provided for @printer_connectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {name}...'**
  String printer_connectingTo(Object name);

  /// No description provided for @printer_connectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get printer_connectedBadge;

  /// No description provided for @printer_connectingBadge.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get printer_connectingBadge;

  /// No description provided for @printer_disconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting...'**
  String get printer_disconnecting;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_title;

  /// No description provided for @about_appName.
  ///
  /// In en, this message translates to:
  /// **'Mono POS'**
  String get about_appName;

  /// No description provided for @about_version.
  ///
  /// In en, this message translates to:
  /// **'version {version}'**
  String about_version(Object version);

  /// No description provided for @about_description.
  ///
  /// In en, this message translates to:
  /// **'Mono POS is a Flutter-based Point of Sale (POS) application for managing products, sales transactions, customers, and employees. It supports QRIS payments (Klik QRIS) and revenue reports, stores data locally with SQLite, and can be synchronized to a REST API server.'**
  String get about_description;

  /// No description provided for @about_developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed with ❤️ by'**
  String get about_developedBy;

  /// No description provided for @about_developerName.
  ///
  /// In en, this message translates to:
  /// **'Fakhri Aditia Rahman'**
  String get about_developerName;

  /// No description provided for @about_github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get about_github;

  /// No description provided for @about_website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get about_website;

  /// No description provided for @update_title.
  ///
  /// In en, this message translates to:
  /// **'App Updates'**
  String get update_title;

  /// No description provided for @update_currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed version'**
  String get update_currentVersion;

  /// No description provided for @update_latestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest version'**
  String get update_latestVersion;

  /// No description provided for @update_check.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get update_check;

  /// No description provided for @update_checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get update_checking;

  /// No description provided for @update_downloadInstall.
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get update_downloadInstall;

  /// No description provided for @update_downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {percent}%'**
  String update_downloading(Object percent);

  /// No description provided for @update_installing.
  ///
  /// In en, this message translates to:
  /// **'Opening installer...'**
  String get update_installing;

  /// No description provided for @update_upToDate.
  ///
  /// In en, this message translates to:
  /// **'App is already up to date'**
  String get update_upToDate;

  /// No description provided for @update_available.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get update_available;

  /// No description provided for @update_changelogTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in {version}'**
  String update_changelogTitle(Object version);

  /// No description provided for @update_noChangelog.
  ///
  /// In en, this message translates to:
  /// **'No release notes.'**
  String get update_noChangelog;

  /// No description provided for @update_noApk.
  ///
  /// In en, this message translates to:
  /// **'This release does not include an APK file.'**
  String get update_noApk;

  /// No description provided for @update_releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Released {date}'**
  String update_releaseDate(Object date);

  /// No description provided for @update_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get update_retry;

  /// No description provided for @update_androidOnly.
  ///
  /// In en, this message translates to:
  /// **'Automatic install is only available on Android.'**
  String get update_androidOnly;

  /// No description provided for @error_backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get error_backToHome;

  /// No description provided for @shared_oops.
  ///
  /// In en, this message translates to:
  /// **'Oops!'**
  String get shared_oops;

  /// No description provided for @shared_somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please contact developer.'**
  String get shared_somethingWrong;

  /// No description provided for @shared_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get shared_close;

  /// No description provided for @shared_nothingToShow.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show'**
  String get shared_nothingToShow;

  /// No description provided for @shared_somethingWrongRetry.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.\nPlease try again later.'**
  String get shared_somethingWrongRetry;

  /// No description provided for @lowStock_title.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get lowStock_title;

  /// No description provided for @lowStock_message.
  ///
  /// In en, this message translates to:
  /// **'{count} products are running low on stock'**
  String lowStock_message(Object count);

  /// No description provided for @lowStock_item.
  ///
  /// In en, this message translates to:
  /// **'{name} — {stock} left'**
  String lowStock_item(Object name, Object stock);

  /// No description provided for @lowStock_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get lowStock_ok;

  /// No description provided for @receipt_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get receipt_date;

  /// No description provided for @receipt_trxId.
  ///
  /// In en, this message translates to:
  /// **'Trx. ID'**
  String get receipt_trxId;

  /// No description provided for @receipt_customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get receipt_customer;

  /// No description provided for @receipt_cashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get receipt_cashier;

  /// No description provided for @receipt_item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get receipt_item;

  /// No description provided for @receipt_qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get receipt_qty;

  /// No description provided for @receipt_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get receipt_price;

  /// No description provided for @receipt_subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get receipt_subtotal;

  /// No description provided for @receipt_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get receipt_total;

  /// No description provided for @receipt_pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get receipt_pay;

  /// No description provided for @receipt_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get receipt_change;

  /// No description provided for @receipt_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get receipt_paymentMethod;

  /// No description provided for @receipt_grosir.
  ///
  /// In en, this message translates to:
  /// **'Grosir'**
  String get receipt_grosir;

  /// No description provided for @receipt_retail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get receipt_retail;

  /// No description provided for @receipt_testTitle.
  ///
  /// In en, this message translates to:
  /// **'MONO POS TEST PRINT OK'**
  String get receipt_testTitle;

  /// No description provided for @receipt_testTopLeft.
  ///
  /// In en, this message translates to:
  /// **'top left'**
  String get receipt_testTopLeft;

  /// No description provided for @receipt_testTopRight.
  ///
  /// In en, this message translates to:
  /// **'top right'**
  String get receipt_testTopRight;

  /// No description provided for @receipt_testBottomLeft.
  ///
  /// In en, this message translates to:
  /// **'bottom left'**
  String get receipt_testBottomLeft;

  /// No description provided for @receipt_testBottomRight.
  ///
  /// In en, this message translates to:
  /// **'bottom right'**
  String get receipt_testBottomRight;

  /// No description provided for @receipt_testThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank You'**
  String get receipt_testThanks;

  /// No description provided for @receipt_storeName.
  ///
  /// In en, this message translates to:
  /// **'YOUR STORE'**
  String get receipt_storeName;

  /// No description provided for @receipt_merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get receipt_merchant;

  /// No description provided for @receipt_qrisTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Payment'**
  String get receipt_qrisTotal;

  /// No description provided for @receipt_qrisScan.
  ///
  /// In en, this message translates to:
  /// **'Scan QRIS to pay'**
  String get receipt_qrisScan;

  /// No description provided for @receipt_qrisNote.
  ///
  /// In en, this message translates to:
  /// **'* Payment will be detected automatically *'**
  String get receipt_qrisNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
