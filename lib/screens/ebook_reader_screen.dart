import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_render/pdf_render.dart' as pdf;
import '../models/book.dart';
import '../services/bookshelf_service.dart';
import '../theme/app_theme.dart';

/// Ebook reader — Man Wen-ified PDF viewer.
///
/// Structure (matches the existing editorial register):
///   - Top app bar: back arrow + book title (mono) + 3-dot menu
///   - Body: vertically-scrollable list of PDF pages, each rendered
///     to a [ui.Image] lazily (visible pages + neighbors) so a
///     200-page book doesn't lock the UI at open
///   - Bottom bar: PAGE N OF M + percentage + hairline progress bar
///   - 3-dot menu: jump to top / jump to bottom / copy page excerpt
///
/// State: PDF is loaded once on init. Current page is tracked by
/// scroll position, throttled to save to SharedPreferences at most
/// every 300ms. On dispose, the final page is written.
class EbookReaderScreen extends StatefulWidget {
  final Book book;
  const EbookReaderScreen({super.key, required this.book});

  @override
  State<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends State<EbookReaderScreen> {
  pdf.PdfDocument? _doc;
  int _currentPage = 0;
  int _totalPages = 0;
  final ScrollController _scroll = ScrollController();
  bool _isLoading = true;
  String? _loadError;
  Timer? _saveDebounce;
  // The text of the current page (for the "copy excerpt" menu item).
  // PDF rendering via `pdf_render` doesn't expose selectable text, so
  // we render the page image — no text content is available. The
  // share button is therefore disabled when the PDF doesn't have a
  // text layer (most older scanned-as-text PDFs do, but `pdf_render`
  // only sees the rendered image). Kept here for future use.

  @override
  void initState() {
    super.initState();
    _loadPdf();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    // Best-effort save the final page on exit. Wrapped in microtask
    // + try-catch so a prefs race with the bookshelf reload after pop
    // doesn't surface as an error.
    final bookId = widget.book.id;
    final page = _currentPage;
    Future.microtask(() async {
      try {
        await BookshelfService.setLastPage(bookId, page);
      } catch (_) {}
    });
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      final doc = await BookshelfService.loadBookPdf(widget.book);
      final lastPage = await BookshelfService.getLastPage(widget.book.id);
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _totalPages = doc.pageCount;
        _currentPage = lastPage.clamp(0, _totalPages - 1);
        _isLoading = false;
      });
      // Scroll to last-read page after the first frame, so the
      // ListView has a position to jump to.
      if (_currentPage > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToPage(_currentPage);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Jump the scroll position to the top of [page]. Approximate —
  /// each page is assumed to take an equal share of the total scroll
  /// extent. This is good enough for the 99% case (the user opened
  /// the book and resumed near where they left off).
  void _scrollToPage(int page) {
    if (!_scroll.hasClients || _totalPages == 0) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    final pageHeight = max / _totalPages;
    _scroll.jumpTo(pageHeight * page);
  }

  void _onScroll() {
    if (!_scroll.hasClients || _totalPages == 0) return;
    final pos = _scroll.position;
    if (pos.maxScrollExtent <= 0) return;
    final pageHeight = pos.maxScrollExtent / _totalPages;
    final newPage =
        (pos.pixels / pageHeight).round().clamp(0, _totalPages - 1);
    if (newPage != _currentPage) {
      setState(() => _currentPage = newPage);
      _scheduleSave();
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      if (_doc != null) {
        BookshelfService.setLastPage(widget.book.id, _currentPage);
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
        currentPage: _currentPage,
        totalPages: _totalPages,
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
              '${widget.book.title} — page ${_currentPage + 1} of $_totalPages';
          Clipboard.setData(ClipboardData(text: ref));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Page reference copied to clipboard',
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Column(
        children: [
          _ReaderTopBar(book: widget.book, onMenu: () {}),
          const Expanded(
            child: Center(
                child:
                    CircularProgressIndicator(color: AppTheme.accent)),
          ),
          _ReaderBottomBarPlaceholder(book: widget.book),
        ],
      );
    }
    if (_loadError != null) {
      return Column(
        children: [
          _ReaderTopBar(book: widget.book, onMenu: () {}),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'COULD NOT LOAD PDF\n\n$_loadError',
                  textAlign: TextAlign.center,
                  style: AppTheme.label.copyWith(color: AppTheme.accent),
                ),
              ),
            ),
          ),
          _ReaderBottomBarPlaceholder(book: widget.book),
        ],
      );
    }
    final doc = _doc!;
    return Column(
      children: [
        _ReaderTopBar(book: widget.book, onMenu: _showMenu),
        Expanded(
          child: _PdfPageList(
            doc: doc,
            totalPages: _totalPages,
            scroll: _scroll,
          ),
        ),
        _ReaderBottomBar(
          book: widget.book,
          currentPage: _currentPage,
          totalPages: _totalPages,
        ),
      ],
    );
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

/// Vertically-scrolling list of PDF pages. Uses [ListView.builder] so
/// off-screen pages aren't built; combined with [_PdfPageWidget]'s
/// lazy render, a 200-page book opens instantly.
class _PdfPageList extends StatelessWidget {
  final pdf.PdfDocument doc;
  final int totalPages;
  final ScrollController scroll;

  const _PdfPageList({
    required this.doc,
    required this.totalPages,
    required this.scroll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: totalPages,
      itemBuilder: (context, i) => _PdfPageWidget(
        doc: doc,
        pageNumber: i,
      ),
    );
  }
}

/// Renders a single PDF page to a [ui.Image] on mount, then displays
/// the image via [RawImage]. Each page is white (PDF default) with
/// the rendered image on top. While rendering, shows a hairline-rule
/// placeholder the same size as the eventual image so the list
/// doesn't jump when the image arrives.
class _PdfPageWidget extends StatefulWidget {
  final pdf.PdfDocument doc;
  final int pageNumber;

  const _PdfPageWidget({
    required this.doc,
    required this.pageNumber,
  });

  @override
  State<_PdfPageWidget> createState() => _PdfPageWidgetState();
}

class _PdfPageWidgetState extends State<_PdfPageWidget> {
  ui.Image? _image;
  String? _error;
  // Cached page dimensions so the placeholder matches the rendered
  // image size (prevents layout jump when the image arrives).
  double? _placeholderWidth;
  double? _placeholderHeight;

  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    try {
      // Render at the screen's device-pixel width. We use 2× the
      // logical width so the rendered image is crisp on retina
      // displays; `BoxFit.contain` in the build method then scales
      // it back to the actual display size.
      final screenWidth = MediaQuery.of(context).size.width;
      final renderWidth = (screenWidth * 2).round();
      // A4 / US Letter aspect ratio (~0.77). Most books in the
      // catalog are close to this; pages that differ will be
      // letterboxed by BoxFit.contain.
      final renderHeight = (renderWidth * 1.3).round();

      if (!mounted) return;
      setState(() {
        _placeholderWidth = screenWidth;
        _placeholderHeight = screenWidth * 1.3;
      });

      final page = widget.doc[widget.pageNumber];
      final pageImage = await page.render(
        x: 0,
        y: 0,
        width: renderWidth,
        height: renderHeight,
        fullWidth: renderWidth,
        fullHeight: renderHeight,
      );

      // Convert raw RGBA pixels to a Flutter ui.Image so we can
      // pass it to RawImage. This is the standard way to display
      // a pixel buffer in Flutter.
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        pageImage.pixels,
        pageImage.width,
        pageImage.height,
        ui.PixelFormat.rgba8888,
        (ui.Image img) => completer.complete(img),
      );
      final image = await completer.future;
      if (!mounted) return;
      setState(() {
        _image = image;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // While rendering, show a placeholder the same size as the
    // eventual image so the list doesn't shift when the image
    // arrives. The hairline border matches the rest of the
    // editorial system.
    if (_image == null) {
      final w = _placeholderWidth ?? MediaQuery.of(context).size.width;
      final h = _placeholderHeight ?? w * 1.3;
      return Container(
        width: w,
        height: h,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.rule, width: 1),
        ),
        child: Center(
          child: _error != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'PAGE ${widget.pageNumber + 1}  ·  RENDER ERROR\n\n$_error',
                    textAlign: TextAlign.center,
                    style: AppTheme.label.copyWith(color: AppTheme.accent),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    // Image rendered — display it. The Container's height is
    // derived from the image's actual aspect ratio so the page
    // is never letterboxed.
    final aspect = _image!.height / _image!.width;
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: AspectRatio(
        aspectRatio: aspect,
        child: RawImage(
          image: _image,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Bottom control bar — hairline top border, three slots:
///   left:  PAGE N OF M
///   right: N% (currentPage / (totalPages-1))
///   middle: hairline progress bar in the book's color
class _ReaderBottomBar extends StatelessWidget {
  final Book book;
  final int currentPage;
  final int totalPages;

  const _ReaderBottomBar({
    required this.book,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = totalPages > 1 ? currentPage / (totalPages - 1) : 0.0;
    final pct = (fraction * 100).round();
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
              Text(
                totalPages > 0
                    ? 'PAGE ${currentPage + 1} OF $totalPages'
                    : '—',
                style: AppTheme.labelSoft,
              ),
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
                widthFactor: fraction.clamp(0.0, 1.0),
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

/// Placeholder bottom bar (used while the PDF is loading) so the
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
///   - Copy page reference (e.g. "As a Man Thinketh — page 42 of 80")
class _ReaderMenu extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onJumpTop;
  final VoidCallback onJumpBottom;
  final VoidCallback onCopyPageRef;

  const _ReaderMenu({
    required this.currentPage,
    required this.totalPages,
    required this.onJumpTop,
    required this.onJumpBottom,
    required this.onCopyPageRef,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalPages > 1
        ? (currentPage / (totalPages - 1) * 100).round()
        : 0;
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
                Text('READER  ·  $progress%',
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
            _MenuRow(label: 'COPY PAGE REFERENCE', onTap: onCopyPageRef),
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
