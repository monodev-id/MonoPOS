import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth/auth_notifier.dart';
import '../../presentation/screens/account/about_screen.dart';
import '../../presentation/screens/account/account_screen.dart';
import '../../presentation/screens/account/app_update_screen.dart';
import '../../presentation/screens/account/payment_settings_screen.dart';
import '../../presentation/screens/account/product_data_screen.dart';

import '../../presentation/screens/account/printer_settings_screen.dart';
import '../../presentation/screens/account/profile_form_screen.dart';
import '../../presentation/screens/account/store_settings_screen.dart';
import '../../presentation/screens/customer/customer_form_screen.dart';
import '../../presentation/screens/customer/customer_screen.dart';
import '../../presentation/screens/employees/employee_form_screen.dart';
import '../../presentation/screens/employees/employees_screen.dart';
import '../../presentation/screens/revenue/revenue_screen.dart';
import '../../presentation/screens/error/error_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/main/main_screen.dart';
import '../../presentation/screens/payment/klik_qris_payment_screen.dart';
import '../../presentation/screens/products/product_detail_screen.dart';
import '../../presentation/screens/products/product_form_screen.dart';
import '../../presentation/screens/products/products_screen.dart';
import '../../presentation/screens/transactions/transaction_detail_screen.dart';
import '../../presentation/screens/transactions/transactions_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import 'params/error_screen_param.dart';

/// App routes
class AppRoutes {
  AppRoutes();

  static bool _isAdminOnlyPath(String? path) {
    if (path == null) return false;
    return _adminOnlyPaths.any((p) => path.startsWith(p));
  }

  static final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final navNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'nav');

  static const _adminOnlyPaths = [
    '/account/employees',
    '/account/store-settings',
    '/account/revenue',
    '/account/payment-settings',
    '/account/product-data',
    '/account/app-update',
    '/products/product-create',
    '/products/product-edit',
  ];

  GoRouter build({required Ref ref, required Listenable refreshListenable}) {
    return GoRouter(
      initialLocation: '/',
      navigatorKey: rootNavigatorKey,
      refreshListenable: refreshListenable,
      errorBuilder: (context, state) => ErrorScreen(param: ErrorScreenParam(error: state.error)),
      redirect: (context, state) {
        final authState = ref.read(authNotifierProvider);
        final isAuthenticated = authState.isAuthenticated;
        final isAdmin = authState.user?.role?.value == 'admin';
        final path = state.fullPath;

        if (path == '/') return null;

        if (!isAuthenticated) {
          final isLoginRoute = path == '/login';
          return isLoginRoute ? null : '/login';
        }

        if (path == '/login') return '/home';

        if (!isAdmin && _isAdminOnlyPath(path)) return '/home';

        return null;
      },
      routes: [
        _splash(),
        _login(),
        _main(),
        _klikQrisPayment(),
        _error(),
      ],
    );
  }

  GoRoute _splash() {
    return GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    );
  }

  GoRoute _login() {
    return GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    );
  }

  GoRoute _klikQrisPayment() {
    return GoRoute(
      path: '/payment/qris',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const KlikQrisPaymentScreen(),
    );
  }

  GoRoute _error() {
    return GoRoute(
      path: '/error',
      builder: (context, state) {
        if (state.extra == null || state.extra! is! ErrorScreenParam) {
          throw 'Required ErrorScreenParam is not provided!';
        }

        return ErrorScreen(param: state.extra as ErrorScreenParam);
      },
    );
  }

  ShellRoute _main() {
    return ShellRoute(
      navigatorKey: navNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return MainScreen(child: child);
      },
      routes: [
        _home(),
        _products(),
        _transactions(),
        _account(),
      ],
    );
  }

  GoRoute _home() {
    return GoRoute(
      path: '/home',
      pageBuilder: (context, state) {
        return const NoTransitionPage<void>(
          child: HomeScreen(),
        );
      },
    );
  }

  GoRoute _products() {
    return GoRoute(
      path: '/products',
      pageBuilder: (context, state) {
        return const NoTransitionPage<void>(
          child: ProductsScreen(),
        );
      },
      routes: [
        _productCreate(),
        _productEdit(),
        _productDetail(),
      ],
    );
  }

  GoRoute _transactions() {
    return GoRoute(
      path: '/transactions',
      pageBuilder: (context, state) {
        return const NoTransitionPage<void>(
          child: TransactionsScreen(),
        );
      },
      routes: [
        _transactionDetail(),
      ],
    );
  }

  GoRoute _account() {
    return GoRoute(
      path: '/account',
      pageBuilder: (context, state) {
        return const NoTransitionPage<void>(
          child: AccountScreen(),
        );
      },
      routes: [
        _profileEdit(),
        _about(),
        _printerSettings(),
        _storeSettings(),
        _paymentSettings(),
        _productData(),
        _appUpdate(),
        _revenue(),
        _customers(),
        _employees(),
      ],
    );
  }

  GoRoute _productCreate() {
    return GoRoute(
      path: 'product-create',
      parentNavigatorKey: navNavigatorKey,
      builder: (context, state) {
        return const ProductFormScreen();
      },
    );
  }

  GoRoute _productEdit() {
    return GoRoute(
      path: 'product-edit/:id',
      builder: (context, state) {
        int? id = int.tryParse(state.pathParameters["id"] ?? '');

        if (id == null) {
          throw 'Required productId is not provided!';
        }

        return ProductFormScreen(id: id);
      },
    );
  }

  GoRoute _productDetail() {
    return GoRoute(
      path: 'product-detail/:id',
      builder: (context, state) {
        int? id = int.tryParse(state.pathParameters["id"] ?? '');

        if (id == null) {
          throw 'Required productId is not provided!';
        }

        return ProductDetailScreen(id: id);
      },
    );
  }

  GoRoute _transactionDetail() {
    return GoRoute(
      path: 'transaction-detail/:id',
      builder: (context, state) {
        int? id = int.tryParse(state.pathParameters["id"] ?? '');

        if (id == null) {
          throw 'Required productId is not provided!';
        }

        return TransactionDetailScreen(id: id);
      },
    );
  }

  GoRoute _profileEdit() {
    return GoRoute(
      path: 'profile',
      builder: (context, state) {
        return const ProfileFormScreen();
      },
    );
  }

  GoRoute _about() {
    return GoRoute(
      path: 'about',
      builder: (context, state) {
        return const AboutScreen();
      },
    );
  }

  GoRoute _printerSettings() {
    return GoRoute(
      path: 'printer-settings',
      builder: (context, state) {
        return const PrinterSettingsScreen();
      },
    );
  }

  GoRoute _storeSettings() {
    return GoRoute(
      path: 'store-settings',
      builder: (context, state) {
        return const StoreSettingsScreen();
      },
    );
  }

  GoRoute _paymentSettings() {
    return GoRoute(
      path: 'payment-settings',
      builder: (context, state) {
        return const PaymentSettingsScreen();
      },
    );
  }

  GoRoute _productData() {
    return GoRoute(
      path: 'product-data',
      builder: (context, state) {
        return const ProductDataScreen();
      },
    );
  }

  GoRoute _appUpdate() {
    return GoRoute(
      path: 'app-update',
      builder: (context, state) {
        return const AppUpdateScreen();
      },
    );
  }

  GoRoute _revenue() {
    return GoRoute(
      path: 'revenue',
      builder: (context, state) {
        return const RevenueScreen();
      },
    );
  }

  GoRoute _customers() {
    return GoRoute(
      path: 'customers',
      builder: (context, state) {
        return const CustomerScreen();
      },
      routes: [
        _customerCreate(),
        _customerEdit(),
      ],
    );
  }

  GoRoute _employees() {
    return GoRoute(
      path: 'employees',
      builder: (context, state) {
        return const EmployeesScreen();
      },
      routes: [
        _employeeAdd(),
        _employeeEdit(),
      ],
    );
  }

  GoRoute _employeeAdd() {
    return GoRoute(
      path: 'add',
      builder: (context, state) {
        return const EmployeeFormScreen();
      },
    );
  }

  GoRoute _employeeEdit() {
    return GoRoute(
      path: 'edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        if (id == null) throw 'Required employeeId is not provided!';

        return EmployeeFormScreen(id: id);
      },
    );
  }

  GoRoute _customerCreate() {
    return GoRoute(
      path: 'customer-create',
      parentNavigatorKey: navNavigatorKey,
      builder: (context, state) {
        return const CustomerFormScreen();
      },
    );
  }

  GoRoute _customerEdit() {
    return GoRoute(
      path: 'customer-edit/:id',
      builder: (context, state) {
        final id = state.pathParameters["id"];
        if (id == null) throw 'Required customerId is not provided!';

        return CustomerFormScreen(id: id);
      },
    );
  }
}
