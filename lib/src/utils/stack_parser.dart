class ParsedStackTraceLine {
  final String method;
  final String file;
  final int line;

  ParsedStackTraceLine({required this.method, required this.file, required this.line});

  @override
  String toString() => '$method ($file:$line)';
}

class StackParser {
  /// Lọc stacktrace, chỉ lấy dòng chứa packageName (vd: package:my_app/)
  static List<ParsedStackTraceLine> parseRelevantLines(StackTrace? stack, String packageName) {
    if (stack == null) return [];

    final lines = stack.toString().split('\n');
    final relevant = <ParsedStackTraceLine>[];
    final pattern = RegExp(r'#\d+\s+([^\s]+)\s+.+\((package:' + RegExp.escape(packageName) + r'/[^\s]+):(\d+):\d+\)');

    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        relevant.add(
          ParsedStackTraceLine(method: match.group(1)!, file: match.group(2)!, line: int.parse(match.group(3)!)),
        );
      }
    }

    return relevant;
  }
}
