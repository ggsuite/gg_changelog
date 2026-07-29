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
  late CommandRunner<dynamic> runner;

  const expectedContent =
      '# Changelog\n\n## Unreleased\n\n### Added\n\n- Message 1\n';

  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    final pubspecFile = File('${d.path}/pubspec.yaml');
    await pubspecFile.writeAsString(pubspecExample);
    add = Add(ggLog: ggLog);
    runner = CommandRunner('test', 'Test runner')..addCommand(add);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  Future<String> changelogContent() async {
    final changelogFile = File('${d.path}/CHANGELOG.md');
    return await changelogFile.readAsString();
  }

  group('Add', () {
    group('exec(directory, ggLog, message, logType)', () {
      group('should succeed', () {
        test('and take message and logType from cli args when given', () async {
          await runner.run([
            'add',
            '--message',
            'Message 1',
            '--log-type',
            'added',
            '-i',
            d.path,
          ]);

          final content0 = await changelogContent();
          expect(content0, expectedContent);
        });

        group('and return', () {
          group('false', () {
            group('and not add the message', () {
              test(
                'when the message is already contained at Unreleased',
                () async {
                  // ...........................
                  // Exec command the first time
                  // => Message should be added
                  final result0 = await add.exec(
                    directory: d,
                    ggLog: ggLog,
                    message: 'Message 1',
                    logType: LogType.added,
                  );

                  // Check result
                  expect(result0, true);

                  final content0 = await changelogContent();
                  expect(content0, expectedContent);

                  // ..........................
                  // Exec command a second time
                  // => Message should not be added again
                  final result1 = await add.exec(
                    directory: d,
                    ggLog: ggLog,
                    message: 'Message 1',
                    logType: LogType.added,
                  );

                  final content1 = await changelogContent();
                  expect(content1, content0);

                  // Check result
                  expect(result1, false);

                  // ...................
                  // Release the version
                  await Release(ggLog: ggLog).exec(
                    directory: d,
                    ggLog: ggLog,
                    releaseVersion: Version(1, 2, 3),
                  );

                  final content2 = await changelogContent();
                  expect(content2, contains('## 1.2.3 -'));
                  expect(content2, isNot(contains('Unreleased')));

                  // ...................
                  // Add Message 1 again
                  // => Message should be added
                  // because the previous version was released
                  final result2 = await add.exec(
                    directory: d,
                    ggLog: ggLog,
                    message: 'Message 1',
                    logType: LogType.added,
                  );
                  expect(result2, true);
                  final content3 = await changelogContent();

                  // Count number of occurrances of 'Message 1'
                  final count = RegExp('Message 1').allMatches(content3).length;
                  expect(count, 2);
                },
              );
            });
          });

          group('true', () {
            test(
              'when the message is not contained in the unreleased section',
              () async {
                // Exec command
                // => Message should be added
                final result0 = await add.exec(
                  directory: d,
                  ggLog: ggLog,
                  message: 'Message 1',
                  logType: LogType.added,
                );

                // Check result
                expect(result0, true);

                final content0 = await changelogContent();
                expect(content0, expectedContent);
              },
            );
          });
        });
      });

      group('should throw', () {
        test('when --message arg is not given', () async {
          late String exception;

          try {
            await runner.run([
              'add',
              // --message
              // 'Message 3',
              '--log-type',
              'fixed',
              '-i',
              d.path,
            ]);
          } catch (e) {
            exception = e.toString();
          }

          expect(exception, contains('Run again with '));
          expect(exception, contains('yourMessage'));
        });

        test('when --log-type arg is not given', () async {
          late String exception;

          try {
            await runner.run([
              'add',
              // '--log-type',
              // 'fixed',
              '--message',
              'Message 3',
              '-i',
              d.path,
            ]);
          } catch (e) {
            exception = e.toString();
          }

          expect(exception, contains('Run again with '));
          expect(
            exception,
            contains(
              'added | changed | deprecated | fixed | removed | security',
            ),
          );
        });
      });

      group('should handle special cases like', () {
        test(
          'the initial CHANGLOE.md generated by gg_create_package',
          () async {
            final changelogFile = File('${d.path}/CHANGELOG.md');
            await changelogFile.writeAsString(
              changeLogCreatedByGgCreatePackage,
            );

            await add.exec(
              directory: d,
              ggLog: ggLog,
              message: 'Message 1',
              logType: LogType.added,
            );

            final contentAfter = await changelogContent();
            expect(
              contentAfter,
              changeLogCreatedByGgCreatePackageAfterAddingMessage,
            );
          },
        );
      });
    });
  });
}

// .............................................................................
const changeLogCreatedByGgCreatePackage = '''# Changelog

## Unreleased

- Initial version.
''';

// .............................................................................
const changeLogCreatedByGgCreatePackageAfterAddingMessage = '''# Changelog

## Unreleased

- Initial version.

### Added

- Message 1
''';
