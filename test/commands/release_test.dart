// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../pubspec_yaml.dart';

void main() {
  final messages = <String>[];
  final ggLog = messages.add;
  late Directory d;
  late Add add;
  late Release release;

  // .........................................................................
  Future<String> changelogContent() async {
    final changelogFile = File('${d.path}/CHANGELOG.md');
    return await changelogFile.readAsString();
  }

  // .........................................................................
  Future<void> prepareUnreleasedVersion() async {
    // Prepare an unreleased version
    await add.exec(
      directory: d,
      ggLog: ggLog,
      message: 'Message 1',
      logType: LogType.added,
    );

    var content = changelogContent();
    expect(await content, contains('Unreleased'));
    expect(await content, contains('## Added\n'));
    expect(await content, contains('- Message 1'));
  }

  // ...........................................................................
  Future<void> expectVersion(String version) async {
    var content = changelogContent();
    expect(await content, contains('## $version -'));
  }

  // ...........................................................................
  Future<void> expectDate(DateTime date) async {
    var content = changelogContent();
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    expect(await content, contains('$year-$month-$day'));
  }

  // ...........................................................................
  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    final pubspecFile = File('${d.path}/pubspec.yaml');
    await pubspecFile.writeAsString(pubspecExample);
    release = Release(ggLog: ggLog);
    add = Add(ggLog: ggLog);
    await prepareUnreleasedVersion();
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('Release', () {
    group('exec(directory, ggLog, releaseVersion, releaseDate)', () {
      group('succeeds', () {
        group('and writes no repository links into CHANGELOG.md', () {
          test('for the released version', () async {
            await release.exec(
              directory: d,
              ggLog: ggLog,
              releaseVersion: Version(1, 2, 3),
              releaseDate: DateTime(2024, 1, 2),
            );

            final content = await changelogContent();
            expect(content, contains('## 1.2.3 - 2024-01-02'));
            expect(content, isNot(contains('https://github.com')));
          });

          test('and removes the links of previous releases', () async {
            // Write a change log containing links of previous releases
            final changelogFile = File('${d.path}/CHANGELOG.md');
            final changelog = await changelogFile.readAsString();
            await changelogFile.writeAsString(
              '$changelog\n'
              '## [1.0.0] - 2024-01-01\n\n'
              '### Added\n\n'
              '- Message 0\n\n'
              '[1.0.0]: https://github.com/inlavigo/gg_changelog/tag/1.0.0\n',
            );

            await release.exec(
              directory: d,
              ggLog: ggLog,
              releaseVersion: Version(1, 2, 3),
              releaseDate: DateTime(2024, 1, 2),
            );

            final content = await changelogContent();
            expect(content, contains('## 1.2.3 - 2024-01-02'));
            expect(content, contains('## 1.0.0 - 2024-01-01'));
            expect(content, isNot(contains('https://github.com')));
          });
        });

        group('and turns ## Unreleased into ## 1.0.0 - 2024-04-05', () {
          group('with release date', () {
            test('from today, when releaseDate is null', () async {
              await release.exec(
                directory: d,
                ggLog: ggLog,
                releaseVersion: null, // release date is null
                releaseDate: null,
              );
              await expectDate(DateTime.now());
            });

            test('from releaseDate param', () async {
              final date = DateTime(2024, 1, 2);
              await release.exec(
                directory: d,
                ggLog: ggLog,
                releaseVersion: null, // release date is null
                releaseDate: date,
              );
              await expectDate(date);
            });

            test('from command line arguments when given', () async {
              final runner = CommandRunner<void>('test', 'test')
                ..addCommand(release);

              await runner.run([
                'release',
                '--release-date',
                '2023-04-05',
                '-i',
                d.path,
              ]);

              await expectDate(DateTime(2023, 4, 5));
            });
          });
          group('with version', () {
            test('from pubspec.yaml, when not version is null', () async {
              await release.exec(
                directory: d,
                ggLog: ggLog,
                releaseVersion: null, // version is null
                releaseDate: null,
              );
              await expectDate(DateTime.now());
              await expectVersion('2.4.6');
            });

            test('from releaseVersion param', () async {
              final releaseVersion = Version(1, 2, 3);

              await release.exec(
                directory: d,
                ggLog: ggLog,
                releaseVersion: releaseVersion, // version is given
                releaseDate: null,
              );
              await expectDate(DateTime.now());
              await expectVersion('$releaseVersion');
            });

            test('from command line arguments when given', () async {
              final runner = CommandRunner<void>('test', 'test')
                ..addCommand(release);

              await runner.run([
                'release',
                '--release-version',
                '8.9.10',
                '-i',
                d.path,
              ]);

              await expectVersion('8.9.10');
            });
          });
        });
      });

      group('throws', () {
        test('when CHANGELOG.md does not exist', () async {
          final changelogFile = File('${d.path}/CHANGELOG.md');
          await changelogFile.delete();

          late String exception;

          try {
            await release.exec(
              directory: d,
              ggLog: ggLog,
              releaseVersion: null,
              releaseDate: null,
            );
          } catch (e) {
            exception = e.toString();
          }

          expect(exception, contains('CHANGELOG.md does not exist'));
        });
      });
    });
  });
}
