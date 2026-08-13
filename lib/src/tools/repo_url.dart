// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:mocktail/mocktail.dart';

/// Returns the repository URL from the pubspec.yaml file
class RepoUrl {
  /// Constructor
  const RepoUrl();

  /// The repository URL
  Future<String> get({required Directory directory}) async {
    final pubspec = await File('${directory.path}/pubspec.yaml').readAsString();
    RegExp regExp = RegExp(r'^\s*repository:\s*(.+)$', multiLine: true);
    Match? match = regExp.firstMatch(pubspec);
    String? repositoryUrl = match?.group(1)?.replaceAll(RegExp(r'/$'), '');
    if (repositoryUrl == null) {
      throw Exception('No »repository:« found in pubspec.yaml');
    }
    return repositoryUrl;
  }
}

/// Mock for [RepoUrl]
class MockRepoUrl extends Mock implements RepoUrl {}
