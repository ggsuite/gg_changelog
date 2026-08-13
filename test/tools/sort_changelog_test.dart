// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_changelog/src/tools/sort_changelog.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('versionInChangelogHeadline(line)', () {
    test('returns the version of version headlines', () {
      expect(
        versionInChangelogHeadline('## 1.2.3 - 2024-01-01'),
        Version(1, 2, 3),
      );
      expect(
        versionInChangelogHeadline('## [1.2.3] - 2024-01-01'),
        Version(1, 2, 3),
      );
      expect(
        versionInChangelogHeadline(r'## \[1.2.3\] - 2024-01-01'),
        Version(1, 2, 3),
      );
      expect(
        versionInChangelogHeadline('## [1.2.3](https://foo.com) - 2024-01-01'),
        Version(1, 2, 3),
      );
      expect(versionInChangelogHeadline('## 1.2.3'), Version(1, 2, 3));
      expect(
        versionInChangelogHeadline('## 1.2.3 - 2024-01-01 [YANKED]'),
        Version(1, 2, 3),
      );
      expect(
        versionInChangelogHeadline('## 1.2.3-rc.1+build - 2024-01-01'),
        Version.parse('1.2.3-rc.1+build'),
      );
    });

    test('returns null for other lines', () {
      expect(versionInChangelogHeadline('## Unreleased'), isNull);
      expect(versionInChangelogHeadline('## v1.2.3'), isNull);
      expect(versionInChangelogHeadline('### 1.2.3 - 2024-01-01'), isNull);
      expect(versionInChangelogHeadline('# Changelog'), isNull);
      expect(versionInChangelogHeadline('- Some text'), isNull);
      expect(versionInChangelogHeadline(''), isNull);
    });
  });

  group('isUnreleasedChangelogHeadline(line)', () {
    test('returns true for unreleased headlines', () {
      expect(isUnreleasedChangelogHeadline('## Unreleased'), isTrue);
      expect(isUnreleasedChangelogHeadline('## [Unreleased]'), isTrue);
      expect(isUnreleasedChangelogHeadline(r'## \[Unreleased\]'), isTrue);
      expect(isUnreleasedChangelogHeadline('## unreleased - 2024-04-09'), true);
    });

    test('returns false for other lines', () {
      expect(isUnreleasedChangelogHeadline('## 1.2.3 - 2024-01-01'), isFalse);
      expect(isUnreleasedChangelogHeadline('### Unreleased'), isFalse);
      expect(isUnreleasedChangelogHeadline('- Unreleased'), isFalse);
      expect(isUnreleasedChangelogHeadline(''), isFalse);
    });
  });

  group('sortChangelog(changelog)', () {
    test('sorts the versions by version number and not by date', () {
      // In unsortedSample version 1.1.0 carries an older date than 1.0.0 —
      // e.g. the result of a git merge. The version number wins.
      expect(sortChangelog(unsortedSample), sortedSample);
    });

    test('does not change an already sorted changelog', () {
      expect(sortChangelog(sortedSample), sortedSample);
    });

    test('is idempotent', () {
      expect(sortChangelog(sortChangelog(unsortedSample)), sortedSample);
    });

    test('keeps duplicated versions in their original order', () {
      expect(sortChangelog(duplicatedSample), duplicatedSampleSorted);
    });

    test('sorts headline variants like escaped or linked headlines', () {
      expect(sortChangelog(variantsSample), variantsSampleSorted);
    });

    test('keeps foreign headlines attached to their section', () {
      expect(sortChangelog(foreignHeadlineSample), foreignHeadlineSorted);
    });

    test('sorts changelogs without a header', () {
      expect(
        sortChangelog('## 1.0.0 - 2024-01-01\n\n## 2.0.0 - 2024-01-02\n'),
        '## 2.0.0 - 2024-01-02\n\n## 1.0.0 - 2024-01-01\n',
      );
    });

    test('returns content without version headlines unchanged', () {
      expect(sortChangelog(''), '');
      expect(sortChangelog('Just some text'), 'Just some text');
      expect(
        sortChangelog('# Changelog\n\nSome text\n'),
        '# Changelog\n\nSome text\n',
      );
    });
  });

  group('sortChangelogInDirectory(directory)', () {
    test('sorts the changelog in the given directory', () async {
      final d = await Directory.systemTemp.createTemp('gg_test_');
      final changelogFile = File('${d.path}/CHANGELOG.md');
      await changelogFile.writeAsString(unsortedSample);

      await sortChangelogInDirectory(d);
      expect(await changelogFile.readAsString(), sortedSample);

      // Sorting a sorted changelog does not change it anymore
      await sortChangelogInDirectory(d);
      expect(await changelogFile.readAsString(), sortedSample);

      await d.delete(recursive: true);
    });
  });
}

// .............................................................................
const unsortedSample = '''# Changelog

## 1.0.0 - 2024-04-05

### Added

- Feature A

## Unreleased

### Added

- Pending change

## 1.1.0 - 2024-04-01

### Added

- Feature B
''';

// .............................................................................
const sortedSample = '''# Changelog

## Unreleased

### Added

- Pending change

## 1.1.0 - 2024-04-01

### Added

- Feature B

## 1.0.0 - 2024-04-05

### Added

- Feature A
''';

// .............................................................................
const duplicatedSample = '''# Changelog

## 1.0.0 - 2024-04-05

- First occurrence

## 1.1.0 - 2024-04-06

- Feature B

## 1.0.0 - 2024-04-07

- Second occurrence
''';

// .............................................................................
const duplicatedSampleSorted = '''# Changelog

## 1.1.0 - 2024-04-06

- Feature B

## 1.0.0 - 2024-04-05

- First occurrence

## 1.0.0 - 2024-04-07

- Second occurrence
''';

// .............................................................................
const variantsSample = '''# Changelog

## \\[0.9.0\\] - 2024-01-01

- Escaped

## [1.2.3](https://github.com/org/repo/tag/1.2.3) - 2024-03-01

- Linked

## 1.2.3-rc.1 - 2024-02-25

- Release candidate

## [1.0.0] - 2024-02-01 [YANKED]

- Bracketed and yanked

## 2.0.0

- No date
''';

// .............................................................................
const variantsSampleSorted = '''# Changelog

## 2.0.0

- No date

## [1.2.3](https://github.com/org/repo/tag/1.2.3) - 2024-03-01

- Linked

## 1.2.3-rc.1 - 2024-02-25

- Release candidate

## [1.0.0] - 2024-02-01 [YANKED]

- Bracketed and yanked

## \\[0.9.0\\] - 2024-01-01

- Escaped
''';

// .............................................................................
const foreignHeadlineSample = '''# Changelog

## 1.0.0 - 2024-04-05

### Added

- Feature A

## Some notes

- Note under a foreign headline

## 1.1.0 - 2024-04-06

- Feature B
''';

// .............................................................................
const foreignHeadlineSorted = '''# Changelog

## 1.1.0 - 2024-04-06

- Feature B

## 1.0.0 - 2024-04-05

### Added

- Feature A

## Some notes

- Note under a foreign headline
''';
