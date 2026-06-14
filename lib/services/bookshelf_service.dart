import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf_render/pdf_render.dart' as pdf;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';

/// Self-help bookshelf — static catalog of bundled PDF books + page-level
/// reading-position persistence via SharedPreferences.
///
/// All books are bundled in `assets/books/*.pdf` so the app works offline
/// with zero network dependency. To add a new book:
///   1. Drop a text-based PDF into `assets/books/`
///   2. Add a [Book] entry to [catalog] below
///   3. Rebuild
///
/// Why PDFs (vs plain text like the v1 reader): books-as-text loses all
/// the editorial formatting — chapter breaks, italics for emphasis,
/// drop caps, the visual rhythm a real book has. We use the `pdf_render`
/// FFI plugin (PDFium under the hood) to render each page to an image
/// lazily, so a 200-page book doesn't lock the UI at open.
class BookshelfService {
  BookshelfService._();

  /// The Man Wen bookshelf — 6 public-domain / freely-shared self-help
  /// classics, bundled as PDFs. Order is editorial: foundational mind /
  /// discipline books first (Allen, Aurelius, Emerson), then the
  /// action-oriented titles (Goggins, Bennett), then the inner-work
  /// titles (Allen, Gibran). Books are picked for direct relevance to
  /// self-mastery and resilience.
  ///
  /// Colors are picked from the existing Man Wen palette so each book
  /// card reads as a different color block in the same editorial
  /// register as the home action cards.
  static const List<Book> catalog = [
    Book(
      id: 'as_a_man_thinketh',
      title: 'As a Man Thinketh',
      author: 'James Allen',
      year: 1903,
      assetPath: 'assets/books/as_a_man_thinketh.pdf',
      blurb:
          'A man is literally what he thinks. The mind is the master weaver.',
      theme: 'SELF-MASTERY',
      color: AppTheme.catBlocker, // brick
      pageCount: 0, // filled in at load time
    ),
    Book(
      id: 'meditations',
      title: 'Meditations',
      author: 'Marcus Aurelius',
      year: 180,
      assetPath: 'assets/books/meditations.pdf',
      blurb:
          'Twelve books of private notes on Stoic self-discipline, written on campaign.',
      theme: 'STOICISM',
      color: AppTheme.catUrge, // amber
      pageCount: 0,
    ),
    Book(
      id: 'self_reliance',
      title: 'Self-Reliance',
      author: 'Ralph Waldo Emerson',
      year: 1841,
      assetPath: 'assets/books/self_reliance.pdf',
      blurb:
          '"Whoso would be a man must be a nonconformist." The essay of essays.',
      theme: 'INDIVIDUALITY',
      color: AppTheme.catAccount, // forest
      pageCount: 0,
    ),
    Book(
      id: 'cant_hurt_me',
      title: "Can't Hurt Me",
      author: 'David Goggins',
      year: 2018,
      assetPath: 'assets/books/cant_hurt_me.pdf',
      blurb:
          'Master Your Mind and Defy the Odds. A Navy SEAL on pushing past pain, fear, and self-doubt.',
      theme: 'MENTAL TOUGHNESS',
      color: AppTheme.catSetting, // indigo (was The Prophet's color)
      pageCount: 0,
    ),
    Book(
      id: 'the_way_of_peace',
      title: 'The Way of Peace',
      author: 'James Allen',
      year: 1907,
      assetPath: 'assets/books/the_way_of_peace.pdf',
      blurb:
          'Inner peace is the foundation of all lasting change. The path in, then out.',
      theme: 'INNER PEACE',
      color: AppTheme.catBook, // umber
      pageCount: 0,
    ),
    Book(
      id: 'how_to_live_24_hours',
      title: 'How to Live on 24 Hours a Day',
      author: 'Arnold Bennett',
      year: 1910,
      assetPath: 'assets/books/how_to_live_24_hours.pdf',
      blurb:
          'You have 16 productive hours a week hiding in plain sight. Here is how to use them.',
      theme: 'FOCUS',
      color: AppTheme.catStats, // teal
      pageCount: 0,
    ),
  ];

  /// Look up a book by ID. Returns null if not found.
  static Book? byId(String id) {
    for (final b in catalog) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Load a book's PDF document from the bundled asset. Throws if the
  /// file is missing or not a valid PDF.
  ///
  /// The returned [pdf.PdfDocument] is the entry point for the
  /// reader — pages are rendered on demand via `doc[pageNumber].render()`.
  static Future<pdf.PdfDocument> loadBookPdf(Book book) async {
    final data = await rootBundle.load(book.assetPath);
    return pdf.PdfDocument.openData(data.buffer.asUint8List());
  }

  // ── Reading position persistence ───────────────────────────────
  //
  // We use SharedPreferences (the project's working custom plugin) to
  // store per-book reading position as the current PAGE NUMBER (int).
  // On reopen, we restore the scroll position to the top of that page.
  //
  // Page numbers are 0-indexed. Total page count is available from
  // the PdfDocument at open time, so the progress fraction is
  // currentPage / (pageCount - 1).

  /// Get the last-read page (0-indexed) for a book. Returns 0 if the
  /// book has never been opened.
  static Future<int> getLastPage(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('book_page_$bookId') ?? 0;
  }

  /// Persist the last-read page (0-indexed).
  static Future<void> setLastPage(String bookId, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('book_page_$bookId', page);
  }

  /// Get the ID of the last book the user opened, or null if none.
  static Future<String?> getLastOpenedBookId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('book_last_opened_id');
  }

  /// Mark a book as the most recently opened.
  static Future<void> setLastOpenedBookId(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('book_last_opened_id', bookId);
  }
}
