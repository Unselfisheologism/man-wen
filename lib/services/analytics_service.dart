import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../dart_crash_reporter.dart';

/// Aggregated analytics data for the Man Wen home screen.
///
/// All counts and trends are computed from existing data sources:
///   - urge-surfing sessions (already persisted in SharedPreferences
///     by the urge-surfing screen)
///   - blocker enabled state + a few new counter prefs (fired /
///     disabled / relapse) that the blocker service can increment
///     as the user uses the app.
///
/// Counters that aren't wired up yet (blocker fired, blocker
/// disabled) return 0 — the UI shows them as 0 rather than hiding
/// the field, so it's obvious what to wire up next.
class AnalyticsService {
  // Pref keys (new — additive, won't break existing data)
  static const _sessionsKey = 'urge_surfing_sessions';
  static const _blockerFiredKey = 'blocker_fired_count';
  static const _blockerDisabledKey = 'blocker_disabled_count';
  static const _lastRelapseKey = 'last_relapse_at'; // ISO 8601
  static const _streakStartKey = 'streak_start_at';  // ISO 8601
  static const _bestStreakKey = 'best_streak_days';

  /// Aggregated snapshot — all reads in one call so the analytics
  /// screen can build a single render pass.
  ///
  /// Bulletproof: every read is wrapped in its own try-catch and a
  /// single failure yields a safe default snapshot. The page should
  /// always render *something*, even with no data.
  static Future<AnalyticsSnapshot> snapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = _readSessions(prefs);
      return AnalyticsSnapshot(
        urgeSessions: sessions,
        currentStreakDays: _currentStreakDays(prefs, sessions),
        bestStreakDays: _safeInt(prefs, _bestStreakKey),
        blockerFiredCount: _safeInt(prefs, _blockerFiredKey),
        blockerDisabledCount: _safeInt(prefs, _blockerDisabledKey),
      );
    } catch (e, s) {
      // Report but don't throw — the page must always render.
      // DartCrashReporter.report is void (fire-and-forget), so
      // don't await it — the previous commit did, which broke
      // the build ("type 'void' can't be used").
      try {
        DartCrashReporter.report('snapshot failed', e, s);
      } catch (_) {}
      return const AnalyticsSnapshot(
        urgeSessions: [],
        currentStreakDays: 0,
        bestStreakDays: 0,
        blockerFiredCount: 0,
        blockerDisabledCount: 0,
      );
    }
  }

  static int _safeInt(SharedPreferences prefs, String key) {
    try {
      return prefs.getInt(key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Increment a counter (used by the blocker service when it fires
  /// or when the user disables it). Failure-tolerant — never throws
  /// to the caller.
  static Future<void> incrementBlockerFired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = prefs.getInt(_blockerFiredKey) ?? 0;
      await prefs.setInt(_blockerFiredKey, n + 1);
    } catch (_) {}
  }

  static Future<void> incrementBlockerDisabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = prefs.getInt(_blockerDisabledKey) ?? 0;
      await prefs.setInt(_blockerDisabledKey, n + 1);
    } catch (_) {}
  }

  /// Mark a relapse — resets the current streak and updates the
  /// best streak if the previous one was longer.
  static Future<void> recordRelapse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final streakStart = _parseDate(prefs.getString(_streakStartKey));
      if (streakStart != null) {
        final prevDays = now.difference(streakStart).inDays;
        final best = prefs.getInt(_bestStreakKey) ?? 0;
        if (prevDays > best) {
          await prefs.setInt(_bestStreakKey, prevDays);
        }
      }
      await prefs.setString(_lastRelapseKey, now.toIso8601String());
      await prefs.setString(_streakStartKey, now.toIso8601String());
    } catch (_) {}
  }

  // ── Internal ──────────────────────────────────────────────────

  static List<UrgeSession> _readSessions(SharedPreferences prefs) {
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => UrgeSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Days since the last relapse (or since streak start if no
  /// relapse has been recorded). Returns 0 if there's no streak
  /// start recorded.
  static int _currentStreakDays(
    SharedPreferences prefs,
    List<UrgeSession> sessions,
  ) {
    final relapse = _parseDate(prefs.getString(_lastRelapseKey));
    final start = _parseDate(prefs.getString(_streakStartKey));

    // If we have sessions, treat the most-recent session timestamp
    // as an implicit "alive" signal — even if no relapse has been
    // recorded. The streak is days between (relapse or earliest
    // session) and now.
    DateTime? anchor = relapse ?? start;
    if (anchor == null && sessions.isNotEmpty) {
      // First time the analytics page sees sessions but no
      // relapse has been recorded yet — initialize the streak
      // anchor to the earliest session so subsequent visits are
      // stable. We can't await here, so just compute a value.
      final ts = sessions.map((s) => s.timestamp).reduce(
            (a, b) => a.isBefore(b) ? a : b,
          );
      anchor = ts;
    }
    if (anchor == null) return 0;
    final days = DateTime.now().difference(anchor).inDays;
    return days < 0 ? 0 : days;
  }

  static DateTime? _parseDate(String? iso) {
    if (iso == null) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }
}

class AnalyticsSnapshot {
  final List<UrgeSession> urgeSessions;
  final int currentStreakDays;
  final int bestStreakDays;
  final int blockerFiredCount;
  final int blockerDisabledCount;

  const AnalyticsSnapshot({
    required this.urgeSessions,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.blockerFiredCount,
    required this.blockerDisabledCount,
  });

  int get totalSessions => urgeSessions.length;

  /// Average drop in urge (0-10) from before to after a session.
  /// Returns null if no completed sessions exist.
  double? get averageUrgeDrop {
    final withDelta = urgeSessions
        .where((s) => s.initialUrge != null && s.finalUrge != null)
        .toList();
    if (withDelta.isEmpty) return null;
    final total = withDelta.fold<double>(
      0,
      (acc, s) => acc + ((s.initialUrge ?? 0) - (s.finalUrge ?? 0)),
    );
    return total / withDelta.length;
  }

  /// Count of urge sessions in the last [days] days.
  int sessionsInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return urgeSessions.where((s) => s.timestamp.isAfter(cutoff)).length;
  }

  /// Counts of urge sessions grouped by day for the last [days] days.
  /// Returns oldest → newest so the bar chart reads left-to-right.
  List<int> sessionsByDay(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = List<int>.filled(days, 0);
    for (final s in urgeSessions) {
      final d = DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      final diff = today.difference(d).inDays;
      if (diff >= 0 && diff < days) {
        result[days - 1 - diff] += 1; // right-align today
      }
    }
    return result;
  }

  /// Counts of urge sessions grouped by month for the last 12 months.
  /// Returns oldest → newest.
  List<int> sessionsByMonth() {
    final now = DateTime.now();
    final result = List<int>.filled(12, 0);
    for (final s in urgeSessions) {
      int monthsAgo = (now.year - s.timestamp.year) * 12 +
          (now.month - s.timestamp.month);
      if (monthsAgo >= 0 && monthsAgo < 12) {
        result[11 - monthsAgo] += 1;
      }
    }
    return result;
  }
}

/// Minimal session model — mirrors the persisted shape in
/// urge_surfing_screen.dart so we can decode it here without
/// circular imports.
class UrgeSession {
  final String technique;
  final DateTime timestamp;
  final int durationSeconds;
  final int? initialUrge;
  final int? finalUrge;

  const UrgeSession({
    required this.technique,
    required this.timestamp,
    required this.durationSeconds,
    this.initialUrge,
    this.finalUrge,
  });

  factory UrgeSession.fromJson(Map<String, dynamic> j) => UrgeSession(
        technique: j['technique'] as String? ?? 'unknown',
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        durationSeconds: (j['durationSeconds'] as num?)?.toInt() ?? 0,
        initialUrge: (j['initialUrge'] as num?)?.toInt(),
        finalUrge: (j['finalUrge'] as num?)?.toInt(),
      );
}
