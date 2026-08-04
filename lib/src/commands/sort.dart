// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:gg_log/gg_log.dart';

/// Sorts the versions in CHANGELOG.md. Newest first.
class Sort extends DirCommand<void> {
  /// Constructor
  Sort({
    required super.ggLog,
    super.name = 'sort',
    super.description = 'Sorts the versions in CHANGELOG.md. Newest first.',
  });

  // ...........................................................................
  /// Sorts the versions of the change log in [directory]. Newest first.
  @override
  Future<void> get({required Directory directory, required GgLog ggLog}) async {
    // Does the directory exist?
    await check(directory: directory);

    // Throw if CHANGELOG.md does not exist
    final changelogFile = File('${directory.path}/CHANGELOG.md');
    if (!await changelogFile.exists()) {
      throw Exception('CHANGELOG.md does not exist');
    }

    await sortChangelogInDirectory(directory);
  }
}

// .............................................................................
/// Mock for [Sort]
class MockSort extends MockDirCommand<void> implements Sort {}
