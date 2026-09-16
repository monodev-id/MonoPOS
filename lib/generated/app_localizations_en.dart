// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mono POS';

  @override
  String get home => 'Home';

  @override
  String get products => 'Products';

  @override
  String get transactions => 'Transactions';

  @override
  String get settings => 'Settings';

  @override
  String get home_searchHint => 'Search Products...';

  @override
  String get home_syncronizing => 'Syncronizing';

  @override
  String get home_synced => 'Synced';

  @override
  String get home_pending => 'Pending';

  @override
  String get home_onlineMode => 'Online mode';

  @override
  String get home_noInternet =>
      'No internet connection, running in offline mode';

  @override
  String get home_enterAmount => 'Enter Amount';

  @override
  String get home_addToCart => 'Add To Cart';

  @override
  String get home_cancel => 'Cancel';

  @override
  String get home_noProducts =>
      'No products available, add product to continue';

  @override
  String get home_addProduct => 'Add Product';

  @override
  String get home_transaction => 'Transaction';

  @override
  String get home_pay => 'Pay';

  @override
  String get home_retail => 'Retail';

  @override
  String get home_grosir => 'Grosir';

  @override
  String cart_products(Object count) {
    return '$count Products';
  }

  @override
  String get cart_confirm => 'Confirm';

  @override
  String get cart_removeAllConfirm =>
      'Are you sure want to remove all product?';

  @override
  String get cart_remove => 'Remove';

  @override
  String get cart_removeAll => 'Remove All';

  @override
  String get cart_empty => 'Empty';

  @override
  String get cart_noProducts => 'No products added to cart';

  @override
  String cart_total(Object count) {
    return 'Total ($count)';
  }

  @override
  String get cart_back => 'Back';

  @override
  String get cart_receivedAmount => 'Received Amount';

  @override
  String get cart_receivedAmountHint => 'Received amount...';

  @override
  String get cart_paymentMethod => 'Payment Method';

  @override
  String get cart_bank => 'Bank';

  @override
  String get cart_cash => 'Cash';

  @override
  String get cart_customerName => 'Customer Name (Optional)';

  @override
  String get cart_customerNameHint => 'e.g. Jhone Doe';

  @override
  String get cart_description => 'Description (Optional)';

  @override
  String get cart_descriptionHint => 'Description...';

  @override
  String cart_stock(Object count) {
    return 'Stock: $count';
  }

  @override
  String get cart_removeProductConfirm =>
      'Are you sure want to remove this product?';

  @override
  String get cart_paymentType => 'Payment Type';

  @override
  String get cart_credit => 'Credit';

  @override
  String get cart_dueDate => 'Due Date';

  @override
  String get cart_dueDateHint => 'Select due date...';

  @override
  String product_stockSold(Object stock, Object sold) {
    return 'Stock $stock | Sold $sold';
  }

  @override
  String product_retailPrice(Object price) {
    return 'Retail: $price';
  }

  @override
  String product_grosirPrice(Object price) {
    return 'Grosir: $price';
  }

  @override
  String get product_outOfStock => 'Out of stock';

  @override
  String get product_searchHint => 'Search Products...';

  @override
  String get product_noProducts =>
      'No products available, add product to continue';

  @override
  String get product_createTitle => 'Create Product';

  @override
  String get product_editTitle => 'Edit Product';

  @override
  String get product_image => 'Product Image';

  @override
  String get product_nameLabel => 'Name';

  @override
  String get product_nameHint => 'Product name...';

  @override
  String get product_retailPriceLabel => 'Retail Price';

  @override
  String get product_retailPriceHint => 'Retail price...';

  @override
  String get product_wholesalePriceLabel => 'Wholesale Price (Optional)';

  @override
  String get product_wholesalePriceHint => 'Wholesale price...';

  @override
  String get product_stockLabel => 'Stock';

  @override
  String get product_stockHint => 'Product stock...';

  @override
  String get product_barcodeLabel => 'Barcode';

  @override
  String get product_barcodeHint => 'Scan or type barcode...';

  @override
  String get product_barcode => 'Barcode';

  @override
  String get product_unitLabel => 'Unit';

  @override
  String get product_descriptionLabel => 'Description';

  @override
  String get product_descriptionHint => 'Product description...';

  @override
  String get product_addButton => 'Add Product';

  @override
  String get product_updateButton => 'Update Product';

  @override
  String get product_deleteButton => 'Delete';

  @override
  String get product_deleteConfirm =>
      'Are you sure want to delete this product?';

  @override
  String get product_deleted => 'Product deleted';

  @override
  String get product_created => 'Product created';

  @override
  String get product_updated => 'Product updated';

  @override
  String get product_detailTitle => 'Product Detail';

  @override
  String get product_editProduct => 'Edit Product';

  @override
  String get product_noName => '(No name)';

  @override
  String product_addedAt(Object date) {
    return 'Added at $date';
  }

  @override
  String product_lastUpdated(Object date) {
    return 'Last updated at $date';
  }

  @override
  String get product_price => 'Price';

  @override
  String get product_stock => 'Stock';

  @override
  String get product_sold => 'Sold';

  @override
  String get product_description => 'Description';

  @override
  String get product_noDescription => '(No description)';

  @override
  String get product_notFound => 'Not Found';

  @override
  String get transaction_searchHint => 'Search Transaction ID...';

  @override
  String get transaction_noTransaction => 'No transaction available';

  @override
  String get transaction_detailTitle => 'Transaction Detail';

  @override
  String get transaction_reprint => 'Reprint';

  @override
  String get transaction_created => 'Transaction Created';

  @override
  String get transaction_id => 'Transaction ID';

  @override
  String get transaction_paymentMethod => 'Payment Method';

  @override
  String get transaction_createdBy => 'Created By';

  @override
  String get transaction_createdAt => 'Created At';

  @override
  String get transaction_customerName => 'Customer Name';

  @override
  String get transaction_description => 'Description';

  @override
  String get transaction_orderedProducts => 'Ordered Products';

  @override
  String get transaction_total => 'Total';

  @override
  String get transaction_paymentReceived => 'Payment Received';

  @override
  String get transaction_change => 'Change';

  @override
  String get transaction_notFound => 'Not Found';

  @override
  String get revenue_title => 'Revenue Report';

  @override
  String get revenue_totalRevenue => 'Total Revenue';

  @override
  String revenue_transactions(Object count) {
    return '$count Transactions';
  }

  @override
  String revenue_products(Object count) {
    return '$count Products';
  }

  @override
  String get revenue_noData => 'No revenue data available';

  @override
  String transaction_products(Object count) {
    return '$count Products';
  }

  @override
  String get storeSettings_title => 'Store Settings';

  @override
  String get storeSettings_storeNameLabel => 'Store Name';

  @override
  String get storeSettings_storeNameHint => 'Your store name...';

  @override
  String get storeSettings_storeAddressLabel => 'Address';

  @override
  String get storeSettings_storeAddressHint => 'Your store address...';

  @override
  String get storeSettings_receiptFooterLabel => 'Receipt Footer';

  @override
  String get storeSettings_receiptFooterHint =>
      'Message at the bottom of receipt, e.g: Thank you for shopping';

  @override
  String get storeSettings_save => 'Save';

  @override
  String get storeSettings_saving => 'Saving...';

  @override
  String get storeSettings_saved => 'Store settings saved';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_profile => 'Profile';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_close => 'Close';

  @override
  String get settings_darkMode => 'Dark Mode';

  @override
  String get settings_printerSettings => 'Printer Settings';

  @override
  String get settings_about => 'About';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_english => 'English';

  @override
  String get settings_indonesian => 'Indonesian';

  @override
  String get settings_noName => '(No Name)';

  @override
  String get settings_appUpdate => 'App Updates';

  @override
  String get dataProduct_title => 'Product Data';

  @override
  String get dataProduct_export => 'Export Data';

  @override
  String get dataProduct_import => 'Import Data';

  @override
  String get dataProduct_exporting => 'Exporting...';

  @override
  String get dataProduct_importing => 'Importing...';

  @override
  String dataProduct_exportSuccess(Object count) {
    return 'Exported $count products';
  }

  @override
  String dataProduct_importSuccess(Object count) {
    return 'Imported $count products';
  }

  @override
  String get dataProduct_exportFailed => 'Export failed';

  @override
  String get dataProduct_importFailed => 'Import failed';

  @override
  String get dataProduct_importTitle => 'Import Products';

  @override
  String get dataProduct_importConfirm =>
      'This will add the products from the backup file. Continue?';

  @override
  String get dataProduct_cancel => 'Cancel';

  @override
  String get dataProduct_confirm => 'Import';

  @override
  String get dataProduct_noFile => 'No file selected';

  @override
  String get dataProduct_invalidFile => 'Invalid backup file';

  @override
  String get profile_editTitle => 'Edit Profile';

  @override
  String get profile_image => 'Profile Image';

  @override
  String get profile_nameLabel => 'Name';

  @override
  String get profile_nameHint => 'Your name...';

  @override
  String get profile_emailLabel => 'Email';

  @override
  String get profile_emailHint => 'Your email...';

  @override
  String get profile_phoneLabel => 'Phone Number';

  @override
  String get profile_phoneHint => 'Your phone number...';

  @override
  String get profile_update => 'Update';

  @override
  String get profile_cropPhoto => 'Crop Photo';

  @override
  String get profile_updated => 'Profile updated';

  @override
  String get printer_title => 'Printer Settings';

  @override
  String get printer_paperSize => 'Paper Size';

  @override
  String get printer_connectionTypes => 'Connection Types';

  @override
  String get printer_selectConnection => 'Select connection types';

  @override
  String get printer_usb => 'USB';

  @override
  String get printer_bluetooth => 'Bluetooth';

  @override
  String get printer_ble => 'BLE';

  @override
  String get printer_network => 'Network';

  @override
  String get printer_allConnections => 'All connection types';

  @override
  String get printer_availableDevices => 'Available Devices';

  @override
  String get printer_scanning => 'Scanning for printers...';

  @override
  String get printer_noDevice => '(No printer detected)';

  @override
  String get about_title => 'About';

  @override
  String get about_appName => 'Mono POS';

  @override
  String about_version(Object version) {
    return 'version $version';
  }

  @override
  String get about_description =>
      'Mono POS is a Flutter-based Point of Sale (POS) application for managing products, sales transactions, customers, and employees. It supports QRIS payments (Klik QRIS) and revenue reports, stores data locally with SQLite, and can be synchronized to a REST API server.';

  @override
  String get about_developedBy => 'Developed with ❤️ by';

  @override
  String get about_developerName => 'Fakhri Aditia Rahman';

  @override
  String get about_github => 'GitHub';

  @override
  String get about_website => 'Website';

  @override
  String get update_title => 'App Updates';

  @override
  String get update_currentVersion => 'Installed version';

  @override
  String get update_latestVersion => 'Latest version';

  @override
  String get update_check => 'Check for Updates';

  @override
  String get update_checking => 'Checking...';

  @override
  String get update_downloadInstall => 'Download & Install';

  @override
  String update_downloading(Object percent) {
    return 'Downloading... $percent%';
  }

  @override
  String get update_installing => 'Opening installer...';

  @override
  String get update_upToDate => 'App is already up to date';

  @override
  String get update_available => 'New version available';

  @override
  String update_changelogTitle(Object version) {
    return 'What\'s new in $version';
  }

  @override
  String get update_noChangelog => 'No release notes.';

  @override
  String get update_noApk => 'This release does not include an APK file.';

  @override
  String update_releaseDate(Object date) {
    return 'Released $date';
  }

  @override
  String get update_retry => 'Retry';

  @override
  String get update_androidOnly =>
      'Automatic install is only available on Android.';

  @override
  String get error_backToHome => 'Back to home';

  @override
  String get shared_oops => 'Oops!';

  @override
  String get shared_somethingWrong =>
      'Something went wrong, please contact developer.';

  @override
  String get shared_close => 'Close';

  @override
  String get shared_nothingToShow => 'Nothing to show';

  @override
  String get shared_somethingWrongRetry =>
      'Something went wrong.\nPlease try again later.';

  @override
  String get lowStock_title => 'Low Stock Alert';

  @override
  String lowStock_message(Object count) {
    return '$count products are running low on stock';
  }

  @override
  String lowStock_item(Object name, Object stock) {
    return '$name — $stock left';
  }

  @override
  String get lowStock_ok => 'OK';

  @override
  String get receipt_date => 'Date';

  @override
  String get receipt_trxId => 'Trx. ID';

  @override
  String get receipt_customer => 'Customer';

  @override
  String get receipt_cashier => 'Cashier';

  @override
  String get receipt_item => 'Item';

  @override
  String get receipt_qty => 'Qty';

  @override
  String get receipt_price => 'Price';

  @override
  String get receipt_subtotal => 'Subtotal';

  @override
  String get receipt_total => 'Total';

  @override
  String get receipt_pay => 'Pay';

  @override
  String get receipt_change => 'Change';

  @override
  String get receipt_paymentMethod => 'Payment';

  @override
  String get receipt_grosir => 'Grosir';

  @override
  String get receipt_retail => 'Retail';

  @override
  String get receipt_testTitle => 'MONO POS TEST PRINT OK';

  @override
  String get receipt_testTopLeft => 'top left';

  @override
  String get receipt_testTopRight => 'top right';

  @override
  String get receipt_testBottomLeft => 'bottom left';

  @override
  String get receipt_testBottomRight => 'bottom right';

  @override
  String get receipt_testThanks => 'Thank You';

  @override
  String get receipt_storeName => 'YOUR STORE';

  @override
  String get receipt_merchant => 'Merchant';

  @override
  String get receipt_qrisTotal => 'Total Payment';

  @override
  String get receipt_qrisScan => 'Scan QRIS to pay';

  @override
  String get receipt_qrisNote => '* Payment will be detected automatically *';
}
