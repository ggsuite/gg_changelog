// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:cider/cider.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:test/test.dart';

import '../pubspec_yaml.dart';

void main() {
  late Directory d;
  late CiderProject ciderProject;

  setUp(() async {
    d = await Directory.systemTemp.createTemp();
    final pubspecFile = File('${d.path}/pubspec.yaml');
    await pubspecFile.writeAsString(pubspecExample);
    ciderProject = const CiderProject();
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('Cider', () {
    group('get(directory)', () {
      group('should succeed', () {
        test('and return a cider project', () async {
          expect(await ciderProject.get(directory: d), isA<Project>());
        });

        test('and not write repository links into CHANGELOG.md', () async {
          final changelogFile = File('${d.path}/CHANGELOG.md');
          await changelogFile.writeAsString(
            '# Changelog\n\n## 1.0.0 - 2024-04-05\n\n### Added\n\n- Initial\n',
          );

          final project = await ciderProject.get(directory: d);
          await project.release(DateTime(2024, 4, 6));

          final changelog = await changelogFile.readAsString();
          expect(changelog, contains('## 2.4.6 - 2024-04-06'));
          expect(changelog, isNot(contains('https://github.com')));
        });
      });
    });
  });
}
