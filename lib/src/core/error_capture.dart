import 'dart:async';

class CapturedError {
  final Object exception;
  final StackTrace? stack;

  CapturedError(this.exception, this.stack);
}

class ErrorCapture {
  static final ErrorCapture _instance = ErrorCapture._internal();

  factory ErrorCapture() => _instance;

  ErrorCapture._internal();

  CapturedError? lastError;

  final StreamController<CapturedError?> _errorController = StreamController.broadcast();

  Stream<CapturedError?> get onError => _errorController.stream;

  void capture(Object error, StackTrace? stack) {
    lastError = CapturedError(error, stack);
    _errorController.add(lastError);
  }

  void dispose() {
    _errorController.close();
  }
}
