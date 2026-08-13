// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_changelog/gg_changelog.dart';
import 'package:test/test.dart';

import '../pubspec_yaml.dart';

void main() {
  late Directory d;
  late File pubspecFile;
  const repoUrl = RepoUrl();

  setUp(() async {
    d = await Directory.systemTemp.createTemp();
    pubspecFile = File('${d.path}/pubspec.yaml');
    await pubspecFile.writeAsString(pubspecExample);
  });

  group('RepoUrl', () {
    group('get', () {
      group('should throw', () {
        test('when no repository entry is found in pubspec.yaml', () async {
          // Remove repository entry
          final pubspec = pubspecExample.replaceAll(
            RegExp(r'^repository:\s*(.+)$', multiLine: true),
            '',
          );
          await pubspecFile.writeAsString(pubspec);

          // Exec command
          late String exception;

          try {
            await repoUrl.get(directory: d);
          } catch (e) {
            exception = e.toString();
          }

          // Check exception
          expect(exception, contains('No »repository:« found in pubspec.yaml'));
        });
      });

      group('should succeed', () {
        group('and return the repo url', () {
          test('when the repository entry is found in pubspec.yaml', () async {
            // Exec command
            final url = await repoUrl.get(directory: d);

            // Check result
            expect(url, 'https://github.com/inlavigo/gg_changelog.git');
          });
        });
      });
    });
  });
}
