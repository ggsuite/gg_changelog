// @license
// Copyright (c) ggsuite
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
  }) : _ciderProject = ciderProject ?? const CiderProject() {
    _addParam();
  }

  // ...........................................................................
  /// Throws if the existing change log has not the right format
  @override
  Future<bool> exec({
    required Directory directory,
    required GgLog ggLog,
    Map<String, dynamic> options = const {},
  }) async {
    // Does the directory exist?
    await check(directory: directory);
    final errors = <String>[];

    final printer = GgStatusPrinter<bool>(
      message: 'CHANGELOG.md has right format',
      ggLog: ggLog,
      dark: true,
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
    // The cider-based CHANGELOG validation only applies to Dart/Flutter
    // packages (cider requires a pubspec.yaml). Project types without a
    // pubspec.yaml — e.g. TypeScript — use a registry/manifest based
    // versioning flow and have no CHANGELOG.md to validate here, so the
    // check is skipped.
    final pubspec = File('${directory.path}/pubspec.yaml');
    if (!pubspec.existsSync()) {
      return true;
    }

    final cider = await _ciderProject.get(directory: directory);
    try {
      await cider.getAllVersions();
      return true;
    } on FormatException catch (e) {
      // Show the expected structure instead of the bare parser error. The
      // example release takes the version of the broken headline, or the
      // pubspec.yaml version when the headline carries none.
      final version =
          _version.firstMatch(e.message)?[0] ??
          (await cider.getVersion()).toString();
      ggLog.call(wrongFormatMessage(version: version, date: DateTime.now()));
      return false;
    }
  }

  // ...........................................................................
  /// Tells the user how CHANGELOG.md must be structured, with an example
  /// release of [version] on [date].
  static String wrongFormatMessage({
    required String version,
    required DateTime date,
  }) {
    final day = date.toIso8601String().substring(0, 10);
    return [
      'Please open CHANGELOG.md.',
      'Ensure the following structure:',
      '',
      '# CHANGELOG',
      '',
      '## Unreleased',
      '',
      '## $version - $day',
    ].join('\n');
  }

  // ######################
  // Private
  // ######################

  final CiderProject _ciderProject;

  /// Matches the version in cider's »Invalid release header format« error.
  static final _version = RegExp(r'\d+\.\d+\.\d+[^\s"\]\\]*');

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
