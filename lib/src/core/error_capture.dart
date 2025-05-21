import 'dart:async';

/// A class that holds an exception and its associated stack trace.
class CapturedError {
  /// The exception that was captured.
  final Object exception;

  /// The stack trace associated with the exception, if available.
  final StackTrace? stack;

  /// Creates a [CapturedError] with the given [exception] and [stack].
  CapturedError(this.exception, this.stack);
}

/// Singleton class for capturing and broadcasting errors throughout the app.
class ErrorCapture {
  static final ErrorCapture _instance = ErrorCapture._internal();

  /// Returns the singleton instance of [ErrorCapture].
  factory ErrorCapture() => _instance;

  ErrorCapture._internal();

  /// The last error that was captured, if any.
  CapturedError? lastError;

  final StreamController<CapturedError?> _errorController = StreamController.broadcast();

  /// A stream of captured errors.
  Stream<CapturedError?> get onError => _errorController.stream;

  /// Captures an [error] and its [stack] trace, and notifies listeners.
  void capture(Object error, StackTrace? stack) {
    lastError = CapturedError(error, stack);
    _errorController.add(lastError);
  }

  /// Disposes the error controller.
  void dispose() {
    _errorController.close();
  }
}
