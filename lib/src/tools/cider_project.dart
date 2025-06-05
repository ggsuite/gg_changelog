// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:cider/cider.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:gg_log/gg_log.dart';

// ignore: implementation_imports
import 'package:cider/src/cli/config.dart';
import 'package:mocktail/mocktail.dart';

/// Creates a cider project
class CiderProject {
  /// Constructor
  CiderProject({
    required GgLog ggLog,
    GithubDiffTemplate? githubDiffTemplate,
    GithubTagTemplate? githubTagTemplate,
  }) : _githubDiffTemplate =
           githubDiffTemplate ?? GithubDiffTemplate(ggLog: ggLog),
       _githubTagTemplate =
           githubTagTemplate ?? GithubTagTemplate(ggLog: ggLog);

  // ...........................................................................
  /// Creates and returns a cider [Project]
  Future<Project> get({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final diffTemplate = await _githubDiffTemplate.exec(
      directory: directory,
      ggLog: (_) {}, // coverage:ignore-line
    );

    final tagTemplate = await _githubTagTemplate.exec(
      directory: directory,
      ggLog: (_) {}, // coverage:ignore-line
    );

    final result = Project(
      directory.path,
      Config(diffTemplate: diffTemplate, tagTemplate: tagTemplate),
    );

    return result;
  }

  // ...........................................................................
  final GithubDiffTemplate _githubDiffTemplate;
  final GithubTagTemplate _githubTagTemplate;
}

/// Mock for [CiderProject]
class MockCiderProject extends Mock implements CiderProject {}
