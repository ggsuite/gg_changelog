// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:cider/cider.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_log/gg_log.dart';
import 'package:pub_semver/pub_semver.dart';

/// An example command
class Release extends DirCommand<void> {
  /// Constructor
  Release({
    required super.ggLog,
    super.name = 'release',
    super.description = 'Releases the current change log.',
    CiderProject? ciderProject,
  }) : _ciderProject = ciderProject ?? const CiderProject() {
    _addParam();
  }

  // ...........................................................................
  /// Returns true if a message was added to the change log.
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
    Version? releaseVersion,
    DateTime? releaseDate,
  }) => get(
    directory: directory,
    ggLog: ggLog,
    releaseVersion: releaseVersion,
    releaseDate: releaseDate,
  );

  // ...........................................................................
  /// Returns true if a message was added to the change log.
  @override
  Future<void> get({
    required Directory directory,
    required GgLog ggLog,
    Version? releaseVersion,
    DateTime? releaseDate,
  }) async {
    // Does the directory exist?
    await check(directory: directory);

    // Throw if CHANGELOG.md does not exist
    final changelogFile = File('${directory.path}/CHANGELOG.md');
    if (!await changelogFile.exists()) {
      throw Exception('CHANGELOG.md does not exist');
    }

    // Read the release version from the command line
    final releaseVersionStr = argResults?['release-version'] as String?;
    releaseVersion ??= releaseVersionStr != null
        ? Version.parse(releaseVersionStr)
        : null;

    final releaseDateStr = argResults?['release-date'] as String?;

    releaseDate ??= releaseDateStr != null
        ? DateTime.parse(releaseDateStr)
        : null;

    // Revert the escapes and links a previous cider run has left behind.
    // Otherwise cider does not recognize headlines like »## \[1.1.3\] - ...«
    // as a release and releases into the wrong section.
    await unescapeChangelogInDirectory(directory);
    await removeChangelogLinksInDirectory(directory);

    final cider = await _ciderProject.get(directory: directory);

    // Take the version from pubspec.yaml when it is not given
    releaseVersion ??= await cider.getVersion();

    // Releasing a version a second time would make cider throw
    // »Bad state: Release 1.2.3 already exists«. Nothing needs to be done
    // because the version is already in CHANGELOG.md.
    if (await _isAlreadyReleased(cider, releaseVersion)) {
      ggLog.call(
        darkGray('The version »$releaseVersion« is already in CHANGELOG.md'),
      );
      return;
    }

    // Use cider to write into CHANGELOG.md
    await cider.release(releaseDate ?? DateTime.now(), version: releaseVersion);

    // Revert the markdown escapes cider added while rewriting the changelog
    await unescapeChangelogInDirectory(directory);

    // Remove the repository links cider took over from previous releases
    await removeChangelogLinksInDirectory(directory);

    // Pretty print the changelog
    await prettyPrintChangelogInDirectory(directory);
  }

  // ######################
  // Private
  // ######################

  final CiderProject _ciderProject;

  // ...........................................................................
  /// Returns true when [version] already has a section in CHANGELOG.md
  Future<bool> _isAlreadyReleased(Project cider, Version version) async {
    // Yanked versions are part of the change log as well. Cider would throw
    // for them too. Thus they need to be taken into account here.
    final releasedVersions = await cider.getAllVersions(includeYanked: true);

    // Cider trims and lowercases versions before comparing them. Do the same.
    final searched = version.toString().trim().toLowerCase();
    return releasedVersions.any((e) => e.trim().toLowerCase() == searched);
  }

  // ...........................................................................
  void _addParam() {
    argParser.addOption(
      'release-version',
      abbr: 'r',
      help: 'The release version. Taken from pubspec.yaml if not provided.',
      mandatory: false,
    );

    argParser.addOption(
      'release-date',
      abbr: 'd',
      help: 'The release date. Today by default.',
      mandatory: false,
    );
  }
}

/// Mock for [Release]
class MockRelease extends MockDirCommand<void> implements Release {}
