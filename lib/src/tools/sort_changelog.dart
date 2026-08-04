// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

// Matches version headlines like »## 1.0.1 - 2024-04-05« as well as their
// bracketed »## [1.0.1] - …«, escaped »## \[1.0.1\] - …« and linked
// »## [1.0.1](https://…) - …« variants.
final _versionHeadline = RegExp(r'^##\s+\\?\[?([^\]\s\\]+)');

// Matches unreleased headlines like »## Unreleased«, »## [Unreleased]« and
// »## \[Unreleased\]«
final _unreleasedHeadline = RegExp(
  r'^##\s+\\?\[?unreleased',
  caseSensitive: false,
);

// .............................................................................
/// Returns the version of a changelog headline like »## 1.0.1 - 2024-04-05«
///
/// Returns null when [line] is no headline or its headline carries no
/// parseable version.
Version? versionInChangelogHeadline(String line) {
  final match = _versionHeadline.firstMatch(line);
  if (match == null) {
    return null;
  }

  try {
    return Version.parse(match[1]!);
  } on FormatException {
    return null;
  }
}

// .............................................................................
/// Returns true when [line] is an unreleased headline like »## Unreleased«
bool isUnreleasedChangelogHeadline(String line) =>
    _unreleasedHeadline.hasMatch(line);

// .............................................................................
/// Sorts the version sections of the [changelog] by version. Newest first.
///
/// Git merges can leave the sections of a change log in the wrong order.
/// Sorting them strictly by version number neutralizes such merge artifacts.
/// The header and the »## Unreleased« sections stay at the top. Sections
/// carrying the same version keep their original relative order.
String sortChangelog(String changelog) {
  final header = <String>[];
  final unreleasedBlocks = <List<String>>[];
  final versionBlocks = <({Version version, List<String> lines})>[];

  // Split the changelog into the header and its »## « blocks. Headlines that
  // carry neither a version nor »Unreleased« do not start a block — they stay
  // attached to the block they are in, so no content moves across sections.
  List<String>? currentBlock;
  for (final line in changelog.split('\n')) {
    if (isUnreleasedChangelogHeadline(line)) {
      currentBlock = [line];
      unreleasedBlocks.add(currentBlock);
      continue;
    }

    final version = versionInChangelogHeadline(line);
    if (version != null) {
      currentBlock = [line];
      versionBlocks.add((version: version, lines: currentBlock));
      continue;
    }

    (currentBlock ?? header).add(line);
  }

  // Not a changelog? Return the input unchanged.
  if (unreleasedBlocks.isEmpty && versionBlocks.isEmpty) {
    return changelog;
  }

  // Sort the version blocks by version. Newest first. Blocks with the same
  // version keep their original relative order. (List.sort is not stable,
  // therefore the original index breaks ties.)
  final indexedBlocks = versionBlocks.indexed.toList();
  indexedBlocks.sort((a, b) {
    final byVersion = b.$2.version.compareTo(a.$2.version);
    return byVersion != 0 ? byVersion : a.$1.compareTo(b.$1);
  });

  // Reassemble the changelog: header first, then the unreleased sections,
  // then the sorted version sections — separated by one empty line.
  final parts = [
    header,
    ...unreleasedBlocks,
    ...indexedBlocks.map((e) => e.$2.lines),
  ].map(_withoutTrailingEmptyLines).where((e) => e.isNotEmpty);

  return '${parts.map((e) => e.join('\n')).join('\n\n')}\n';
}

// .............................................................................
/// Sorts the versions of the change log in the given directory. Newest first.
Future<void> sortChangelogInDirectory(Directory directory) async {
  final changelogFile = File('${directory.path}/CHANGELOG.md');
  final changelog = await changelogFile.readAsString();
  await changelogFile.writeAsString(sortChangelog(changelog));
}

// ######################
// Private
// ######################

// .............................................................................
List<String> _withoutTrailingEmptyLines(List<String> lines) {
  final result = [...lines];
  while (result.isNotEmpty && result.last.trim().isEmpty) {
    result.removeLast();
  }
  return result;
}
