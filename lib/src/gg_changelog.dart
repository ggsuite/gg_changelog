// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:gg_log/gg_log.dart';

/// The command line interface for GgChangelog
class GgChangelog extends Command<dynamic> {
  /// Constructor
  GgChangelog({required this.ggLog}) {
    addSubcommand(Add(ggLog: ggLog));
    addSubcommand(GithubDiffTemplate(ggLog: ggLog));
    addSubcommand(GithubTagTemplate(ggLog: ggLog));
    addSubcommand(HasRightFormat(ggLog: ggLog));
    addSubcommand(HasVersion(ggLog: ggLog));
    addSubcommand(Release(ggLog: ggLog));
    addSubcommand(Sort(ggLog: ggLog));
  }

  /// The log function
  final GgLog ggLog;

  // ...........................................................................
  @override
  final name = 'changelog';
  @override
  final description =
      'various tools to manipulate dart CHANGELOG.md files. '
      'Based on cider package.';
}
