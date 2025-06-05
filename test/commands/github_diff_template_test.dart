// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_changelog/gg_changelog.dart';
import 'package:test/test.dart';

import '../pubspec_yaml.dart';

void main() {
  final messages = <String>[];
  final ggLog = messages.add;
  late Directory d;
  late GithubDiffTemplate githubDiffTemplate;

  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    final pubspecFile = File('${d.path}/pubspec.yaml');
    await pubspecFile.writeAsString(pubspecExample);
    githubDiffTemplate = GithubDiffTemplate(ggLog: ggLog);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('GithubDiffTemplate', () {
    group('exec(directory, ggLog)', () {
      test('should log and return the template', () async {
        // Exec command
        final result = await githubDiffTemplate.exec(
          directory: d,
          ggLog: ggLog,
        );

        // Check result
        expect(
          result,
          'https://github.com/inlavigo/gg_changelog/compare/%from%...%to%',
        );
      });
    });
  });
}
