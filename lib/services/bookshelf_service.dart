import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';

/// Self-help bookshelf — static catalog of bundled text books +
/// scroll-position persistence via SharedPreferences.
///
/// All books are bundled in `assets/books/*.txt` so the app works
/// offline with zero network dependency. To add a new book:
///   1. Drop a .txt file into `assets/books/`
///   2. Add a [Book] entry to [catalog] below
///   3. Rebuild
class BookshelfService {
  BookshelfService._();

  /// The Man Wen bookshelf — 6 public-domain / freely-shared self-help
  /// classics, bundled as plain-text. Order is editorial: foundational
  /// mind / discipline books first (Allen, Aurelius, Emerson), then
  /// the action-oriented titles (Goggins, Bennett), then the
  /// inner-work titles (Allen, Gibran). Books are picked for direct
  /// relevance to self-mastery and resilience.
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
      assetPath: 'assets/books/as_a_man_thinketh.txt',
      blurb:
          'A man is literally what he thinks. The mind is the master weaver.',
      theme: 'SELF-MASTERY',
      color: AppTheme.catBlocker, // brick
      wordCount: 7569,
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
      wordCount: 10287,
    ),
    Book(
      id: 'cant_hurt_me',
      title: "Can't Hurt Me",
      author: 'David Goggins',
      year: 2018,
      assetPath: 'assets/books/cant_hurt_me.txt',
      blurb:
          'Master Your Mind and Defy the Odds. A Navy SEAL on pushing past pain, fear, and self-doubt.',
      theme: 'MENTAL TOUGHNESS',
      color: AppTheme.catSetting, // indigo
      wordCount: 107727,
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
      color: AppTheme.catBook, // umber
      wordCount: 17741,
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
      wordCount: 17309,
    ),
    // ── Books 7–12 (added 2026-06) ─────────────────────────────────
    // The first six are public-domain and bundled from Project
    // Gutenberg / Wikisource. These six are still under copyright
    // and the user supplied the source PDFs — we extract the text
    // once at build time and ship it as bundled assets so the app
    // remains fully offline.
    Book(
      id: 'the_48_laws_of_power',
      title: 'The 48 Laws of Power',
      author: 'Robert Greene',
      year: 1998,
      assetPath: 'assets/books/the_48_laws_of_power.txt',
      blurb:
          'The laws of power, distilled from three thousand years of history. Read once, read again, read carefully.',
      theme: 'POWER',
      color: AppTheme.catWine, // wine
      wordCount: 237353,
    ),
    Book(
      id: 'thinking_fast_and_slow',
      title: 'Thinking, Fast and Slow',
      author: 'Daniel Kahneman',
      year: 2011,
      assetPath: 'assets/books/thinking_fast_and_slow.txt',
      blurb:
          'Two systems drive how we think. Master both, and you master every conversation you walk into.',
      theme: 'COGNITION',
      color: AppTheme.catOlive, // olive
      wordCount: 190287,
    ),
    Book(
      id: 'rich_dad_poor_dad',
      title: 'Rich Dad Poor Dad',
      author: 'Robert Kiyosaki',
      year: 1997,
      assetPath: 'assets/books/rich_dad_poor_dad.txt',
      blurb:
          'The rich don\'t work for money; they make money work for them. A primer on financial literacy.',
      theme: 'WEALTH',
      color: AppTheme.catGold, // gold
      wordCount: 66437,
    ),
    Book(
      id: 'mastery',
      title: 'Mastery',
      author: 'Robert Greene',
      year: 2012,
      assetPath: 'assets/books/mastery.txt',
      blurb:
          'The path to mastery is long, lonely, and the only one that leads anywhere worth going.',
      theme: 'MASTERY',
      color: AppTheme.catPlum, // plum
      wordCount: 153754,
    ),
    Book(
      id: 'psychology_of_money',
      title: 'The Psychology of Money',
      author: 'Morgan Housel',
      year: 2020,
      assetPath: 'assets/books/psychology_of_money.txt',
      blurb:
          'Wealth is what you don\'t see. It\'s the cars not purchased and the upgrades not made.',
      theme: 'MONEY',
      color: AppTheme.catSand, // sand
      wordCount: 52778,
    ),
    Book(
      id: 'atomic_habits',
      title: 'Atomic Habits',
      author: 'James Clear',
      year: 2018,
      assetPath: 'assets/books/atomic_habits.txt',
      blurb:
          'Tiny changes, remarkable results. The compound interest of self-improvement.',
      theme: 'HABITS',
      color: AppTheme.catSage, // sage
      wordCount: 77334,
    ),
  ];

  /// Look up a book by ID. Returns null if not found.
  static Book? byId(String id) {
    for (final b in catalog) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Load a book's text from the bundled asset. Throws if the
  /// file is missing.
  static Future<String> loadBookText(Book book) async {
    return rootBundle.loadString(book.assetPath);
  }

  // ── Reading position persistence ───────────────────────────────
  //
  // We use SharedPreferences (the project's working custom plugin) to
  // store per-book reading position as a fraction (0.0–1.0). On
  // reopen, we restore the scroll position to that fraction of the
  // total scroll extent.

  /// Get the reading progress (0.0–1.0) for a book. Returns 0.0 if
  /// the book has never been opened.
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
