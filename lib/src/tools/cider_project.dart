// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:cider/cider.dart';

// ignore: implementation_imports
import 'package:cider/src/cli/config.dart';
import 'package:mocktail/mocktail.dart';

/// Creates a cider project
class CiderProject {
  /// Constructor
  const CiderProject();

  // ...........................................................................
  /// Creates and returns a cider [Project]
  ///
  /// No link templates are handed over to cider. Thus cider does not write
  /// repository links like
  /// »[1.0.1]: https://github.com/org/repo/compare/1.0.0...1.0.1«
  /// into CHANGELOG.md.
  Future<Project> get({required Directory directory}) async =>
      Project(directory.path, Config());
}

/// Mock for [CiderProject]
class MockCiderProject extends Mock implements CiderProject {}
