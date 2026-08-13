// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  final ggLog = messages.add;
  late Directory d;
  late HasVersion hasVersion;
  late CommandRunner<dynamic> runner;

  // ...........................................................................
  Future<void> writeChangelog(String content) async {
    final changelogFile = File('${d.path}/CHANGELOG.md');
    await changelogFile.writeAsString(content);
  }

  // ...........................................................................
  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    hasVersion = HasVersion(ggLog: ggLog);
    runner = CommandRunner<dynamic>('test', 'test')..addCommand(hasVersion);
    await writeChangelog(sampleChangelog);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('HasVersion', () {
    group('get(directory, ggLog, version)', () {
      group('returns true', () {
        test('when the version is in CHANGELOG.md', () async {
          final result = await hasVersion.get(
            directory: d,
            ggLog: ggLog,
            version: Version(1, 2, 3),
          );
          expect(result, isTrue);
        });

        test('when the version is yanked', () async {
          final result = await hasVersion.get(
            directory: d,
            ggLog: ggLog,
            version: Version(1, 0, 0),
          );
          expect(result, isTrue);
        });

        test('when a git merge duplicated the version section', () async {
          await writeChangelog(
            '# Changelog\n\n'
            '## 1.2.3 - 2024-01-05\n\n- A\n\n'
            '## 1.2.3 - 2024-01-02\n\n- B\n',
          );

          final result = await hasVersion.get(
            directory: d,
            ggLog: ggLog,
            version: Version(1, 2, 3),
          );
          expect(result, isTrue);
        });
      });

      group('returns false', () {
        test('when the version is not in CHANGELOG.md', () async {
          final result = await hasVersion.get(
            directory: d,
            ggLog: ggLog,
            version: Version(9, 9, 9),
          );
          expect(result, isFalse);
        });

        test('when CHANGELOG.md does not exist', () async {
          await File('${d.path}/CHANGELOG.md').delete();

          final result = await hasVersion.get(
            directory: d,
            ggLog: ggLog,
            version: Version(1, 2, 3),
          );
          expect(result, isFalse);
        });
      });

      group('throws', () {
        test('when no version is given', () async {
          late String exception;
          try {
            await hasVersion.get(directory: d, ggLog: ggLog);
          } catch (e) {
            exception = e.toString();
          }
          expect(exception, contains('Run again with'));
        });

        test('when the version given via CLI cannot be parsed', () async {
          late String exception;
          try {
            await runner.run(['has-version', '-v', 'abc', '-i', d.path]);
          } catch (e) {
            exception = e.toString();
          }
          expect(exception, contains('Run again with'));
        });
      });
    });

    group('exec(directory, ggLog, version)', () {
      test('logs true when the version is in CHANGELOG.md', () async {
        await hasVersion.exec(
          directory: d,
          ggLog: ggLog,
          version: Version(1, 2, 3),
        );
        expect(messages.last, 'true');
      });

      test('logs false when the version is not in CHANGELOG.md', () async {
        await hasVersion.exec(
          directory: d,
          ggLog: ggLog,
          version: Version(9, 9, 9),
        );
        expect(messages.last, 'false');
      });

      test('takes the version from the command line', () async {
        await runner.run(['has-version', '-v', '1.2.3', '-i', d.path]);
        expect(messages.last, 'true');
      });
    });

    group('unreleasedHasEntries(directory, ggLog)', () {
      group('returns true', () {
        test('when the unreleased section has structured entries', () async {
          final result = await hasVersion.unreleasedHasEntries(
            directory: d,
            ggLog: ggLog,
          );
          expect(result, isTrue);
        });

        test('when the unreleased section has plain text entries', () async {
          await writeChangelog(
            '# Changelog\n\n'
            '## Unreleased\n\n'
            'Some plain text\n\n'
            '## 1.2.3 - 2024-01-02\n\n- A\n',
          );

          final result = await hasVersion.unreleasedHasEntries(
            directory: d,
            ggLog: ggLog,
          );
          expect(result, isTrue);
        });

        test('when the unreleased section has a foreign headline', () async {
          await writeChangelog(
            '# Changelog\n\n'
            '## Unreleased\n\n'
            '## Some notes\n\n'
            '## 1.2.3 - 2024-01-02\n\n- A\n',
          );

          final result = await hasVersion.unreleasedHasEntries(
            directory: d,
            ggLog: ggLog,
          );
          expect(result, isTrue);
        });
      });

      group('returns false', () {
        test('when there is no unreleased section', () async {
          await writeChangelog('# Changelog\n\n## 1.2.3 - 2024-01-02\n\n- A\n');

          final result = await hasVersion.unreleasedHasEntries(
            directory: d,
            ggLog: ggLog,
          );
          expect(result, isFalse);
        });

        test('when the unreleased section is empty', () async {
          await writeChangelog(
            '# Changelog\n\n'
            '## Unreleased\n\n'
            '## 1.2.3 - 2024-01-02\n\n- A\n',
          );

          final result = await hasVersion.unreleasedHasEntries(
            directory: d,
            ggLog: ggLog,
          );
          expect(result, isFalse);
        });

        test('when the unreleased section is the last section', () async {
          await writeChangelog('# Changelog\n\n## Unreleased\n\n\n');

          final result = await hasVersion.unreleasedHasEntries(
            directory: d,
            ggLog: ggLog,
          );
          expect(result, isFalse);
        });

        test('when CHANGELOG.md does not exist', () async {
          await File('${d.path}/CHANGELOG.md').delete();

          final result = await hasVersion.unreleasedHasEntries(
            directory: d,
            ggLog: ggLog,
          );
          expect(result, isFalse);
        });
      });
    });
  });
}

// .............................................................................
const sampleChangelog = '''# Changelog

## Unreleased

### Added

- Pending change

## 1.2.3 - 2024-01-02

### Added

- Message 1

## 1.0.0 - 2024-01-01 [YANKED]

### Added

- Message 0
''';
