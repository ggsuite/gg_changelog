// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_changelog/src/tools/repo_url.dart';

import 'package:gg_log/gg_log.dart';

// #############################################################################
/// An example command
class GithubDiffTemplate extends DirCommand<String> {
  /// Constructor
  GithubDiffTemplate({
    required super.ggLog,
    super.name = 'github-diff-template',
    super.description =
        'Reads repository URL from pubspec.yaml and '
        'returns the cider diff template',
    RepoUrl? repoUrl,
  }) : _repoUrl = repoUrl ?? const RepoUrl();

  // ...........................................................................
  @override
  Future<String> exec({
    required Directory directory,
    required GgLog ggLog,
    Map<String, dynamic> options = const {},
  }) async {
    // Does the directory exist?
    await check(directory: directory);
    final result = await get(directory: directory, ggLog: ggLog);
    ggLog(result);
    return result;
  }

  // ...........................................................................
  /// Reads repo URL from pubspec.yaml and returns the cider diff template'
  @override
  Future<String> get({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final repoUrl = await _repoUrl.get(directory: directory);
    final repoUrlWithoutGit = repoUrl.replaceAll(RegExp(r'\.git$'), '');

    return '$repoUrlWithoutGit/compare/%from%...%to%';
  }

  // ######################
  // Private
  // ######################

  final RepoUrl _repoUrl;
}

/// Mock for [GitHubDiffTemplate]
class MockGitHubDiffTemplate extends MockDirCommand<String>
    implements GithubDiffTemplate {}
