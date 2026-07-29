// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

// Matches code spans and fenced code blocks like »`gg_install_gg`«.
// Cider does not escape anything in there, so a »\_« found inside is a literal
// backslash the author wrote and must be kept.
final _codeSpan = RegExp('`+[^`]*`+');

// Matches the escapes cider writes in front of »*«, »_«, »~«, »|«, »[« and »]«.
//
// The escapes cider puts in front of »#«, »-«, »+« and »1.« at the beginning of
// a line are not matched on purpose: those characters would start a headline or
// a list item and therefore have to stay escaped.
final _escapedSpecialChar = RegExp(r'\\([*_~|\[\]])');

// .............................................................................
/// Reverts the markdown escapes cider added to the [changelog]
///
/// Cider rewrites the whole CHANGELOG.md on every change. While doing so it
/// escapes »*«, »_«, »~«, »|«, »[« and »]«, turning »gg_install_gg« into
/// »gg\_install\_gg«. The escapes are not needed and, in case of »[« and »]«,
/// even harmful: an escaped headline like »## \[1.1.3\] - 2025-08-08« is no
/// longer recognized as a release. Code spans are left untouched.
String unescapeChangelog(String changelog) {
  final result = StringBuffer();
  var start = 0;

  for (final codeSpan in _codeSpan.allMatches(changelog)) {
    result.write(_unescape(changelog.substring(start, codeSpan.start)));
    result.write(codeSpan[0]);
    start = codeSpan.end;
  }

  result.write(_unescape(changelog.substring(start)));

  return result.toString();
}

// .............................................................................
/// Reverts the markdown escapes in the change log in the given directory
Future<void> unescapeChangelogInDirectory(Directory directory) async {
  final changelogFile = File('${directory.path}/CHANGELOG.md');
  final changelog = await changelogFile.readAsString();
  await changelogFile.writeAsString(unescapeChangelog(changelog));
}

// ######################
// Private
// ######################

String _unescape(String part) =>
    part.replaceAllMapped(_escapedSpecialChar, (match) => match[1]!);
