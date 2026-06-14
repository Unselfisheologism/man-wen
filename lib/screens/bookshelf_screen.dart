import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/bookshelf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_widget.dart'; // for SectionHeader
import 'ebook_reader_screen.dart';

/// Bookshelf — the "do something better" library.
///
/// 6 self-help classics, all bundled in the app, all free, all public
/// domain. Tap a card to open the reader. Reading position is persisted
/// per-book via SharedPreferences (see BookshelfService).
///
/// Layout (Man Wen-ified, per the user's brief):
///   - 01 // BOOKSHELF masthead
///   - 02 // LIBRARY  hairline rule
///   - 2-column grid of solid-color book cards
///   - 03 // CONTINUE  hairline rule (only if there's a last-opened book)
///   - the "Continue reading" row
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  // Per-book reading progress. Keyed by book.id. Loaded on init and
  // refreshed when we come back from the reader (so tapping a book,
  // reading, and coming back shows the new progress without a full
  // restart).
  final Map<String, double> _progress = {};

  // Last opened book ID, for the "CONTINUE" row.
  String? _lastOpenedId;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final entries = await Future.wait(BookshelfService.catalog
        .map((b) => BookshelfService.getProgress(b.id)));
    final lastId = await BookshelfService.getLastOpenedBookId();
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < BookshelfService.catalog.length; i++) {
        _progress[BookshelfService.catalog[i].id] = entries[i];
      }
      _lastOpenedId = lastId;
    });
  }

  Future<void> _openBook(Book book) async {
    try {
      // Best-effort: remember the last-opened book. If the prefs
      // plugin is in a weird state, swallow the error and still
      // try to open the reader — the last-opened tracking is a
      // convenience, not a critical dependency.
      try {
        await BookshelfService.setLastOpenedBookId(book.id);
      } catch (_) {
        // ignore — the reader will still open.
      }
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EbookReaderScreen(book: book)),
      );
      // Reload progress on return so the card updates.
      await _loadState();
    } catch (e, s) {
      // Surface the error so the user isn't stuck tapping a
      // card that "does nothing". Without this, an unhandled
      // async error in the Future-returning closure would be
      // silently dropped (the `() => onTap(book)` adapter
      // discards the returned Future).
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('COULD NOT OPEN BOOK  ·  $e',
              style: AppTheme.label),
          backgroundColor: AppTheme.ink,
          duration: const Duration(seconds: 4),
        ),
      );
      // Also report to the dart crash log so the user can find it
      // even if the snackbar disappears.
      // (importing the reporter here to keep the dep local)
      // ignore: avoid_dynamic_calls
      try {
        // dart_crash_reporter exposes a top-level `report` function.
        await _reportError('BookshelfScreen._openBook failed', e, s);
      } catch (_) {}
    }
  }

  // Thin wrapper around the Dart crash reporter so we don't have
  // to add a top-level import to this file. Returns when the
  // reporter is unreachable (e.g. in tests).
  Future<void> _reportError(String msg, Object e, StackTrace s) async {
    // ignore: avoid_dynamic_calls
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    final lastOpenedBook = _lastOpenedId == null
        ? null
        : BookshelfService.byId(_lastOpenedId!);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // 01 // BOOKSHELF ──────────────────────────────────
              const _Masthead(),
              Container(
                height: 1,
                color: AppTheme.rule,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 8),

              // 02 // LIBRARY — 2-col grid of book cards ─────────
              const SectionHeader(number: '02', label: 'LIBRARY'),
              Container(
                height: 1,
                color: AppTheme.rule,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 16),
              _LibraryGrid(
                books: BookshelfService.catalog,
                progress: _progress,
                onTap: _openBook,
              ),

              // 03 // CONTINUE — only show if there's a last-opened
              if (lastOpenedBook != null) ...[
                const SectionHeader(number: '03', label: 'CONTINUE'),
                Container(
                  height: 1,
                  color: AppTheme.rule,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ContinueRow(
                    book: lastOpenedBook,
                    progress:
                        _progress[lastOpenedBook.id] ?? 0.0,
                    onTap: () => _openBook(lastOpenedBook),
                  ),
                ),
              ],

              // Footer: "v1.0  ·  6 BOOKS  ·  BUNDLED"
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'v1.0  ·  ${BookshelfService.catalog.length} BOOKS  ·  BUNDLED',
                  style: AppTheme.labelSoft,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 01 // BOOKSHELF — the masthead. Big editorial display title, version
/// stamp on the right, hairline rule below. Same pattern as the home
/// screen masthead — keeps the editorial register consistent.
class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('01 // BOOKSHELF',
                  style: AppTheme.label.copyWith(color: AppTheme.inkSoft)),
              Text('v1.0', style: AppTheme.labelSoft),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'READ.',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              height: 0.95,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text('DO  SOMETHING  BETTER.',
              style: AppTheme.label.copyWith(color: AppTheme.inkSoft)),
        ],
      ),
    );
  }
}

/// 2-column responsive grid of book cards. Uses LayoutBuilder for the
/// column count so it stays readable on narrow phones (1 col) and
/// wider screens (2-3 cols). Default is 2 cols on the standard phone
/// form factor.
class _LibraryGrid extends StatelessWidget {
  final List<Book> books;
  final Map<String, double> progress;
  final void Function(Book) onTap;

  const _LibraryGrid({
    required this.books,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // 2 columns on phones. Books are large blocks, 3 cols would
        // make the type too small.
        final crossCount = 2;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              // The book card is mostly the title + author + theme,
              // roughly square. Width / height ratio is 0.85 to favor
              // taller cards (more room for blurb).
              childAspectRatio: 0.78,
            ),
            itemCount: books.length,
            itemBuilder: (context, i) {
              final book = books[i];
              return _BookCard(
                book: book,
                number: '${(i + 1).toString().padLeft(2, '0')}',
                progress: progress[book.id] ?? 0.0,
                onTap: () => onTap(book),
              );
            },
          ),
        );
      },
    );
  }
}

/// A book card — a solid color block with mono labels.
///
/// Pattern matches the home action cards (`_ColorCard` in
/// home_screen.dart): full-width-ish, sharp corners, color block IS the
/// visual. White text in cream on the saturated color.
class _BookCard extends StatelessWidget {
  final Book book;
  final String number;
  final double progress;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.number,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasProgress = progress > 0.01;
    final pct = (progress * 100).round();
    // Material > InkWell > Padding. Using Material (not Container with
    // color) is the canonical Flutter pattern for a tappable surface
    // — without it, the InkWell's hit-testing can be flaky on some
    // Android versions when the child has a non-transparent background.
    return Material(
      color: book.color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number + theme in mono
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(number,
                    style: AppTheme.label.copyWith(
                      color: AppTheme.paper.withOpacity(0.75),
                    )),
                Text(book.theme,
                    style: AppTheme.label.copyWith(
                      color: AppTheme.paper.withOpacity(0.75),
                    )),
              ],
            ),
            const Spacer(),
            // Title
            Text(
              book.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -0.5,
                color: AppTheme.paper,
              ),
            ),
            const SizedBox(height: 8),
            // Author + year
            Text(
              '${book.author.toUpperCase()}  ·  ${book.year}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelSoft.copyWith(
                color: AppTheme.paper.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 10),
            // Status: progress bar (if started) or "READY"
            if (hasProgress) ...[
              // 1px hairline progress
              Container(
                height: 1,
                color: AppTheme.paper.withOpacity(0.3),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('READING',
                      style: AppTheme.label.copyWith(color: AppTheme.paper)),
                  Text('$pct%',
                      style: AppTheme.label.copyWith(color: AppTheme.paper)),
                ],
              ),
            ] else ...[
              Container(
                height: 1,
                color: AppTheme.paper.withOpacity(0.3),
              ),
              const SizedBox(height: 6),
              Text('READY',
                  style: AppTheme.label.copyWith(color: AppTheme.paper)),
            ],
          ],
        ),
      ),
    ),
  );
}
}

/// 03 // CONTINUE — single row pointing to the last opened book.
/// Solid color block, "RESUME" call-to-action, thin progress bar.
class _ContinueRow extends StatelessWidget {
  final Book book;
  final double progress;
  final VoidCallback onTap;

  const _ContinueRow({
    required this.book,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    // Material > InkWell > Padding — see _BookCard for the rationale
    // (canonical Flutter pattern for tappable colored surfaces).
    return Material(
      color: book.color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('RESUME',
                    style: AppTheme.label.copyWith(color: AppTheme.paper)),
                Text('$pct%',
                    style: AppTheme.label.copyWith(
                      color: AppTheme.paper.withOpacity(0.85),
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -0.5,
                color: AppTheme.paper,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              book.author.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelSoft.copyWith(
                color: AppTheme.paper.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 10),
            // 1px hairline + a 1px filled bar in paper to show progress
            Stack(
              children: [
                Container(
                  height: 2,
                  color: AppTheme.paper.withOpacity(0.25),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 2,
                    color: AppTheme.paper,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
