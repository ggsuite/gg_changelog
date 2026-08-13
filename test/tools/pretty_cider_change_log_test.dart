// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_changelog/src/tools/pretty_cider_change_log.dart';
import 'package:test/test.dart';

void main() {
  group('prettyChangeLog(changeLog)', () {
    test('should make sure headlines are surrounded by empty lines', () {
      // Fix a broken changelog
      final before = brokenSample0;
      final after = prettyCiderChangelog(before);
      expect(after, fixedSample);

      // Fix another broken changelog
      final before1 = brokenSample1;
      final after1 = prettyCiderChangelog(before1);
      expect(after1, fixedSample);

      // A fixed changelog should not be changed anymore
      final after2 = prettyCiderChangelog(after);
      expect(after2, fixedSample);
    });
  });

  group('prettyPrintChangelogInDirectory(directory)', () {
    test('should pretty print a changelog in a directory', () async {
      final d = await Directory.systemTemp.createTemp('gg_test_');
      final changelogFile = File('${d.path}/CHANGELOG.md');
      await changelogFile.writeAsString(brokenSample0);

      // Fix a broken changelog
      await prettyPrintChangelogInDirectory(d);

      // A fixed changelog should not be changed anymore
      final after2 = await changelogFile.readAsString();
      expect(after2, fixedSample);

      // Delete stuff
      await d.delete(recursive: true);
    });
  });
}

final brokenSample0 =
    '''
# Changelog
## 1.0.13 - 2024-04-05
### Added
- Hello World
- Hello World

## [1.0.12] - 2024-04-04
- Initial version

[1.0.12]: https://github.com/inlavigo/gg/releases/tag/1.0.12'''
        .trim();

final brokenSample1 =
    '''
# Changelog
## 1.0.13 - 2024-04-05
### Added
- Hello World
- Hello World
## [1.0.12] - 2024-04-04
- Initial version

[1.0.12]: https://github.com/inlavigo/gg/releases/tag/1.0.12
'''
        .trim();

const fixedSample = '''# Changelog

## 1.0.13 - 2024-04-05

### Added

- Hello World
- Hello World

## [1.0.12] - 2024-04-04

- Initial version

[1.0.12]: https://github.com/inlavigo/gg/releases/tag/1.0.12
''';
