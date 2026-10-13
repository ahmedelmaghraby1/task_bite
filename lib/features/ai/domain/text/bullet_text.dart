/// Text shaping for task descriptions.
///
/// The product requires the generated description to be actionable bullet
/// points rather than one long paragraph. The AI is prompted to return bullets,
/// but provider output is not trusted blindly: [normalizeToBulletPoints]
/// converts a paragraph into bullets and canonicalizes existing bullet markers,
/// while never dropping the user's words.
library;

final RegExp _bulletMarker = RegExp(r'^[-*\u2022]\s+');
final RegExp _lineBreak = RegExp(r'\r\n|\r|\n');
final RegExp _segmentSeparators = RegExp(
  r'[\n.!?\u061f\u06d4\u061b;\u2026]+|,\s+',
);
final RegExp _leadingConjunction = RegExp(
  r'^(?:and|then|also|plus)\s+',
  caseSensitive: false,
);

/// Converts free text into a `- ` prefixed bullet list.
///
/// Splits on line breaks, sentence terminators, semicolons and commas, drops
/// empty fragments and leading coordinating conjunctions, and trims trailing
/// punctuation. Returns `''` for blank input.
String toBulletPoints(String text) {
  final segments = text.split(_segmentSeparators);
  final bullets = <String>[];
  for (final raw in segments) {
    var line = raw.trim();
    if (line.isEmpty) continue;
    line = line.replaceFirst(_leadingConjunction, '').trim();
    line = line.replaceFirst(_leadingConjunction, '').trim();
    line =
        line.replaceFirst(RegExp(r'[.!?\u061f\u06d4\u061b;,.]+$'), '').trim();
    if (line.isEmpty) continue;
    final lower = line.toLowerCase();
    if (lower == 'and' ||
        lower == 'also' ||
        lower == 'then' ||
        lower == 'plus') {
      continue;
    }
    bullets.add('- $line');
  }
  return bullets.join('\n');
}

/// Normalizes [raw] into bullets.
///
/// * Already-bulleted text keeps its structure; markers are canonicalized to
///   `- ` and non-bulleted lines inside a bulleted block become their own item.
/// * Prose is split into bullets with [toBulletPoints].
/// * Blank input returns `''`.
String normalizeToBulletPoints(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  final lines =
      trimmed
          .split(_lineBreak)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
  final hasBullets = lines.any((line) => _bulletMarker.hasMatch(line));

  if (!hasBullets) return toBulletPoints(trimmed);

  final bullets = <String>[];
  for (final line in lines) {
    final match = _bulletMarker.firstMatch(line);
    final content = (match == null ? line : line.substring(match.end)).trim();
    if (content.isEmpty) continue;
    bullets.add('- $content');
  }
  return bullets.join('\n');
}
