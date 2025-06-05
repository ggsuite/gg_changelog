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
import 'package:gg_status_printer/gg_status_printer.dart';
import 'package:mocktail/mocktail.dart';

/// Checks if the change log has the right format.
class HasRightFormat extends DirCommand<bool> {
  /// Constructor
  HasRightFormat({
    required super.ggLog,
    super.name = 'has-right-format',
    super.description = 'HasRightformats the current change log.',
    CiderProject? ciderProject,
  }) : _ciderProject = ciderProject ?? CiderProject(ggLog: ggLog) {
    _addParam();
  }

  // ...........................................................................
  /// Throws if the existing change log has not the right format
  @override
  Future<bool> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    // Does the directory exist?
    await check(directory: directory);
    final errors = <String>[];

    final printer = GgStatusPrinter<bool>(
      message: 'CHANGELOG.md has right format',
      ggLog: ggLog,
    );

    final result = await printer.logTask(
      success: (ok) => ok,
      task: () => get(directory: directory, ggLog: errors.add),
    );

    if (!result) {
      throw Exception(darkGray(errors.join('\n')));
    }

    return result;
  }

  // ...........................................................................
  /// Returns true if CHANGELOG.md has the right format
  @override
  Future<bool> get({required Directory directory, required GgLog ggLog}) async {
    final cider = await _ciderProject.get(directory: directory, ggLog: (_) {});
    try {
      await cider.getAllVersions();
      return true;
    } on FormatException catch (e) {
      ggLog.call(e.message);
      return false;
    }
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
  }
}

// .............................................................................
/// Mock for [HasRightFormat]
class MockHasRightFormat extends Mock implements HasRightFormat {}
