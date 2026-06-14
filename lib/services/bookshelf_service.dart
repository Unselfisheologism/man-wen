import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';

/// Self-help bookshelf — static catalog of bundled books + reading-position
/// persistence via SharedPreferences.
///
/// All books are bundled in `assets/books/*.txt` so the app works offline
/// with zero network dependency. To add a new book:
///   1. Drop a .txt file into `assets/books/`
///   2. Add a [Book] entry to [catalog] below
///   3. Rebuild
class BookshelfService {
  BookshelfService._();

  /// The Man Wen bookshelf — a curated set of classic self-help /
  /// philosophy texts in the public domain. All 6 fit comfortably under
  /// 200KB of bundled text (see [assets/books/](assets/books/)) and have
  /// stood the test of time as relevant to self-mastery.
  ///
  /// Colors are picked from the existing Man Wen palette so each book card
  /// reads as a different color block in the same editorial register as
  /// the home action cards.
  static const List<Book> catalog = [
    Book(
      id: 'as_a_man_thinketh',
      title: 'As a Man Thinketh',
      author: 'James Allen',
      year: 1903,
      assetPath: 'assets/books/as_a_man_thinketh.txt',
      blurb:
          'A man is literally what he thinks. The mind is the master weaver.',
      theme: 'SELF-MASTERY',
      color: AppTheme.catBlocker, // brick
      wordCount: 7560,
    ),
    Book(
      id: 'meditations',
      title: 'Meditations',
      author: 'Marcus Aurelius',
      year: 180,
      assetPath: 'assets/books/meditations.txt',
      blurb:
          'Twelve books of private notes on Stoic self-discipline, written on campaign.',
      theme: 'STOICISM',
      color: AppTheme.catUrge, // amber
      wordCount: 71957,
    ),
    Book(
      id: 'self_reliance',
      title: 'Self-Reliance',
      author: 'Ralph Waldo Emerson',
      year: 1841,
      assetPath: 'assets/books/self_reliance.txt',
      blurb:
          '"Whoso would be a man must be a nonconformist." The essay of essays.',
      theme: 'INDIVIDUALITY',
      color: AppTheme.catAccount, // forest
      wordCount: 10065,
    ),
    Book(
      id: 'the_prophet',
      title: 'The Prophet',
      author: 'Kahlil Gibran',
      year: 1923,
      assetPath: 'assets/books/the_prophet.txt',
      blurb:
          'On love, work, joy, sorrow, freedom, and 20 other things. Poetic, short, unforgettable.',
      theme: 'WISDOM',
      color: AppTheme.catSetting, // indigo
      wordCount: 12603,
    ),
    Book(
      id: 'the_way_of_peace',
      title: 'The Way of Peace',
      author: 'James Allen',
      year: 1907,
      assetPath: 'assets/books/the_way_of_peace.txt',
      blurb:
          'Inner peace is the foundation of all lasting change. The path in, then out.',
      theme: 'INNER PEACE',
      color: AppTheme.catBook, // umber (new — for the bookshelf itself)
      wordCount: 17193,
    ),
    Book(
      id: 'how_to_live_24_hours',
      title: 'How to Live on 24 Hours a Day',
      author: 'Arnold Bennett',
      year: 1910,
      assetPath: 'assets/books/how_to_live_24_hours.txt',
      blurb:
          'You have 16 productive hours a week hiding in plain sight. Here is how to use them.',
      theme: 'FOCUS',
      color: AppTheme.catStats, // teal
      wordCount: 12842,
    ),
  ];

  /// Look up a book by ID. Returns null if not found.
  static Book? byId(String id) {
    for (final b in catalog) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Load a book's text from the bundled asset. Throws if the file is
  /// missing — this is a programming error (forgot to add to pubspec.yaml
  /// or typo in assetPath), not a user-facing failure mode.
  static Future<String> loadBookText(Book book) async {
    final data = await rootBundle.loadString(book.assetPath);
    return data;
  }

  // ── Reading position persistence ───────────────────────────────
  //
  // We use SharedPreferences (the project's working custom plugin) to
  // store per-book reading position as a 0.0–1.0 progress fraction. The
  // EbookReaderScreen writes here on every scroll change (throttled) and
  // on dispose; the BookshelfScreen reads it to render progress chips on
  // each card.

  /// Get the reading progress (0.0–1.0) for a book. Returns 0.0 if the
  /// book has never been opened.
  static Future<double> getProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('book_progress_$bookId') ?? 0.0;
  }

  /// Persist the reading progress (0.0–1.0).
  static Future<void> setProgress(String bookId, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('book_progress_$bookId', progress.clamp(0.0, 1.0));
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
