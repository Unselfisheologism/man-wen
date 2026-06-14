import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../services/bookshelf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/book_text_parser.dart';

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
  bool _isLoading = true;
  String? _loadError;
  Timer? _saveDebounce;

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
        child: FutureBuilder<String>(
          future: _textFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  _ReaderTopBar(book: widget.book, onMenu: () {}),
                  const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.accent)),
                  ),
                  _ReaderBottomBarPlaceholder(book: widget.book),
                ],
              );
            }
            if (snap.hasError || !snap.hasData) {
              return Column(
                children: [
                  _ReaderTopBar(book: widget.book, onMenu: () {}),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'COULD NOT LOAD TEXT\n\n${snap.error ?? 'unknown error'}',
                          textAlign: TextAlign.center,
                          style: AppTheme.label
                              .copyWith(color: AppTheme.accent),
                        ),
                      ),
                    ),
                  ),
                  _ReaderBottomBarPlaceholder(book: widget.book),
                ],
              );
            }
            // Cache the loaded text and restore scroll position on
            // the first build. The side effect in build is a known
            // anti-pattern but the Flutter team uses it in their
            // own code for the same case (FutureBuilder + restore).
            if (_loadedText == null) {
              _loadedText = snap.data!;
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _restoreScrollAfterFirstFrame());
            }
            final blocks = BookTextParser.parse(snap.data!);
            return Column(
              children: [
                _ReaderTopBar(book: widget.book, onMenu: _showMenu),
                Expanded(
                  child: _ReaderBody(
                    book: widget.book,
                    blocks: blocks,
                    scroll: _scroll,
                  ),
                ),
                _ReaderBottomBar(
                  book: widget.book,
                  progress: _progress,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onTextLoaded(String text) {
    if (_loadedText != null) return; // only once
    setState(() {
      _loadedText = text;
      _isLoading = false;
    });
    _restoreScrollAfterFirstFrame();
  }

  void _onTextError(Object e) {
    setState(() {
      _loadError = e.toString();
      _isLoading = false;
    });
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

/// Placeholder bottom bar (used while the text is loading) so the
/// bar height doesn't jump when the real bar appears.
class _ReaderBottomBarPlaceholder extends StatelessWidget {
  final Book book;
  const _ReaderBottomBarPlaceholder({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: AppTheme.paper,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.rule, width: 1),
        ),
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
