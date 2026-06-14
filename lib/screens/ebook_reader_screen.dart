import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../services/bookshelf_service.dart';
import '../theme/app_theme.dart';

/// Ebook reader — Man Wen-ified reading view.
///
/// Structure (matches the existing editorial register):
///   - Top app bar: back arrow + book title (mono) + 3-dot menu
///   - Book masthead: title, author, year, theme — all mono
///   - Body: scrollable text. Generous line height for reading.
///     Sans body, no serif — consistent with the rest of the app.
///   - Bottom control bar: progress percentage + bookmark + share
///
/// State: text is loaded once on init. Scroll position is tracked as a
/// 0.0–1.0 fraction of the total scroll extent, throttled to save to
/// SharedPreferences at most every 1.5s. On dispose, the final position
/// is written.
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

  @override
  void initState() {
    super.initState();
    _textFuture = BookshelfService.loadBookText(widget.book);
    _scroll.addListener(_onScroll);
    // Restore last position asynchronously after the first frame so
    // the ScrollController has an extent to jump to.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = await BookshelfService.getProgress(widget.book.id);
      if (!mounted) return;
      if (p > 0.01 && _scroll.hasClients) {
        final max = _scroll.position.maxScrollExtent;
        _scroll.jumpTo(max * p);
      }
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    // Final save on the way out. Don't await — we're in dispose.
    BookshelfService.setProgress(widget.book.id, _progress);
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
    _saveDebounce = Timer(const Duration(milliseconds: 1500), () {
      BookshelfService.setProgress(widget.book.id, _progress);
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
        onShare: () {
          Navigator.pop(ctx);
          // Lightweight "copy to clipboard" share — avoids depending on
          // the share_plus plugin (which the project's old-style Gradle
          // plugin can't autolink).
          if (_loadedText != null) {
            final preview = _loadedText!.length > 240
                ? '${_loadedText!.substring(0, 240)}...'
                : _loadedText!;
            Clipboard.setData(ClipboardData(
                text:
                    '${widget.book.title} — ${widget.book.author}\n\n$preview'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('First lines copied to clipboard',
                    style: AppTheme.label),
                duration: Duration(seconds: 2),
                backgroundColor: AppTheme.surface,
              ),
            );
          }
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
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.accent));
            }
            if (snap.hasError || !snap.hasData) {
              // Asset load failed — show error state.
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'COULD NOT LOAD TEXT',
                    style: AppTheme.label.copyWith(color: AppTheme.accent),
                  ),
                ),
              );
            }
            _loadedText = snap.data!;
            return Column(
              children: [
                _ReaderTopBar(
                  book: widget.book,
                  onMenu: _showMenu,
                ),
                Expanded(
                  child: _ReaderBody(
                    text: snap.data!,
                    book: widget.book,
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
}

/// Top bar — back arrow + book title (mono) + 3-dot menu. The title
/// truncates with ellipsis. 52px tall, no shadow, no AppBar elevation
/// (matches the editorial register).
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

/// The reading body — masthead + scrollable text.
///
/// Body text uses the system sans (Roboto on Android). Line height 1.7
/// is generous for sustained reading. We split paragraphs by double
/// newline (the asset text is paragraph-separated).
class _ReaderBody extends StatelessWidget {
  final String text;
  final Book book;
  final ScrollController scroll;

  const _ReaderBody({
    required this.text,
    required this.book,
    required this.scroll,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scroll,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book masthead at the top of the reading body.
          _BookMasthead(book: book),
          const SizedBox(height: 24),
          Container(height: 1, color: AppTheme.rule),
          const SizedBox(height: 24),
          // Body text — split into paragraphs.
          ..._paragraphs(text).map((p) => _Paragraph(text: p)),
          const SizedBox(height: 80), // bottom breathing room
        ],
      ),
    );
  }

  /// Split the book text into paragraphs. The bundled .txt files are
  /// separated by blank lines (we collapsed 3+ blanks to 2 in the
  /// strip script). So a paragraph = text between blank lines.
  List<String> _paragraphs(String s) {
    return s
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }
}

/// Book masthead inside the reader — title (big), author, year, theme.
/// Same editorial register as the page mastheads.
class _BookMasthead extends StatelessWidget {
  final Book book;
  const _BookMasthead({required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4px color block — the "this is the category of this book" signal
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
          '~${book.estimatedMinutes} MIN READ  ·  ${book.wordCount ~/ 1000}K WORDS',
          style: AppTheme.labelSoft,
        ),
      ],
    );
  }
}

/// A single paragraph of body text. Generous line height (1.7) and a
/// slightly larger size than the default for sustained reading comfort.
class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          height: 1.7,
          color: AppTheme.ink,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/// Bottom control bar — hairline top border, three slots:
///   left: progress percentage (mono)
///   middle: progress bar
///   right: progress percentage
///
/// The middle progress bar tints the book's color so it matches the
/// rest of the editorial system. The 3-dot menu is in the top bar; the
/// bottom bar is for visual progress only.
///
/// IMPORTANT: this bar has an explicit `color: AppTheme.paper` on the
/// background. Without it, the Container is transparent and the
/// GestureDetector that used to wrap it (default behavior:
/// HitTestBehavior.deferToChild) was rendering as a near-black
/// ghost strip on some Android versions after the reader was popped.
/// Keeping the bar opaque with the paper color matches the rest of
/// the app's editorial system and prevents that artifact.
class _ReaderBottomBar extends StatelessWidget {
  final Book book;
  final double progress;

  const _ReaderBottomBar({
    required this.book,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      // Explicit paper background so the bar is never transparent.
      // (Was previously wrapped in a GestureDetector with a transparent
      // Container child — that combination left a dark strip on the
      // bookshelf after the reader was popped, on some Android builds.)
      // Note: color lives inside the BoxDecoration — Container doesn't
      // allow both `color:` and `decoration:` to be set at the same time.
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppTheme.paper,
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
              Container(
                height: 2,
                color: AppTheme.rule,
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 2,
                  color: book.color,
                ),
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
///   - Copy first lines
class _ReaderMenu extends StatelessWidget {
  final double progress;
  final VoidCallback onJumpTop;
  final VoidCallback onJumpBottom;
  final VoidCallback onShare;

  const _ReaderMenu({
    required this.progress,
    required this.onJumpTop,
    required this.onJumpBottom,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
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
                Text('READER  ·  ${(progress * 100).round()}%',
                    style: AppTheme.label),
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
            _MenuRow(label: 'COPY FIRST LINES', onTap: onShare),
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
