// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

/// Adds linebreaks to make the changelog compatible to Vscode
String prettyCiderChangelog(String changelog) {
  final lines0 = changelog.split('\n').map((e) => e.trim()).toList();

  // ...........................................................................
  final lines1 = <String>[];
  var i = 0;

  // Add lines after
  for (final line in lines0) {
    if (!line.startsWith('#')) {
      lines1.add(line);
    } else {
      // Is last line?
      final isLastLine = i == lines0.length - 1;

      // Add line
      lines1.add(line);

      // Is headline followed by an empty line?
      final isFollowedByEmptyLine = isLastLine || lines0[i + 1].isEmpty;
      if (!isFollowedByEmptyLine) {
        lines1.add('');
      }
    }

    i++;
  }

  // ...........................................................................
  final lines2 = <String>[];
  i = 0;

  // Add lines before
  for (final line in lines1) {
    if (!line.startsWith('#')) {
      lines2.add(line);
    } else {
      // Is first line?
      final isFirstLine = i == 0;

      // Is headline preceeded by an empty line?
      final isPreceededByEmptyLine = isFirstLine || lines1[i - 1].isEmpty;

      // No? Add an empty line
      if (!isPreceededByEmptyLine) {
        lines2.add('');
      }

      // Add line
      lines2.add(line);
    }

    i++;
  }

  // .......................................
  // Is last line followed by an empty line?
  if (lines2.last.isNotEmpty) {
    lines2.add('');
  }

  return lines2.join('\n');
}

/// Pretty prints the changelog in the given directory
Future<void> prettyPrintChangelogInDirectory(Directory directory) async {
  final changelog2File = File('${directory.path}/CHANGELOG.md');
  final changelog2 = await changelog2File.readAsString();
  await changelog2File.writeAsString(prettyCiderChangelog(changelog2));
}
