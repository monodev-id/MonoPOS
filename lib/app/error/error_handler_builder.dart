import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/constants.dart';
import '../../core/services/logger/error_logger_service.dart';
import '../../core/utilities/console_logger.dart';
import '../../presentation/widgets/app_error_widget.dart';
import '../di/app_providers.dart';
import '../routes/params/error_screen_param.dart';

class ErrorHandlerBuilder extends ConsumerStatefulWidget {
  final Widget? child;

  const ErrorHandlerBuilder({
    super.key,
    this.child,
  });

  @override
  ErrorHandlerBuilderState createState() => ErrorHandlerBuilderState();
}

class ErrorHandlerBuilderState extends ConsumerState<ErrorHandlerBuilder> {
  late final ErrorLoggerService _errorLoggerService;

  @override
  void initState() {
    super.initState();
    _errorLoggerService = ref.read(errorLoggerServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set up custom widget error
      ErrorWidget.builder = (error) => AppErrorWidget(error: error, textOnly: true);

      // Called whenever the Flutter framework catches an error
      FlutterError.onError = onFlutterError;

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = onPlatformError;
    });
  }

  // Flutter error handling logic
  void onFlutterError(FlutterErrorDetails flutterError) {
    final Object exception = flutterError.exception;
    ce(exception);

    _errorLoggerService.log(error: exception, stackTrace: flutterError.stack);

    if (!mounted) return;
    if (_isBenignUnmountedError(exception)) return;

    // Skip navigation to error screen for non-critical errors
    final library = flutterError.library?.toLowerCase() ?? '';
    if (Constants.nonCriticalErrorLibraries.any((lib) => library.contains(lib))) {
      return;
    }

    _navigateToError(ErrorScreenParam(flutterError: flutterError));
  }

  // Platform error handling logic
  bool onPlatformError(Object error, StackTrace stackTrace) {
    ce(error);

    _errorLoggerService.log(error: error, stackTrace: stackTrace);

    if (!mounted) return true;
    if (_isBenignUnmountedError(error)) return true;

    _navigateToError(ErrorScreenParam(error: error, stackTrace: stackTrace));

    return true;
  }

  /// Async gaps (navigation, timers, streams) often complete after a widget
  /// was disposed. Those StateErrors are benign: just drop them instead of
  /// pushing the global error screen, which would only cause more unmounted
  /// errors in a loop.
  bool _isBenignUnmountedError(Object error) {
    final String message = error.toString().toLowerCase();

    return message.contains('unmounted') || message.contains('defunct') || message.contains('mounted');
  }

  void _navigateToError(ErrorScreenParam param) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final router = ref.read(goRouterProvider);
      if (router.routeInformationProvider.value.uri.path != '/error') {
        router.go('/error', extra: param);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}
