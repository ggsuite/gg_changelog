// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:test/test.dart';

import '../../bin/gg_changelog.dart';

void main() {
  group('bin/gg_changelog.dart', () {
    // #########################################################################

    test('should be executable', () async {
      // Execute bin/gg_changelog.dart and check if it prints help
      final result = await Process.run(
        'dart',
        ['./bin/gg_changelog.dart', '--help'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      final stdout = result.stdout as String;
      expect(stdout, contains('has-right-format'));
    });
  });

  // ###########################################################################
  group('run(args, log)', () {
    group('with args=[--param, value]', () {
      test('should print "value"', () async {
        // Execute bin/gg_changelog.dart and check if it prints "value"
        final messages = <String>[];
        await capturePrint(
          ggLog: messages.add,
          code: () => run(args: ['--help'], ggLog: messages.add),
        );

        expect(messages[0], contains('has-right-format'));
      });
    });
  });
}
