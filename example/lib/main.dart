import 'package:flutter/material.dart';
import 'package:flutter_debug_helper/flutter_debug_helper.dart';

void main() {
  FlutterDebugHelper.install(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StackTraceOverlay(
        onLogs: (logs) {},
        onlyDev: true,
        child: Scaffold(
          appBar: AppBar(title: const Text('Crash Logger Demo')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    throw Exception('Test crash!');
                  },
                  child: const Text('Crash App'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await Future.delayed(const Duration(milliseconds: 100));
                    throw Exception('Async crash!');
                  },
                  child: const Text('Async Crash'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String? value;
                    // ignore: dead_code
                    // ignore: unused_local_variable
                    print(value!.length); // Will throw a null dereference error
                  },
                  child: const Text('Null Dereference Crash'),
                ),
                ElevatedButton(
                  onPressed: () {
                    throw CustomError('Custom error occurred!');
                  },
                  child: const Text('Custom Error Crash'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmptyPage()));
                  },
                  child: const Text('Push Navigator crash demo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomError implements Exception {
  final String message;
  CustomError(this.message);
  @override
  String toString() => 'CustomError: $message';
}

class EmptyPage extends StatefulWidget {
  const EmptyPage({super.key});

  @override
  State<EmptyPage> createState() => _EmptyPageState();
}

class _EmptyPageState extends State<EmptyPage> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
