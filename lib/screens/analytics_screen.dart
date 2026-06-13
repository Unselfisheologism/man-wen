import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_widget.dart';

/// Analytics — the home for "how is the quit going?"
///
/// Composition follows the same editorial register as the home
/// screen: numbered sections, mono labels, hairline rules, the
/// category palette. The bar charts use a single category color
/// (the analytics teal) so they read as one piece, with the
/// 4-quadrant overview tiles getting the full spectrum so each
/// metric has its own visual identity.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Future<AnalyticsSnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() => _future = AnalyticsService.snapshot());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<AnalyticsSnapshot>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.catStats));
            }
            if (snap.hasError || !snap.hasData) {
              return _ErrorState(onRetry: _refresh);
            }
            final s = snap.data!;
            return _AnalyticsBody(snapshot: s);
          },
        ),
      ),
    );
  }
}

class _AnalyticsBody extends StatefulWidget {
  final AnalyticsSnapshot snapshot;
  const _AnalyticsBody({required this.snapshot});

  @override
  State<_AnalyticsBody> createState() => _AnalyticsBodyState();
}

class _AnalyticsBodyState extends State<_AnalyticsBody> {
  _Period _period = _Period.week;

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _Masthead(snapshot: s),
          Container(
            height: 1,
            color: AppTheme.rule,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 8),

          // 02 // OVERVIEW — 4-up stat grid
          const SectionHeader(number: '02', label: 'OVERVIEW'),
          Container(
            height: 1,
            color: AppTheme.rule,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _OverviewGrid(snapshot: s),
          ),

          // 03 // ACTIVITY — period selector + bar chart
          const SectionHeader(number: '03', label: 'ACTIVITY'),
          Container(
            height: 1,
            color: AppTheme.rule,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 12),
          _PeriodSelector(
            current: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ActivityChart(snapshot: s, period: _period),
          ),

          // 04 // BLOCKER — blocker-specific stats
          const SectionHeader(number: '04', label: 'BLOCKER'),
          Container(
            height: 1,
            color: AppTheme.rule,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _BlockerStats(snapshot: s),
          ),

          // 05 // SESSIONS — recent urge-surfing sessions
          const SectionHeader(number: '05', label: 'SESSIONS'),
          Container(
            height: 1,
            color: AppTheme.rule,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 12),
          _RecentSessions(snapshot: s),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

/// 01 // ANALYTICS — masthead, with the snapshot's primary number
/// (current streak) shown as a display stat.
class _Masthead extends StatelessWidget {
  final AnalyticsSnapshot snapshot;
  const _Masthead({required this.snapshot});

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
              Text('01 // ANALYTICS',
                  style: AppTheme.label.copyWith(color: AppTheme.inkSoft)),
              Text('v1.0', style: AppTheme.labelSoft),
            ],
          ),
          const SizedBox(height: 12),
          // Primary metric: current streak, in editorial display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${snapshot.currentStreakDays}', style: AppTheme.display),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('DAYS CLEAN', style: AppTheme.label),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'BEST  ${snapshot.bestStreakDays}  ·  SESSIONS  ${snapshot.totalSessions}',
            style: AppTheme.labelSoft,
          ),
        ],
      ),
    );
  }
}

/// 4-up grid of overview stat tiles. Each tile is a mini-version
/// of the home action card: full-width-ish, mono label, big number,
/// category color band on the left as a "this is what kind of
/// stat" signal.
class _OverviewGrid extends StatelessWidget {
  final AnalyticsSnapshot snapshot;
  const _OverviewGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _OverviewTile(
        number: '01',
        color: AppTheme.catBlocker,
        label: 'CURRENT STREAK',
        value: '${snapshot.currentStreakDays}',
        unit: 'DAYS',
      ),
      _OverviewTile(
        number: '02',
        color: AppTheme.catUrge,
        label: 'URGE SESSIONS',
        value: '${snapshot.totalSessions}',
        unit: 'TOTAL',
      ),
      _OverviewTile(
        number: '03',
        color: AppTheme.catStats,
        label: 'SITES BLOCKED',
        value: '${snapshot.blockerFiredCount}',
        unit: 'TRIGGERED',
      ),
      _OverviewTile(
        number: '04',
        color: AppTheme.catSetting,
        label: 'BLOCKER OFF',
        value: '${snapshot.blockerDisabledCount}',
        unit: 'TIMES',
      ),
    ];
    return Column(
      children: [
        Row(children: [
          Expanded(child: tiles[0]),
          const SizedBox(width: 12),
          Expanded(child: tiles[1]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: tiles[2]),
          const SizedBox(width: 12),
          Expanded(child: tiles[3]),
        ]),
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  final String number;
  final Color color;
  final String label;
  final String value;
  final String unit;

  const _OverviewTile({
    required this.number,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: BorderSide(color: AppTheme.rule, width: 1),
          right: BorderSide(color: AppTheme.rule, width: 1),
          bottom: BorderSide(color: AppTheme.rule, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(number, style: AppTheme.label.copyWith(color: AppTheme.inkMuted)),
              Text(unit, style: AppTheme.labelSoft),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w300,
              height: 1,
              letterSpacing: -1,
              color: AppTheme.ink,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTheme.label),
        ],
      ),
    );
  }
}

enum _Period { day, week, month, year }

class _PeriodSelector extends StatelessWidget {
  final _Period current;
  final ValueChanged<_Period> onChanged;
  const _PeriodSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final p in _Period.values)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: p == _Period.values.last ? 0 : 8),
                child: _PeriodChip(
                  label: _label(p),
                  active: p == current,
                  onTap: () => onChanged(p),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _label(_Period p) {
    switch (p) {
      case _Period.day:
        return '01·DAY';
      case _Period.week:
        return '01·WEEK';
      case _Period.month:
        return '01·MONTH';
      case _Period.year:
        return '01·YEAR';
    }
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PeriodChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.ink : AppTheme.surface,
          border: Border.all(color: AppTheme.rule, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.label.copyWith(
            color: active ? AppTheme.paper : AppTheme.inkSoft,
          ),
        ),
      ),
    );
  }
}

/// 03 // ACTIVITY — the bar chart. Pulls the right series for the
/// selected period from the snapshot and renders as a row of
/// teal bars with mono labels underneath.
class _ActivityChart extends StatelessWidget {
  final AnalyticsSnapshot snapshot;
  final _Period period;
  const _ActivityChart({required this.snapshot, required this.period});

  @override
  Widget build(BuildContext context) {
    final series = _series();
    final maxVal = series.values.fold<int>(0, (a, b) => a > b ? a : b);
    final total = series.values.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.rule, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_periodLabel(period), style: AppTheme.label),
              Text(
                total == 0 ? 'NO DATA' : '$total TOTAL',
                style: AppTheme.data,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: total == 0
                ? const Center(
                    child: Text(
                      'NO SESSIONS LOGGED YET',
                      style: AppTheme.labelSoft,
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(series.values.length, (i) {
                      final v = series.values[i];
                      final h = maxVal == 0 ? 0.0 : (v / maxVal);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: i < series.values.length - 1 ? 4 : 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: double.infinity,
                                height: (110 * h).clamp(2, 110),
                                color: AppTheme.catStats,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: series.labels
                .map((l) => Expanded(
                      child: Text(
                        l,
                        textAlign: TextAlign.center,
                        style: AppTheme.labelSoft.copyWith(fontSize: 9),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _periodLabel(_Period p) {
    switch (p) {
      case _Period.day:
        return 'TODAY  ·  HOURLY';
      case _Period.week:
        return 'THIS WEEK  ·  DAILY';
      case _Period.month:
        return 'THIS YEAR  ·  MONTHLY';
      case _Period.year:
        return 'ALL TIME';
    }
  }

  _Series _series() {
    switch (period) {
      case _Period.day:
        // 24 hours, last 24h
        final now = DateTime.now();
        final counts = List<int>.filled(24, 0);
        for (final s in snapshot.urgeSessions) {
          final diff = now.difference(s.timestamp).inHours;
          if (diff >= 0 && diff < 24) counts[23 - diff] += 1;
        }
        return _Series(
          values: counts,
          labels: List.generate(24, (i) => i.toString()),
        );
      case _Period.week:
        final counts = snapshot.sessionsByDay(7);
        return _Series(
          values: counts,
          labels: const ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'],
        );
      case _Period.month:
        final counts = snapshot.sessionsByMonth();
        return _Series(
          values: counts,
          labels: const [
            'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
          ],
        );
      case _Period.year:
        return _Series(values: const [0], labels: const ['ALL']);
    }
  }
}

class _Series {
  final List<int> values;
  final List<String> labels;
  const _Series({required this.values, required this.labels});
}

/// 04 // BLOCKER — stats specific to the site blocker.
class _BlockerStats extends StatelessWidget {
  final AnalyticsSnapshot snapshot;
  const _BlockerStats({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _StatRow(
        color: AppTheme.catBlocker,
        label: 'TRIGGERED',
        value: '${snapshot.blockerFiredCount}',
        caption: 'TIMES THE BLOCKER FIRED',
      ),
      _StatRow(
        color: AppTheme.catSetting,
        label: 'DISABLED',
        value: '${snapshot.blockerDisabledCount}',
        caption: 'TIMES YOU TURNED IT OFF',
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1)
            Container(height: 1, color: AppTheme.rule),
        ],
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String caption;
  const _StatRow({
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 6, height: 28, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.label),
                const SizedBox(height: 2),
                Text(caption, style: AppTheme.labelSoft),
              ],
            ),
          ),
          Text(value, style: AppTheme.displaySmall),
        ],
      ),
    );
  }
}

/// 05 // SESSIONS — list of recent urge-surfing sessions, or
/// an empty state if there aren't any.
class _RecentSessions extends StatelessWidget {
  final AnalyticsSnapshot snapshot;
  const _RecentSessions({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final sessions = [...snapshot.urgeSessions]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.rule, width: 1),
          ),
          child: const Center(
            child: Text(
              'NO SESSIONS YET  ·  TRY THE URGES CARD',
              style: AppTheme.labelSoft,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (var i = 0; i < sessions.length && i < 8; i++) ...[
            _SessionRow(session: sessions[i]),
            if (i < sessions.length - 1 && i < 7)
              Container(height: 1, color: AppTheme.rule),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final UrgeSession session;
  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final drop = (session.initialUrge != null && session.finalUrge != null)
        ? (session.initialUrge! - session.finalUrge!)
        : null;
    final dropColor = drop == null
        ? AppTheme.inkMuted
        : (drop > 3
            ? AppTheme.catAccount
            : (drop > 0 ? AppTheme.catStats : AppTheme.inkMuted));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              _formatDate(session.timestamp),
              style: AppTheme.label.copyWith(color: AppTheme.inkMuted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.technique.toUpperCase(),
                    style: AppTheme.sectionTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${session.durationSeconds}s  ·  '
                  '${session.initialUrge ?? '–'} → ${session.finalUrge ?? '–'}',
                  style: AppTheme.labelSoft,
                ),
              ],
            ),
          ),
          if (drop != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dropColor,
              ),
              child: Text(
                drop > 0 ? '-$drop' : '${drop == 0 ? "±0" : "+${drop.abs()}"}',
                style: AppTheme.label.copyWith(color: AppTheme.paper),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime t) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${t.day.toString().padLeft(2, '0')} ${months[t.month - 1]}';
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('COULDN\'T LOAD ANALYTICS', style: AppTheme.label),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('RETRY')),
        ],
      ),
    );
  }
}
