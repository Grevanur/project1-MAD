// Turns coverage/lcov.info into a readable docs/COVERAGE.md.
//
// Usage:
//   flutter test --coverage
//   dart run tool/coverage_summary.dart
import 'dart:io';

void main() {
  final input = File('coverage/lcov.info');
  if (!input.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info not found. Run: flutter test --coverage',
    );
    exitCode = 1;
    return;
  }

  final files = <String, (int found, int hit)>{};
  String? current;
  var found = 0;
  var hit = 0;
  for (final line in input.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3).replaceAll(r'\', '/');
      final libIndex = current.indexOf('lib/');
      if (libIndex >= 0) current = current.substring(libIndex);
      found = 0;
      hit = 0;
    } else if (line.startsWith('DA:')) {
      found++;
      final count = int.tryParse(line.split(',')[1]) ?? 0;
      if (count > 0) hit++;
    } else if (line == 'end_of_record' && current != null) {
      files[current] = (found, hit);
      current = null;
    }
  }

  final names = files.keys.toList()..sort();
  var totalFound = 0;
  var totalHit = 0;
  final rows = StringBuffer();
  for (final name in names) {
    final (f, h) = files[name]!;
    totalFound += f;
    totalHit += h;
    rows.writeln('| `$name` | $h / $f | ${_percent(h, f)} |');
  }

  final date = DateTime.now().toIso8601String().substring(0, 10);
  final report = StringBuffer()
    ..writeln('# Test Coverage Report')
    ..writeln()
    ..writeln(
      'Generated $date with `flutter test --coverage` and '
      '`dart run tool/coverage_summary.dart`.',
    )
    ..writeln()
    ..writeln(
      '**Total line coverage: ${_percent(totalHit, totalFound)}** '
      '($totalHit of $totalFound lines in `lib/`).',
    )
    ..writeln()
    ..writeln('| File | Lines hit | Coverage |')
    ..writeln('|---|---:|---:|')
    ..write(rows)
    ..writeln()
    ..writeln(
      'Platform services (notifications, file export) are covered '
      'through fakes in widget tests and on-device checks; see README.',
    );

  Directory('docs').createSync(recursive: true);
  File('docs/COVERAGE.md').writeAsStringSync(report.toString());
  stdout.writeln(
    'Wrote docs/COVERAGE.md: ${_percent(totalHit, totalFound)} total.',
  );
}

String _percent(int hit, int found) =>
    found == 0 ? 'n/a' : '${(hit * 100 / found).toStringAsFixed(1)}%';
