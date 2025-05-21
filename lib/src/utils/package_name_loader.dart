import 'package:flutter/services.dart';
import 'dart:convert';

class PackageNameLoader {
  static String? _cached;

  /// Đọc tên package từ pubspec.yaml, cache kết quả.
  static Future<String?> getPackageName() async {
    if (_cached != null) return _cached;

    try {
      final yamlString = await rootBundle.loadString('pubspec.yaml');
      final lines = LineSplitter.split(yamlString);
      for (final line in lines) {
        if (line.trim().startsWith('name:')) {
          final name = line.split(':').last.trim();
          _cached = name;
          return name;
        }
      }
    } catch (_) {
      // Không lấy được packageName, có thể do file không tồn tại
    }
    return null;
  }
}
