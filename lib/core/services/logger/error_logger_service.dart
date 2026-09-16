import '../../utilities/console_logger.dart';

/// Global error logging service
class ErrorLoggerService {
  ErrorLoggerService();

  /// Log error to console
  void log({
    required Object error,
    StackTrace? stackTrace,
    String? title,
    String? message,
    String? state,
  }) {
    final StringBuffer buffer = StringBuffer(error.toString());
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    ce(buffer.toString(), title: title, message: message, state: state);
  }
}
