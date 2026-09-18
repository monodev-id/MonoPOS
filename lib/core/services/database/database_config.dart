class DatabaseConfig {
  // Prevents instantiation and extension
  DatabaseConfig._();

  static const String dbPath = 'app_database.db';
  static const int version = 3;

  static const String userTableName = 'User';
  static const String productTableName = 'Product';
  static const String productUnitTableName = 'ProductUnit';
  static const String productTieredPriceTableName = 'ProductTieredPrice';
  static const String customerTableName = 'Customer';
  static const String transactionTableName = 'Transaction';
  static const String orderedProductTableName = 'OrderedProduct';
  static const String queuedActionTableName = 'QueuedAction';

  static const String createUserTable =
      '''
CREATE TABLE IF NOT EXISTS '$userTableName' (
    'id' TEXT NOT NULL,
    'email' TEXT,
    'phone' TEXT,
    'name' TEXT,
    'gender' TEXT,
    'birthdate' TEXT,
    'imageUrl' TEXT,
    'authProvider' TEXT,
    'password' TEXT,
    'role' TEXT DEFAULT 'kasir',
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id')
);
''';

  static const String createProductTable =
      '''
CREATE TABLE IF NOT EXISTS '$productTableName' (
    'id' INTEGER NOT NULL,
    'createdById' TEXT,
    'name' TEXT,
    'imageUrl' TEXT,
    'stock' INTEGER,
    'sold' INTEGER,
    'price' INTEGER,
    'wholesalePrice' INTEGER,
    'unit' TEXT DEFAULT 'pcs',
    'barcode' TEXT,
    'description' TEXT,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('createdById') REFERENCES 'User' ('id')
);
''';

  static const String createProductUnitTable =
      '''
CREATE TABLE IF NOT EXISTS '$productUnitTableName' (
    'id' INTEGER NOT NULL,
    'productId' INTEGER NOT NULL,
    'unitName' TEXT NOT NULL,
    'conversionValue' INTEGER NOT NULL DEFAULT 1,
    'price' INTEGER NOT NULL,
    'wholesalePrice' INTEGER,
    'isBase' INTEGER NOT NULL DEFAULT 0,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('productId') REFERENCES 'Product' ('id')
);
''';

  static const String createProductTieredPriceTable =
      '''
CREATE TABLE IF NOT EXISTS '$productTieredPriceTableName' (
    'id' INTEGER NOT NULL,
    'productUnitId' INTEGER NOT NULL,
    'minQty' INTEGER NOT NULL DEFAULT 1,
    'maxQty' INTEGER,
    'price' INTEGER NOT NULL,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('productUnitId') REFERENCES 'ProductUnit' ('id')
);
''';

  static const String createTransactionTable =
      '''
CREATE TABLE IF NOT EXISTS '$transactionTableName' (
    'id' INTEGER NOT NULL,
    'paymentMethod' TEXT,
    'customerName' TEXT,
    'description' TEXT,
    'createdById' TEXT,
    'receivedAmount' INTEGER,
    'returnAmount' INTEGER,
    'totalAmount' INTEGER,
    'totalOrderedProduct' INTEGER,
    'paymentStatus' TEXT DEFAULT 'paid',
    'paymentQR' TEXT,
    'paymentExternalId' TEXT,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('createdById') REFERENCES 'User' ('id')
);
''';

  static const String createOrderedProductTable =
      '''
CREATE TABLE IF NOT EXISTS '$orderedProductTableName' (
    'id' INTEGER NOT NULL,
    'transactionId' INTEGER,
    'productId' INTEGER,
    'quantity' REAL NOT NULL DEFAULT 1,
    'stock' INTEGER,
    'name' TEXT,
    'imageUrl' TEXT,
    'price' INTEGER,
    'priceType' TEXT DEFAULT 'retail',
    'unit' TEXT DEFAULT 'pcs',
    'conversionValue' INTEGER NOT NULL DEFAULT 1,
    'isTieredPrice' INTEGER NOT NULL DEFAULT 0,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('transactionId') REFERENCES 'Transaction' ('id'),
    FOREIGN KEY ('productId') REFERENCES 'Product' ('id')
);
''';

  static const String createCustomerTable =
      '''
CREATE TABLE IF NOT EXISTS '$customerTableName' (
    'id' TEXT NOT NULL,
    'name' TEXT NOT NULL,
    'phone' TEXT,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id')
);
''';

  static const String createQueuedActionTable =
      '''
CREATE TABLE IF NOT EXISTS '$queuedActionTableName' (
    'id' INTEGER NOT NULL,
    'repository' TEXT,
    'method' TEXT,
    'param' TEXT,
    'isCritical' INTEGER,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';

  static const String createProductBarcodeIndex = 'CREATE INDEX IF NOT EXISTS idx_product_barcode ON Product(barcode)';
}
