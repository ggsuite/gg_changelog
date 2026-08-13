// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_changelog/gg_changelog.dart';
import 'package:test/test.dart';
import 'package:gg_args/gg_args.dart';

void main() {
  final messages = <String>[];

  setUp(() {
    messages.clear();
  });

  group('GgChangelog()', () {
    // #########################################################################
    group('GgChangelog', () {
      final ggChangelog = GgChangelog(ggLog: messages.add);

      // .......................................................................
      test('should show all sub commands', () async {
        final (subCommands, errorMessage) = await missingSubCommands(
          directory: Directory('lib/src/commands'),
          command: ggChangelog,
        );

        expect(subCommands, isEmpty, reason: errorMessage);
      });
    });
  });
}
