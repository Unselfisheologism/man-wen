import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/book_summaries.dart';
import '../models/book.dart';
import '../services/bookshelf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/book_text_parser.dart';

/// Which sub-view of the reader is currently active. The reader
/// has two tabs: TEXT (the actual book) and SUMMARY (an editorial
/// pitch written by us, ~300 words, plus a chapter index). The
/// tab state is local to the screen — closing the reader resets
/// it back to TEXT.
enum _ReaderTab { text, summary }

/// Ebook reader — Man Wen-ified formatted-text reader.
///
/// Structure (matches the existing editorial register):
///   - Top app bar: back arrow + book title (mono) + 3-dot menu
///   - Book masthead: 4px color block, theme, title, author·year,
///     ~N MIN READ · NK WORDS
///   - Body: scrolling paragraphs of book text. Chapter headings
///     (ALL-CAPS lines like "THE FIRST BOOK" or "Chapter 1") get
///     detected and rendered as big editorial chapter blocks with
///     a hairline rule above and below. The first letter of the
///     first paragraph of the book is a large drop cap.
///   - Bottom bar: PAGE N% + percentage + hairline progress bar
///   - 3-dot menu: jump to top / jump to bottom / copy first lines
///
/// State: text is loaded once on init. Scroll position is tracked
/// as a 0.0–1.0 fraction, throttled to save to SharedPreferences
/// at most every 300ms. On dispose, the final position is written.
class EbookReaderScreen extends StatefulWidget {
  final Book book;
  const EbookReaderScreen({super.key, required this.book});

  @override
  State<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends State<EbookReaderScreen> {
  Future<String>? _textFuture;
  String? _loadedText;
  final ScrollController _scroll = ScrollController();
  double _progress = 0.0;
  Timer? _saveDebounce;
  _ReaderTab _tab = _ReaderTab.text;

  @override
  void initState() {
    super.initState();
    _textFuture = BookshelfService.loadBookText(widget.book);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    // Best-effort final save on the way out. Fire-and-forget via
    // microtask + try-catch so a prefs race with the post-pop
    // reload doesn't surface as an error.
    final bookId = widget.book.id;
    final progress = _progress;
    Future.microtask(() async {
      try {
        await BookshelfService.setProgress(bookId, progress);
      } catch (_) {}
    });
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.maxScrollExtent <= 0) return;
    final p = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    setState(() => _progress = p);
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      if (_loadedText != null) {
        BookshelfService.setProgress(widget.book.id, _progress);
      }
    });
  }

  /// Restore the last-read scroll position after the first frame,
  /// so the [ScrollController] has an extent to jump to. Wrapped
  /// in try-catch so a prefs failure doesn't throw into the
  /// FutureBuilder's error path.
  void _restoreScrollAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final p = await BookshelfService.getProgress(widget.book.id);
        if (!mounted) return;
        if (p > 0.01 && _scroll.hasClients) {
          final max = _scroll.position.maxScrollExtent;
          _scroll.jumpTo(max * p);
        }
      } catch (_) {
        // silent — open at the top on prefs failure
      }
    });
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (ctx) => _ReaderMenu(
        progress: _progress,
        onJumpTop: () {
          Navigator.pop(ctx);
          _scroll.animateTo(0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut);
        },
        onJumpBottom: () {
          Navigator.pop(ctx);
          if (_scroll.hasClients) {
            _scroll.animateTo(_scroll.position.maxScrollExtent,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut);
          }
        },
        onCopyPageRef: () {
          Navigator.pop(ctx);
          final ref =
              '${widget.book.title} — ${(widget.book.wordCount / 220).round()} min read';
          Clipboard.setData(ClipboardData(text: ref));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book reference copied to clipboard',
                  style: AppTheme.label),
              duration: Duration(seconds: 2),
              backgroundColor: AppTheme.surface,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: SafeArea(
        child: Column(
          children: [
            _ReaderTopBar(book: widget.book, onMenu: _showMenu),
            _ReaderTabBar(
              current: _tab,
              onChanged: (t) => setState(() => _tab = t),
              bookColor: widget.book.color,
            ),
            Expanded(
              child: _tab == _ReaderTab.text
                  ? _buildTextTab()
                  : _buildSummaryTab(),
            ),
            _ReaderBottomBar(
              book: widget.book,
              progress: _tab == _ReaderTab.text ? _progress : 0.0,
            ),
          ],
        ),
      ),
    );
  }

  /// The TEXT tab — loads the book text from the asset, parses it
  /// into chapter blocks, and renders it as a scrolling reader
  /// with the bottom bar tracking scroll progress.
  Widget _buildTextTab() {
    return FutureBuilder<String>(
      future: _textFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'COULD NOT LOAD TEXT\n\n${snap.error ?? 'unknown error'}',
                textAlign: TextAlign.center,
                style: AppTheme.label.copyWith(color: AppTheme.accent),
              ),
            ),
          );
        }
        if (_loadedText == null) {
          _loadedText = snap.data!;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _restoreScrollAfterFirstFrame());
        }
        final blocks = BookTextParser.parse(snap.data!);
        return _ReaderBody(
          book: widget.book,
          blocks: blocks,
          scroll: _scroll,
        );
      },
    );
  }

  /// The SUMMARY tab — renders the hand-written editorial pitch
  /// for the book, plus a chapter index if the book has one.
  /// No async loading — the summary lives in code.
  Widget _buildSummaryTab() {
    final summary = summaryFor(widget.book);
    if (summary == null) {
      // Shouldn't happen — every book in the catalog has a
      // summary. But fall back gracefully rather than crash.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No summary available for this book.',
            style: AppTheme.label,
          ),
        ),
      );
    }
    return _SummaryBody(book: widget.book, summary: summary);
  }
}

/// Top bar — back arrow + book title (mono) + 3-dot menu. 52px tall,
/// no shadow, hairline bottom border.
class _ReaderTopBar extends StatelessWidget {
  final Book book;
  final VoidCallback onMenu;

  const _ReaderTopBar({required this.book, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.rule, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 20),
            color: AppTheme.ink,
            splashRadius: 22,
          ),
          Expanded(
            child: Center(
              child: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.label.copyWith(color: AppTheme.ink),
              ),
            ),
          ),
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.more_horiz, size: 20),
            color: AppTheme.ink,
            splashRadius: 22,
          ),
        ],
      ),
    );
  }
}

/// The reading body — masthead + scrolling text blocks.
class _ReaderBody extends StatefulWidget {
  final Book book;
  final List<TextBlock> blocks;
  final ScrollController scroll;

  const _ReaderBody({
    required this.book,
    required this.blocks,
    required this.scroll,
  });

  @override
  State<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<_ReaderBody> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scroll,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookMasthead(book: widget.book),
          const SizedBox(height: 24),
          Container(height: 1, color: AppTheme.rule),
          const SizedBox(height: 24),
          // Render the body — chapter blocks + paragraphs + drop cap
          // for the first paragraph. The parser is responsible for
          // tagging each block with its kind.
          ..._renderBlocks(widget.blocks),
          const SizedBox(height: 80), // bottom breathing room
        ],
      ),
    );
  }

  /// Render the parsed text blocks. The first text block of the book
  /// gets a drop cap. Chapter blocks are big editorial headers.
  List<Widget> _renderBlocks(List<TextBlock> blocks) {
    final out = <Widget>[];
    var isFirstParagraph = true;
    for (final b in blocks) {
      switch (b.kind) {
        case BlockKind.chapter:
          out.add(_ChapterHeader(text: b.text));
          isFirstParagraph = true;
          out.add(const SizedBox(height: 8));
          break;
        case BlockKind.paragraph:
          if (b.text.trim().isEmpty) {
            out.add(const SizedBox(height: 12));
          } else if (isFirstParagraph) {
            out.add(_Paragraph(
              text: b.text,
              dropCap: true,
            ));
            isFirstParagraph = false;
            out.add(const SizedBox(height: 18));
          } else {
            out.add(_Paragraph(text: b.text));
            out.add(const SizedBox(height: 18));
          }
          break;
        case BlockKind.spacer:
          out.add(const SizedBox(height: 12));
          break;
      }
    }
    return out;
  }
}

/// Book masthead inside the reader — 4px color block, theme, title,
/// author·year, ~N MIN READ · NK WORDS.
class _BookMasthead extends StatelessWidget {
  final Book book;
  const _BookMasthead({required this.book});

  @override
  Widget build(BuildContext context) {
    final minutes = (book.wordCount / 220).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 4, width: 48, color: book.color),
        const SizedBox(height: 16),
        Text(book.theme,
            style: AppTheme.label.copyWith(color: AppTheme.inkSoft)),
        const SizedBox(height: 12),
        Text(
          book.title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -1,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${book.author.toUpperCase()}  ·  ${book.year}',
          style: AppTheme.label.copyWith(color: AppTheme.inkSoft),
        ),
        const SizedBox(height: 12),
        Text(
          '~$minutes MIN READ  ·  ${(book.wordCount / 1000).toStringAsFixed(0)}K WORDS',
          style: AppTheme.labelSoft,
        ),
      ],
    );
  }
}

/// Chapter header — full-width editorial block with hairline rules
/// above and below, big mono caps text.
class _ChapterHeader extends StatelessWidget {
  final String text;
  const _ChapterHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: AppTheme.ink),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              height: 1.2,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppTheme.ink),
        ],
      ),
    );
  }
}

/// A single paragraph. Optional drop cap on the first character.
class _Paragraph extends StatelessWidget {
  final String text;
  final bool dropCap;
  const _Paragraph({required this.text, this.dropCap = false});

  @override
  Widget build(BuildContext context) {
    if (!dropCap) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          height: 1.7,
          color: AppTheme.ink,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
      );
    }
    // Drop cap: render the first letter HUGE inline with the rest of
    // the paragraph. We use a Row with the big letter taking the
    // first line's height.
    final first = text.characters.first;
    final rest = text.substring(first.length);
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 17,
          height: 1.7,
          color: AppTheme.ink,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 0, bottom: 0),
              child: Text(
                first,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  height: 0.9,
                  color: AppTheme.ink,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          TextSpan(text: rest),
        ],
      ),
    );
  }
}

/// Bottom control bar — hairline top border:
///   left:  chapter / paragraph counter (words so far)
///   right: percentage
///   middle: hairline progress bar in the book's color
class _ReaderBottomBar extends StatelessWidget {
  final Book book;
  final double progress;
  const _ReaderBottomBar({required this.book, required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      color: AppTheme.paper,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.rule, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${book.wordCount} WORDS',
                  style: AppTheme.labelSoft),
              Text('$pct%', style: AppTheme.data),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(height: 2, color: AppTheme.rule),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(height: 2, color: book.color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The 3-dot menu — full-screen sheet. Options:
///   - Jump to top
///   - Jump to bottom
///   - Copy book reference
class _ReaderMenu extends StatelessWidget {
  final double progress;
  final VoidCallback onJumpTop;
  final VoidCallback onJumpBottom;
  final VoidCallback onCopyPageRef;

  const _ReaderMenu({
    required this.progress,
    required this.onJumpTop,
    required this.onJumpBottom,
    required this.onCopyPageRef,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('READER  ·  $pct%', style: AppTheme.label),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: AppTheme.rule),
            const SizedBox(height: 8),
            _MenuRow(label: 'JUMP TO TOP', onTap: onJumpTop),
            const SizedBox(height: 4),
            _MenuRow(label: 'JUMP TO BOTTOM', onTap: onJumpBottom),
            const SizedBox(height: 4),
            _MenuRow(label: 'COPY BOOK REFERENCE', onTap: onCopyPageRef),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MenuRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(label, style: AppTheme.label.copyWith(color: AppTheme.ink)),
      ),
    );
  }
}

/// Two-tab bar below the top bar. Mono labels, hairline rules,
/// active tab underlined in the book's color. Tapping switches
/// the body between the TEXT reader and the SUMMARY view.
class _ReaderTabBar extends StatelessWidget {
  final _ReaderTab current;
  final ValueChanged<_ReaderTab> onChanged;
  final Color bookColor;

  const _ReaderTabBar({
    required this.current,
    required this.onChanged,
    required this.bookColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.rule, width: 1),
        ),
      ),
      child: Row(
        children: [
          _Tab(label: 'TEXT', selected: current == _ReaderTab.text,
              onTap: () => onChanged(_ReaderTab.text), color: bookColor),
          _Tab(label: 'SUMMARY', selected: current == _ReaderTab.summary,
              onTap: () => onChanged(_ReaderTab.summary), color: bookColor),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? color : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTheme.label.copyWith(
              color: selected ? AppTheme.ink : AppTheme.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

/// The SUMMARY tab body — masthead (theme, title, author·year,
/// ~min read), the hand-written editorial pitch, and a chapter
/// index if the book has one. No async loading.
class _SummaryBody extends StatelessWidget {
  final Book book;
  final BookSummary summary;

  const _SummaryBody({required this.book, required this.summary});

  @override
  Widget build(BuildContext context) {
    final minutes = (book.wordCount / 220).round();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Masthead — same shape as the reader's TEXT masthead so
          // the two tabs feel like the same screen.
          Container(height: 4, width: 48, color: book.color),
          const SizedBox(height: 16),
          Text('SUMMARY',
              style: AppTheme.label.copyWith(color: AppTheme.inkSoft)),
          const SizedBox(height: 12),
          Text(
            book.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${book.author.toUpperCase()}  ·  ${book.year}',
            style: AppTheme.label.copyWith(color: AppTheme.inkSoft),
          ),
          const SizedBox(height: 12),
          Text(
            '~$minutes MIN READ  ·  ${(book.wordCount / 1000).toStringAsFixed(0)}K WORDS',
            style: AppTheme.labelSoft,
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: AppTheme.rule),
          const SizedBox(height: 24),
          // The body of the summary — plain prose, line height
          // matched to the reader body. No drop cap (that's a
          // book-text decoration; a pitch doesn't earn it).
          Text(
            summary.body,
            style: const TextStyle(
              fontSize: 17,
              height: 1.7,
              color: AppTheme.ink,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          if (summary.chapters.isNotEmpty) ...[
            const SizedBox(height: 32),
            Container(height: 1, color: AppTheme.rule),
            const SizedBox(height: 24),
            Text('CHAPTERS',
                style: AppTheme.label.copyWith(color: AppTheme.inkSoft)),
            const SizedBox(height: 12),
            // Numbered chapter index in mono. Each row is a tappable
            // surface that closes the SUMMARY tab and opens the
            // TEXT tab — but jumping to a specific chapter from
            // here is a future feature; for now the rows are
            // visual only (still tappable, with a subtle feedback).
            for (var i = 0; i < summary.chapters.length; i++)
              _ChapterIndexRow(
                number: '${(i + 1).toString().padLeft(2, '0')}',
                title: summary.chapters[i],
              ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ChapterIndexRow extends StatelessWidget {
  final String number;
  final String title;
  const _ChapterIndexRow({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(number, style: AppTheme.label),
          ),
          Expanded(
            child: Text(
              title,
              style: AppTheme.label.copyWith(color: AppTheme.ink),
            ),
          ),
        ],
      ),
    );
  }
}
