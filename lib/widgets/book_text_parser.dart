import 'package:flutter/foundation.dart';

/// One block of rendered book text — either a chapter heading or
/// a regular paragraph. Spacers are inter-block gaps (preserved
/// blank lines from the source).
enum BlockKind { chapter, paragraph, spacer }

@immutable
class TextBlock {
  final BlockKind kind;
  final String text;
  const TextBlock(this.kind, this.text);
}

/// Parses a book's raw text into renderable blocks.
///
/// Plain-text books (as bundled in `assets/books/*.txt`) are a flat
/// string with paragraphs separated by blank lines. To make them
/// look like a real book, we detect chapter headings — short lines
/// that are mostly uppercase, or that match a few common patterns
/// (e.g. "Chapter 1", "BOOK I", "THE FIRST BOOK") — and pull them
/// out as their own block type so the reader can render them as
/// big editorial chapter headers instead of as body text.
///
/// The detection is intentionally a bit conservative: false negatives
/// just mean a heading renders as a normal paragraph, but false
/// positives would chunk the book into a confusing series of
/// chapter blocks. We err on the side of fewer, more confident
/// chapter blocks.
class BookTextParser {
  BookTextParser._();

  // A line that's ALL CAPS, has 2+ words, is under 80 chars, and
  // doesn't end in punctuation that's typical for sentences
  // (period, exclamation, question mark, closing paren) is treated
  // as a chapter heading.
  static final RegExp _chapterLikeAllCaps = RegExp(
    r'^[\sA-Z0-9IVXLCDM\-\.&:\'"]+$',
  );

  // Patterns we explicitly recognise as chapter-style headings,
  // even if they don't fit the all-caps heuristic. E.g. "Chapter 1"
  // or "Chapter XII" or "Book III".
  static final RegExp _chapterPattern = RegExp(
    r'^\s*('
    r'chapter\s+[0-9ivxlcdm]+'
    r'|book\s+[0-9ivxlcdm]+'
    r'|part\s+[0-9ivxlcdm]+'
    r'|section\s+[0-9ivxlcdm]+'
    r'|episode\s+[0-9]+'
    r')\b',
    caseSensitive: false,
  );

  /// Decide whether a single section (a block of consecutive
  /// non-blank lines) is a chapter heading or body text.
  static BlockKind classifySection(String section) {
    final s = section.trim();
    if (s.isEmpty) return BlockKind.spacer;
    if (s.contains('\n')) {
      // Multi-line sections are always body text.
      return BlockKind.paragraph;
    }
    // Single-line sections: check for chapter-like patterns.
    if (_chapterPattern.hasMatch(s)) {
      return BlockKind.chapter;
    }
    // All-caps check: must be 2+ words, <= 80 chars, all caps, and
    // contain at least one letter.
    if (s.length <= 80 &&
        s.split(RegExp(r'\s+')).length >= 2 &&
        _chapterLikeAllCaps.hasMatch(s) &&
        RegExp(r'[A-Z]').hasMatch(s)) {
      return BlockKind.chapter;
    }
    return BlockKind.paragraph;
  }

  /// Parse a raw text string into a list of [TextBlock]s. The text
  /// is split by blank lines; each resulting section is classified
  /// as chapter / paragraph / spacer.
  static List<TextBlock> parse(String text) {
    final out = <TextBlock>[];

    // Normalize line endings and split on blank lines.
    final normalized = text.replaceAll('\r\n', '\n');
    final sections = normalized.split(RegExp(r'\n\s*\n+'));

    for (final raw in sections) {
      final section = raw.trim();
      if (section.isEmpty) {
        out.add(const TextBlock(BlockKind.spacer, ''));
        continue;
      }
      final kind = classifySection(section);
      out.add(TextBlock(kind, section));
    }
    return out;
  }
}
