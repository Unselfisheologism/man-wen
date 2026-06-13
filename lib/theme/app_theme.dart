import 'package:flutter/material.dart';

/// Design system: faded risograph / vintage almanac.
///
/// Palette extracted from the user's Pinterest board
/// (pinterest.com/jeffrinjames99/ui) — cream paper, dark warm ink,
/// ONE muted accent (faded brick), no neon, no glossy, no gradients.
/// Type is mixed: system sans for display, monospace for labels,
/// brackets and section numbers (the `[01] // TITLE` pattern that
/// recurs across the board).
class AppTheme {
  AppTheme._();

  // ── Surfaces ───────────────────────────────────────────────────
  /// Page background — warm cream, like aged paper.
  static const Color paper = Color(0xFFF4EFE6);

  /// Card / elevated surface — slightly lighter than the page so
  /// cards float without needing a shadow.
  static const Color surface = Color(0xFFFAF6F0);

  /// Hairline border — 8% opacity dark ink, looks like a printed rule.
  static const Color rule = Color(0x141A1A1A);

  // ── Ink ────────────────────────────────────────────────────────
  /// Primary text — warm dark, not pure black.
  static const Color ink = Color(0xFF1A1A1A);

  /// Secondary text — 60% ink.
  static const Color inkSoft = Color(0x991A1A1A);

  /// Tertiary text / captions — 35% ink.
  static const Color inkMuted = Color(0x591A1A1A);

  /// Disabled / placeholder — 18% ink.
  static const Color inkGhost = Color(0x2E1A1A1A);

  // ── Accent ─────────────────────────────────────────────────────
  /// Faded brick — the single accent for status, state, and one
  /// element per screen. Drawn from the maroon/terracotta tiles
  /// in the user's automotive + calendar pins.
  static const Color accent = Color(0xFFA85543);

  /// 8% accent for subtle background tints.
  static const Color accentSubtle = Color(0x14A85543);

  // ── Typography ────────────────────────────────────────────────
  /// Monospaced family for labels, section numbers, data.
  /// Resolved by the platform's `monospace` alias (Roboto Mono on
  /// Android, SF Mono on iOS, Menlo on macOS, Consolas on Windows).
  /// We deliberately don't bundle a font asset to keep the APK small.
  static const String mono = 'monospace';

  /// Display — large thin editorial number (e.g. the streak count).
  static const TextStyle display = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w200,
    height: 1,
    letterSpacing: -2.5,
    color: ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Display small — for sub-stats (best streak, relapses).
  static const TextStyle displaySmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    height: 1,
    letterSpacing: -0.5,
    color: ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Section title — bold sans, tight.
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: ink,
  );

  /// Body text.
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ink,
  );

  /// Mono label — uppercase, letter-spaced, for section numbers
  /// and status tags.
  static const TextStyle label = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.6,
    color: ink,
  );

  /// Mono label, soft (for description text in mono).
  static const TextStyle labelSoft = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 1.0,
    color: inkSoft,
  );

  /// Mono data — for the value side of stat cells.
  static const TextStyle data = TextStyle(
    fontFamily: mono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.4,
    color: ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ── Theme ──────────────────────────────────────────────────────
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  /// `light` is the canonical theme. We expose a dark variant so the
  /// Settings screen's `ThemeMode.system` still has something to fall
  /// back on, but it's the same palette inverted — no neon, no glossy.
  static ThemeData _build(Brightness b) {
    final isLight = b == Brightness.light;
    final bg = isLight ? paper : const Color(0xFF141413);
    final fg = isLight ? ink : const Color(0xFFEFE9DC);
    final fgSoft = fg.withOpacity(isLight ? 0.6 : 0.65);
    final rule = isLight ? rule : const Color(0x33EFE9DC);
    final cardSurface = isLight ? surface : const Color(0xFF1C1B19);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      canvasColor: bg,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: b,
        primary: accent,
        onPrimary: paper,
        secondary: accent,
        onSecondary: paper,
        surface: cardSurface,
        onSurface: fg,
        error: accent,
        onError: paper,
      ),
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        displayLarge: display.copyWith(color: fg),
        displaySmall: displaySmall.copyWith(color: fg),
        titleLarge: sectionTitle.copyWith(color: fg),
        bodyLarge: body.copyWith(color: fg),
        bodyMedium: body.copyWith(color: fgSoft, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: fg, size: 18),
        titleTextStyle: label.copyWith(color: fg),
        toolbarHeight: 52,
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(0)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: rule,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: fg, size: 18),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fg,
          foregroundColor: bg,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: label.copyWith(color: bg, fontSize: 11),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: fg,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
          textStyle: label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: rule, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: label,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: fg,
        textColor: fg,
        minVerticalPadding: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(0)),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
