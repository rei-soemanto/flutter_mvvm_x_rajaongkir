// Fails when an emoji or an ASCII emoticon appears anywhere in the project.
//
// The project rule is that the codebase carries no emoticons, and reviewing
// that by eye does not scale. Run it with:
//
//   dart run tool/check_no_emoticons.dart
//
// The patterns below are built from escape sequences on purpose, so this file
// does not trip its own check.
import 'dart:io';

/// Folders and files that are scanned, relative to the project root.
const List<String> scanned = [
  'lib',
  'test',
  'tool',
  'config',
  '.vscode',
  'CLAUDE.md',
  'README.md',
  'pubspec.yaml',
  'analysis_options.yaml',
];

/// File endings worth reading. Anything else is skipped as binary.
const List<String> textExtensions = [
  '.dart',
  '.json',
  '.md',
  '.yaml',
  '.yml',
  '.xml',
];

/// Code point ranges that hold emoji and pictographs.
const List<List<int>> emojiRanges = [
  [0x1F000, 0x1FAFF], // Emoticons, pictographs, symbols, flags.
  [0x2600, 0x27BF], // Miscellaneous symbols and dingbats.
  [0x2B00, 0x2BFF], // Arrows and geometric shapes used as emoji.
  [0xFE0F, 0xFE0F], // Variation selector that renders a glyph as emoji.
  [0x200D, 0x200D], // Zero width joiner, used to build compound emoji.
];

// The pieces emoticons are made of, kept as character codes so that this file
// never spells one out and flags itself.
final String _eyes = String.fromCharCodes([0x3A, 0x3B]);
final String _nose = String.fromCharCode(0x2D);
final String _mouths = String.fromCharCodes([0x29, 0x28, 0x44, 0x50, 0x70]);
final String _caret = String.fromCharCode(0x5E);
final String _underscore = String.fromCharCode(0x5F);
final String _less = String.fromCharCode(0x3C);
final String _three = String.fromCharCode(0x33);

/// Text emoticons.
///
/// Each one has to stand on its own. Without the word boundaries, a package
/// import or a courier list such as the codes joined by colons would look like
/// a smiley to the scanner.
final List<RegExp> emoticonPatterns = [
  // Eyes, an optional nose, then a mouth.
  RegExp('(?<!\\w)[$_eyes]$_nose?[$_mouths](?!\\w)'),
  // The happy face made of two carets around an underscore.
  RegExp('(?<!\\w)\\$_caret$_underscore\\$_caret'),
  // The heart made of a less-than sign and a three.
  RegExp('(?<![\\w$_less])$_less$_three(?![0-9])'),
];

void main(List<String> arguments) {
  final findings = <String>[];

  for (final target in scanned) {
    final entity = FileSystemEntity.typeSync(target);
    if (entity == FileSystemEntityType.file) {
      findings.addAll(_checkFile(File(target)));
    } else if (entity == FileSystemEntityType.directory) {
      final files = Directory(target)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => textExtensions.any(file.path.endsWith));
      for (final file in files) {
        findings.addAll(_checkFile(file));
      }
    }
  }

  if (findings.isEmpty) {
    stdout.writeln('No emoticons found.');
    return;
  }

  stdout.writeln('Found ${findings.length} emoticons:');
  for (final finding in findings) {
    stdout.writeln('  $finding');
  }
  exitCode = 1;
}

List<String> _checkFile(File file) {
  final findings = <String>[];
  final path = file.path.replaceAll(r'\', '/');
  final lines = file.readAsLinesSync();

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final number = index + 1;

    for (final rune in line.runes) {
      final inRange = emojiRanges.any(
        (range) => rune >= range[0] && rune <= range[1],
      );
      if (inRange) {
        findings.add(
          '$path:$number holds the code point '
          'U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}',
        );
        break;
      }
    }

    for (final pattern in emoticonPatterns) {
      if (pattern.hasMatch(line)) {
        findings.add('$path:$number holds a text emoticon');
        break;
      }
    }
  }

  return findings;
}
