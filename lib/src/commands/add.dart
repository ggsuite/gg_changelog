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

// #############################################################################

/// The type of the commit message.
enum LogType {
  /// Added a new feature.
  added,

  /// Changed something.
  changed,

  /// Deprecated something.
  deprecated,

  /// Fixed a bug.
  fixed,

  /// Removed something.
  removed,

  /// Fixed a security issue.
  security,
}

final _logTypes = LogType.values.map((e) => e.name);

// #############################################################################
/// An example command
class Add extends DirCommand<bool> {
  /// Constructor
  Add({
    required super.ggLog,
    super.name = 'add',
    super.description = 'Adds a message to the change log.',
    CiderProject? ciderProject,
  }) : _ciderProject = ciderProject ?? const CiderProject() {
    _addParam();
  }

  // ...........................................................................
  /// Returns true if a message was added to the change log.
  @override
  Future<bool> exec({
    required Directory directory,
    required GgLog ggLog,
    String? message,
    LogType? logType,
    Map<String, dynamic> options = const {},
  }) => get(
    directory: directory,
    ggLog: ggLog,
    message: message,
    logType: logType,
  );

  // ...........................................................................
  /// Returns true if a message was added to the change log.
  @override
  Future<bool> get({
    required Directory directory,
    required GgLog ggLog,
    String? message,
    LogType? logType,
  }) async {
    // Does the directory exist?
    await check(directory: directory);

    // Check needed options
    message ??= _messageFromArgs();
    logType ??= _logTypeFromArgs();

    // Create CHANGELOG.md if it does not exist
    final changelogFile = File('${directory.path}/CHANGELOG.md');
    if (!await changelogFile.exists()) {
      await changelogFile.create();
      await changelogFile.writeAsString('# Changelog\n\n');
    }

    // Revert the escapes and links a previous cider run has left behind.
    // Otherwise cider does not recognize headlines like »## \[1.1.3\] - ...«
    // as a release and inserts the new message at the wrong place.
    await unescapeChangelogInDirectory(directory);
    await removeChangelogLinksInDirectory(directory);

    // Read CHANGELOG.md
    final changelog = await changelogFile.readAsString();

    if (_unreleasedSectionContainsMessage(changelog, message)) {
      ggLog.call(darkGray('The message »message« is already in CHANGELOG.md'));
      return false;
    }

    final cider = await _ciderProject.get(directory: directory);
    await cider.addUnreleased(logType.name, message);

    // Revert the markdown escapes cider added while rewriting the changelog
    await unescapeChangelogInDirectory(directory);

    // Remove the repository links cider took over from previous releases
    await removeChangelogLinksInDirectory(directory);

    // Pretty print the changelog
    await prettyPrintChangelogInDirectory(directory);

    return true;
  }

  // ######################
  // Private
  // ######################

  final CiderProject _ciderProject;

  // ...........................................................................
  void _addParam() {
    argParser.addOption(
      'message',
      abbr: 'm',
      help: 'The message for the commit.',
      mandatory: true,
    );

    argParser.addOption(
      'log-type',
      abbr: 'l',
      help: 'The type of the commit.',
      mandatory: true,
      allowed: _logTypes,
    );
  }

  // ...........................................................................
  String _messageFromArgs() {
    try {
      final message = argResults!['message'] as String;
      return message;
    } catch (e) {
      throw Exception(yellow('Run again with ') + blue('-m "yourMessage"'));
    }
  }

  // ...........................................................................
  LogType _logTypeFromArgs() {
    try {
      final logTypeString = argResults!['log-type'] as String;
      return LogType.values.firstWhere(
        (element) => element.name == logTypeString,
      );
    } catch (e) {
      throw Exception(
        yellow('Run again with ') + blue('-l ${_logTypes.join(' | ')}'),
      );
    }
  }

  // ...........................................................................
  bool _unreleasedSectionContainsMessage(String changeLog, String message) {
    final parts = changeLog.split('## ');
    if (parts.length <= 1) {
      return false;
    }

    final indexOfUnreleased = parts.indexWhere(
      (element) => element.contains('Unreleased'),
    );

    if (indexOfUnreleased < 0) {
      return false;
    }

    if (parts.length > indexOfUnreleased + 1) {
      return parts[indexOfUnreleased + 1].contains(message);
    }

    return false;
  }
}

// .............................................................................
/// Mock for [Add]
class MockAdd extends MockDirCommand<bool> implements Add {}
