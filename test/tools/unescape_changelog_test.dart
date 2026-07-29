// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_changelog/gg_changelog.dart';
import 'package:test/test.dart';

// .............................................................................
const changelogWithEscapes = r'''# Changelog

## \[1.0.1\] - 2024-04-05

### Removed

- dependency to gg\_install\_gg, remove ./check script
- wild card routes using '\*' as route name
- pub.dev can take \~10 min
- add \| change \| deprecate

## 1.0.0 - 2024-04-01

### Added

- Initial version
''';

// .............................................................................
const changelogWithoutEscapes = '''# Changelog

## [1.0.1] - 2024-04-05

### Removed

- dependency to gg_install_gg, remove ./check script
- wild card routes using '*' as route name
- pub.dev can take ~10 min
- add | change | deprecate

## 1.0.0 - 2024-04-01

### Added

- Initial version
''';

void main() {
  group('unescapeChangelog(changelog)', () {
    test('reverts the escapes cider added', () {
      expect(unescapeChangelog(changelogWithEscapes), changelogWithoutEscapes);
    });

    test('does not change a change log without escapes', () {
      expect(
        unescapeChangelog(changelogWithoutEscapes),
        changelogWithoutEscapes,
      );
    });

    test('returns an empty string for an empty change log', () {
      expect(unescapeChangelog(''), '');
    });

    test('turns »gg\\_install\\_gg« into »gg_install_gg«', () {
      expect(unescapeChangelog(r'- gg\_install\_gg'), '- gg_install_gg');
    });

    test('turns »## \\[1.1.3\\] - ...« into »## [1.1.3] - ...«', () {
      expect(
        unescapeChangelog(r'## \[1.1.3\] - 2025-08-08'),
        '## [1.1.3] - 2025-08-08',
      );
    });

    group('keeps the escapes', () {
      test('of »#«, because it would start a headline', () {
        expect(
          unescapeChangelog(r'- \# not a headline'),
          r'- \# not a headline',
        );
      });

      test('of »-« and »+«, because they would start a list item', () {
        expect(unescapeChangelog(r'- \- a'), r'- \- a');
        expect(unescapeChangelog(r'- \+ a'), r'- \+ a');
      });

      test('of »1.«, because it would start an ordered list item', () {
        expect(unescapeChangelog(r'- 1\. a'), r'- 1\. a');
      });

      test('within code spans', () {
        const changelog = r'- `a\_b` but not gg\_one and `c_d`';
        expect(
          unescapeChangelog(changelog),
          r'- `a\_b` but not gg_one and `c_d`',
        );
      });

      test('within fenced code blocks', () {
        const changelog =
            '- An example\n\n'
            '```\n'
            r'final a = b\_c;'
            '\n'
            '```\n\n'
            r'- and gg\_one'
            '\n';

        expect(
          unescapeChangelog(changelog),
          '- An example\n\n'
          '```\n'
          r'final a = b\_c;'
          '\n'
          '```\n\n'
          '- and gg_one\n',
        );
      });
    });

    test('unescapes when a backtick is left unclosed', () {
      expect(
        unescapeChangelog(r'- use ` to quote gg\_one'),
        '- use ` to quote gg_one',
      );
    });

    test('keeps a literal backslash in front of an escaped character', () {
      // »a\\_b« is a literal backslash followed by an escaped underscore
      expect(unescapeChangelog(r'a\\_b'), r'a\_b');
    });
  });

  group('unescapeChangelogInDirectory(directory)', () {
    late Directory d;

    setUp(() async {
      d = await Directory.systemTemp.createTemp();
    });

    tearDown(() async {
      await d.delete(recursive: true);
    });

    test('removes the escapes from CHANGELOG.md in the directory', () async {
      final changelogFile = File('${d.path}/CHANGELOG.md');
      await changelogFile.writeAsString(changelogWithEscapes);

      await unescapeChangelogInDirectory(d);

      expect(await changelogFile.readAsString(), changelogWithoutEscapes);
    });
  });
}
