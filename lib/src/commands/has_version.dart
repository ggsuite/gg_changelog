// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_log/gg_log.dart';
import 'package:pub_semver/pub_semver.dart';

/// Checks if a version is already in CHANGELOG.md.
class HasVersion extends DirCommand<bool> {
  /// Constructor
  HasVersion({
    required super.ggLog,
    super.name = 'has-version',
    super.description = 'Checks if a version is already in CHANGELOG.md.',
  }) {
    _addParam();
  }

  // ...........................................................................
  /// Logs and returns true if [version] is already in CHANGELOG.md.
  @override
  Future<bool> exec({
    required Directory directory,
    required GgLog ggLog,
    Version? version,
  }) async {
    final result = await get(
      directory: directory,
      ggLog: ggLog,
      version: version,
    );
    ggLog(result.toString());
    return result;
  }

  // ...........................................................................
  /// Returns true if [version] is already in CHANGELOG.md.
  ///
  /// The check is text based and therefore also works for change logs a git
  /// merge has damaged, e.g. ones containing a version section twice.
  /// Yanked versions count as well. Returns false when CHANGELOG.md does not
  /// exist.
  @override
  Future<bool> get({
    required Directory directory,
    required GgLog ggLog,
    Version? version,
  }) async {
    // Does the directory exist?
    await check(directory: directory);

    // Read the version from the command line when it is not given
    version ??= _versionFromArgs();

    // A missing CHANGELOG.md contains no version at all
    final changelog = await _readChangelog(directory);
    if (changelog == null) {
      return false;
    }

    // Compare like cider does: trimmed and lowercased
    final searched = version.toString().trim().toLowerCase();

    return changelog
        .split('\n')
        .map(versionInChangelogHeadline)
        .whereType<Version>()
        .any((v) => v.toString().toLowerCase() == searched);
  }

  // ...........................................................................
  /// Returns true if the »## Unreleased« section contains entries.
  ///
  /// Returns false when CHANGELOG.md or its unreleased section do not exist.
  Future<bool> unreleasedHasEntries({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    // Does the directory exist?
    await check(directory: directory);

    // A missing CHANGELOG.md has no unreleased entries
    final changelog = await _readChangelog(directory);
    if (changelog == null) {
      return false;
    }

    // Look for non-empty lines within the unreleased section. Like in
    // [sortChangelog], only unreleased and version headlines start a section.
    // Other lines — including foreign »## « headlines — count as content.
    var inUnreleasedSection = false;
    for (final line in changelog.split('\n')) {
      if (isUnreleasedChangelogHeadline(line)) {
        inUnreleasedSection = true;
        continue;
      }

      if (versionInChangelogHeadline(line) != null) {
        inUnreleasedSection = false;
        continue;
      }

      if (inUnreleasedSection && line.trim().isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  Future<String?> _readChangelog(Directory directory) async {
    final changelogFile = File('${directory.path}/CHANGELOG.md');
    if (!await changelogFile.exists()) {
      return null;
    }
    return changelogFile.readAsString();
  }

  // ...........................................................................
  void _addParam() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'The version to be looked up in CHANGELOG.md.',
      mandatory: false,
    );
  }

  // ...........................................................................
  Version _versionFromArgs() {
    try {
      final versionString = argResults!['version'] as String;
      return Version.parse(versionString);
    } catch (e) {
      throw Exception(yellow('Run again with ') + blue('-v "1.2.3"'));
    }
  }
}

// .............................................................................
/// Mock for [HasVersion]
class MockHasVersion extends MockDirCommand<bool> implements HasVersion {}
