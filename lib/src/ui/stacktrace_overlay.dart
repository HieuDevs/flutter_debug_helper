import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/error_capture.dart';
import '../utils/package_name_loader.dart';
import '../utils/stack_parser.dart';

/// Provides static method to install global error handling for your Flutter app.
class FlutterDebugHelper {
  /// Installs global error and zone error handlers, and runs the app with [child] as the root widget.
  static void install(Widget child) {
    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorCapture().capture(details.exception, details.stack);
      FlutterError.presentError(details);
    };

    runZonedGuarded(
      () {
        runApp(child);
      },
      (error, stack) {
        ErrorCapture().capture(error, stack);
      },
    );
  }
}

/// A widget that displays an overlay with error details and stack trace when an error occurs.
///
/// Place this widget above your app's main [Scaffold] to catch and display errors in development.
class StackTraceOverlay extends StatefulWidget {
  /// Creates a [StackTraceOverlay].
  ///
  /// [child] is the widget below the overlay.
  /// [onLogs] is an optional callback for error logs.
  /// [onlyDev] controls if the overlay only appears in development mode.
  const StackTraceOverlay({
    super.key,
    required this.child,
    this.onLogs,
    this.onlyDev = true,
  });

  /// The widget below the overlay.
  final Widget child;

  /// Optional callback for error logs.
  final void Function(List<String> logs)? onLogs;

  /// If true, overlay only appears in development mode.
  final bool onlyDev;
  @override
  State<StackTraceOverlay> createState() => _StackTraceOverlayState();
}

class _StackTraceOverlayState extends State<StackTraceOverlay> {
  String? _packageName;
  bool _isShowOverlay = false;
  final ErrorCapture _errorCapture = ErrorCapture();

  List<ParsedStackTraceLine> relevantLines = [];
  List<String> previewLines = [];
  int _selectedTab = 0; // 0: All Logs, 1: Self-logs

  @override
  void initState() {
    super.initState();
    PackageNameLoader.getPackageName().then((name) {
      if (name != null) {
        _packageName = name;
        setState(() {});
      }
    });
    _errorCapture.onError.listen((error) {
      setState(() {
        if (widget.onlyDev) {
          _isShowOverlay = true;
        }
        final allLines = error?.stack?.toString().split('\n') ?? [];
        previewLines = allLines;
        relevantLines = StackParser.parseRelevantLines(
          error?.stack,
          _packageName!,
        );
      });
      widget.onLogs?.call(previewLines);
    });
  }

  @override
  void dispose() {
    _errorCapture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = ErrorCapture().lastError;
    if (_packageName == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        widget.child,
        if (_isShowOverlay)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isShowOverlay = false),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withValues(alpha: .4),
                  alignment: Alignment.center,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 32.0,
                      ),
                      child: AnimatedScale(
                        scale: _isShowOverlay ? 1 : 0.97,
                        duration: const Duration(milliseconds: 200),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 540,
                            maxHeight: 640,
                          ),
                          child: Card(
                            elevation: 32,
                            color: Colors.white,
                            surfaceTintColor: Colors.red.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Modern error header with accent bar
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(28),
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade400,
                                        Colors.red.shade700,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 18,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withValues(
                                                alpha: .2,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'Application Error',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleLarge?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ) ??
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                              ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        tooltip: 'Close',
                                        splashRadius: 22,
                                        onPressed:
                                            () => setState(
                                              () => _isShowOverlay = false,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 18,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        error?.exception.toString() ?? '',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      // Modern tab bar
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap:
                                                    () => setState(
                                                      () => _selectedTab = 0,
                                                    ),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 180,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _selectedTab == 0
                                                            ? Colors
                                                                .red
                                                                .shade100
                                                            : Colors
                                                                .transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'All Logs',
                                                    style: TextStyle(
                                                      color:
                                                          _selectedTab == 0
                                                              ? Colors
                                                                  .red
                                                                  .shade700
                                                              : Colors.black54,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap:
                                                    () => setState(
                                                      () => _selectedTab = 1,
                                                    ),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 180,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _selectedTab == 1
                                                            ? Colors
                                                                .red
                                                                .shade100
                                                            : Colors
                                                                .transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Self-logs',
                                                    style: TextStyle(
                                                      color:
                                                          _selectedTab == 1
                                                              ? Colors
                                                                  .red
                                                                  .shade700
                                                              : Colors.black54,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      // Modern code block for logs
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[900],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[800]!,
                                            width: 1,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        constraints: const BoxConstraints(
                                          maxHeight: 220,
                                        ),
                                        child: Scrollbar(
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            child:
                                                _selectedTab == 0
                                                    ? SelectableText(
                                                      (error?.stack
                                                              ?.toString() ??
                                                          ''),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'monospace',
                                                        fontSize: 13.5,
                                                        height: 1.4,
                                                      ),
                                                    )
                                                    : Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children:
                                                          relevantLines
                                                              .map(
                                                                (
                                                                  line,
                                                                ) => SelectableText(
                                                                  line.toString(),
                                                                  style: const TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                    fontFamily:
                                                                        'monospace',
                                                                    fontSize:
                                                                        13.5,
                                                                    height: 1.4,
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          FilledButton.icon(
                                            icon: const Icon(
                                              Icons.copy,
                                              size: 20,
                                            ),
                                            label: const Text('Copy Log'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade600,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              elevation: 2,
                                            ),
                                            onPressed: () {
                                              // TODO: Copy to clipboard
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Log copied to clipboard!',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
