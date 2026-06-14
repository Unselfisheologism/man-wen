import 'package:flutter/material.dart';

/// A book in the Man Wen self-help bookshelf.
///
/// Each book is a PDF asset bundled with the app. Books are immutable
/// metadata — the actual document is loaded on demand from
/// [BookshelfService.loadBookPdf] and the per-book reading position
/// (last page number) lives in [SharedPreferences].
class Book {
  /// Unique stable ID — used as the SharedPreferences key for reading
  /// position. Don't change for existing books; new books get new IDs.
  final String id;

  /// Display title.
  final String title;

  /// Author name.
  final String author;

  /// Original publication year (or circa for ancient works).
  final int year;

  /// Path under the bundled `assets/` tree. Loaded via
  /// `rootBundle.loadString(assetPath)`.
  final String assetPath;

  /// Short editorial blurb shown on the book card.
  final String blurb;

  /// One-line theme — e.g. "STOICISM" / "SELF-MASTERY" / "FOCUS".
  /// Rendered in the mono label slot on the card.
  final String theme;

  /// Category color used for the book card on the bookshelf. Picked
  /// from the existing Man Wen palette (catBlocker / catUrge /
  /// catAccount / catSetting / catStats / catBook). A book card's
  /// color IS its identity on the grid — the same way the home
  /// action cards work.
  final Color color;

  /// Total page count. Defaults to 0 in the static catalog; updated
  /// at load time once the [PdfDocument] is opened.
  final int pageCount;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.year,
    required this.assetPath,
    required this.blurb,
    required this.theme,
    required this.color,
    this.pageCount = 0,
  });

  /// Estimated reading time in minutes at ~250 words/page and
  /// 220 words/minute. Returns 0 when [pageCount] isn't set yet.
  int get estimatedMinutes => (pageCount * 250 / 220).round();
}
