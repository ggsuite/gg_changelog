// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_changelog/gg_changelog.dart';
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
  }) : _ciderProject = ciderProject ?? CiderProject(ggLog: ggLog) {
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

    // Use cider to write into CHANGELOG.md
    final cider = await _ciderProject.get(directory: directory, ggLog: ggLog);
    await cider.release(releaseDate ?? DateTime.now(), version: releaseVersion);

    // Pretty print the changelog
    await prettyPrintChangelogInDirectory(directory);
  }

  // ######################
  // Private
  // ######################

  final CiderProject _ciderProject;

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
