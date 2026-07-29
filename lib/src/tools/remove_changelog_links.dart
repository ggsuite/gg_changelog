// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

// Matches link definitions like
// »[1.0.1]: https://github.com/org/repo/compare/1.0.0...1.0.1«
final _linkDefinition = RegExp(r'^\[[^\]]+\]:\s*\S+$');

// Matches linked headlines like »## [1.0.1] - 2024-04-05«
final _linkedHeadline = RegExp(r'^(#{1,6}\s+)\[([^\]]+)\](?:\([^)]*\))?');

// .............................................................................
/// Removes the repository links from the [changelog]
///
/// Deletes the link definitions at the end of the change log and turns linked
/// headlines like »## [1.0.1] - 2024-04-05« into »## 1.0.1 - 2024-04-05«.
String removeChangelogLinks(String changelog) {
  final result = <String>[];

  for (final line in changelog.split('\n')) {
    // Drop link definitions
    if (_linkDefinition.hasMatch(line.trim())) {
      continue;
    }

    // Remove the link from linked headlines
    result.add(
      line.replaceFirstMapped(
        _linkedHeadline,
        (match) => '${match[1]}${match[2]}',
      ),
    );
  }

  // Remove the empty lines the deleted link definitions left behind
  while (result.isNotEmpty && result.last.trim().isEmpty) {
    result.removeLast();
  }

  return result.isEmpty ? '' : '${result.join('\n')}\n';
}

// .............................................................................
/// Removes the repository links from the change log in the given directory
Future<void> removeChangelogLinksInDirectory(Directory directory) async {
  final changelogFile = File('${directory.path}/CHANGELOG.md');
  final changelog = await changelogFile.readAsString();
  await changelogFile.writeAsString(removeChangelogLinks(changelog));
}
