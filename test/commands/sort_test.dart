// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  final ggLog = messages.add;
  late Directory d;
  late Sort sort;
  late CommandRunner<dynamic> runner;

  // ...........................................................................
  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    sort = Sort(ggLog: ggLog);
    runner = CommandRunner<dynamic>('test', 'test')..addCommand(sort);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('Sort', () {
    group('get(directory, ggLog)', () {
      test('sorts the versions in CHANGELOG.md. Newest first.', () async {
        final changelogFile = File('${d.path}/CHANGELOG.md');
        await changelogFile.writeAsString(
          '# Changelog\n\n'
          '## 1.0.0 - 2024-04-05\n\n- Feature A\n\n'
          '## 1.1.0 - 2024-04-01\n\n- Feature B\n',
        );

        await runner.run(['sort', '-i', d.path]);

        expect(
          await changelogFile.readAsString(),
          '# Changelog\n\n'
          '## 1.1.0 - 2024-04-01\n\n- Feature B\n\n'
          '## 1.0.0 - 2024-04-05\n\n- Feature A\n',
        );
      });

      test('throws when CHANGELOG.md does not exist', () async {
        late String exception;
        try {
          await sort.get(directory: d, ggLog: ggLog);
        } catch (e) {
          exception = e.toString();
        }
        expect(exception, contains('CHANGELOG.md does not exist'));
      });
    });
  });
}
