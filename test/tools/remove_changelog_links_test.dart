// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_changelog/gg_changelog.dart';
import 'package:test/test.dart';

// .............................................................................
const changelogWithLinks = '''# Changelog

## [Unreleased]

### Added

- See [the docs](https://example.com/docs)

## [1.0.1] - 2024-04-05

### Fixed

- A bug

## [1.0.0] - 2024-04-01

### Added

- Initial version

[Unreleased]: https://github.com/ggsuite/gg/compare/1.0.1...HEAD
[1.0.1]: https://github.com/ggsuite/gg/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/ggsuite/gg/tag/1.0.0
''';

// .............................................................................
const changelogWithoutLinks = '''# Changelog

## Unreleased

### Added

- See [the docs](https://example.com/docs)

## 1.0.1 - 2024-04-05

### Fixed

- A bug

## 1.0.0 - 2024-04-01

### Added

- Initial version
''';

void main() {
  group('removeChangelogLinks(changelog)', () {
    test('removes the link definitions at the end of the change log', () {
      final result = removeChangelogLinks(changelogWithLinks);
      expect(result, isNot(contains('https://github.com')));
    });

    test('turns »## [1.0.1] - 2024-04-05« into »## 1.0.1 - 2024-04-05«', () {
      final result = removeChangelogLinks(changelogWithLinks);
      expect(result, contains('## 1.0.1 - 2024-04-05'));
      expect(result, contains('## Unreleased'));
      expect(result, isNot(contains('[1.0.1]')));
    });

    test('keeps inline links within the change log entries', () {
      final result = removeChangelogLinks(changelogWithLinks);
      expect(result, contains('- See [the docs](https://example.com/docs)'));
    });

    test('removes the link from inline linked headlines', () {
      const changelog =
          '# Changelog\n\n'
          '## [1.0.1](https://github.com/ggsuite/gg/tag/1.0.1) - 2024-04-05\n';

      expect(
        removeChangelogLinks(changelog),
        '# Changelog\n\n## 1.0.1 - 2024-04-05\n',
      );
    });

    test('does not change a change log without links', () {
      expect(
        removeChangelogLinks(changelogWithoutLinks),
        changelogWithoutLinks,
      );
    });

    test('returns an empty string for an empty change log', () {
      expect(removeChangelogLinks(''), '');
    });
  });

  group('removeChangelogLinksInDirectory(directory)', () {
    late Directory d;

    setUp(() async {
      d = await Directory.systemTemp.createTemp();
    });

    tearDown(() async {
      await d.delete(recursive: true);
    });

    test('removes the links from CHANGELOG.md in the directory', () async {
      final changelogFile = File('${d.path}/CHANGELOG.md');
      await changelogFile.writeAsString(changelogWithLinks);

      await removeChangelogLinksInDirectory(d);

      expect(await changelogFile.readAsString(), changelogWithoutLinks);
    });
  });
}
