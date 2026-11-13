import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/**/*.dart contains zero emojis (C4)', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();

    expect(dartFiles, isNotEmpty, reason: 'Dart files should be found in lib');

    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}]',
      unicode: true,
    );

    final violations = <String>[];

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (emojiRegex.hasMatch(line)) {
          violations.add('${file.path}:${i + 1}: $line');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'No emojis allowed anywhere in lib/**/*.dart. Found:\n${violations.join('\n')}',
    );
  });
}
