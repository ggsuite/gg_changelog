// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cider/cider.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../pubspec_yaml.dart';

const changeLogWithWrongFormat = '''# Changelog

## 1.2.3

- Message 1
- Message 2
''';

const changeLogWithRightFormat = '''# Changelog

## [1.2.3] 2024-04-05

- Message 1
- Message 2
''';

class MockProject extends Mock implements Project {}

/// The guidance logged for a wrong format with an example release [version].
String wrongFormat(String version) =>
    HasRightFormat.wrongFormatMessage(version: version, date: DateTime.now());

void main() {
  final messages = <String>[];
  // Strip the colors and the overwrite sequence so the expectations assert
  // the text. One closure instance — mocktail matches ggLog by identity.
  // ignore: prefer_function_declarations_over_variables
  final GgLog ggLog = (String msg) => messages.add(rmControls(msg));
  late Directory d;
  late File changeLogFile;
  late HasRightFormat hasRightFormat;
  late CommandRunner<dynamic> runner;

  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    final pubspecFile = File('${d.path}/pubspec.yaml');
    await pubspecFile.writeAsString(pubspecExample);
    hasRightFormat = HasRightFormat(ggLog: ggLog);
    changeLogFile = File('${d.path}/CHANGELOG.md');
    runner = CommandRunner('test', 'test')..addCommand(hasRightFormat);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('HasRightFormat', () {
    group('wrongFormatMessage(version, date)', () {
      test('shows the expected structure of CHANGELOG.md', () {
        expect(
          HasRightFormat.wrongFormatMessage(
            version: '0.0.0',
            date: DateTime(2026, 10, 6),
          ),
          'Please open CHANGELOG.md.\n'
          'Ensure the following structure:\n'
          '\n'
          '# CHANGELOG\n'
          '\n'
          '## Unreleased\n'
          '\n'
          '## 0.0.0 - 2026-10-06',
        );
      });
    });

    group('get(directory, ggLog)', () {
      group('should return false', () {
        group('and log the reason', () {
          test('if the change log has not the right format', () async {
            // .........................................
            // Create a change log with the wrong format
            await changeLogFile.writeAsString(changeLogWithWrongFormat);

            // ............
            // Exec command
            final result = await hasRightFormat.get(directory: d, ggLog: ggLog);

            // Check result
            expect(result, false);
            expect(messages[0], wrongFormat('1.2.3'));
          });

          test('with the pubspec.yaml version '
              'when the error names no version', () async {
            final project = MockProject();
            when(() => project.getAllVersions())
                .thenThrow(const FormatException('Something is wrong'));
            when(() => project.getVersion())
                .thenAnswer((_) async => Version(2, 4, 6));

            final ciderProject = MockCiderProject();
            when(() => ciderProject.get(directory: d))
                .thenAnswer((_) async => project);

            final result = await HasRightFormat(
              ggLog: ggLog,
              ciderProject: ciderProject,
            ).get(directory: d, ggLog: ggLog);

            expect(result, false);
            expect(messages[0], wrongFormat('2.4.6'));
          });
        });
      });

      group('should return true', () {
        test('if the change log has the right format', () async {
          // .........................................
          // Create a change log with the right format
          await changeLogFile.writeAsString(changeLogWithRightFormat);

          // ............
          // Exec command
          final result = await hasRightFormat.get(directory: d, ggLog: ggLog);

          // Check result
          expect(result, true);
          expect(messages, isEmpty);
        });

        test('and skips the check when there is no pubspec.yaml '
            '(e.g. TypeScript)', () async {
          // Remove the pubspec.yaml so the directory looks like a non-Dart
          // (e.g. TypeScript) package without a CHANGELOG.md to validate.
          await File('${d.path}/pubspec.yaml').delete();

          final result = await hasRightFormat.get(directory: d, ggLog: ggLog);

          expect(result, true);
          expect(messages, isEmpty);
        });
      });
    });

    group('exec(directory, ggLog, )', () {
      group('succeeds', () {
        test('and logs ✓ when the format is correct', () async {
          await changeLogFile.writeAsString(changeLogWithRightFormat);
          await runner.run(['has-right-format', '-i', d.path]);
          expect(messages[0], '⌛️ CHANGELOG.md has right format');
          expect(messages[1], contains('✓ CHANGELOG.md has right format'));
        });
      });

      group('throws', () {
        group('an Exception containing the reason', () {
          test('and logs ✗ when the format is incorrect', () async {
            await changeLogFile.writeAsString(changeLogWithWrongFormat);

            late String reason;

            try {
              await runner.run(['has-right-format', '-i', d.path]);
            } catch (e) {
              reason = e.toString();
            }

            expect(messages[0], '⌛️ CHANGELOG.md has right format');
            expect(messages[1], contains('✗ CHANGELOG.md has right format'));

            expect(reason, contains('Please open CHANGELOG.md.'));
            expect(reason, contains('## 1.2.3 - '));
          });
        });
      });
    });
  });
}
