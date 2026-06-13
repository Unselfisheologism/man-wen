import 'package:flutter/material.dart';
import '../services/site_blocker_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/streak_widget.dart';
import '../widgets/progress_widget.dart';
import 'site_blocker_settings_screen.dart';
import 'urge_surfing_screen.dart';
import 'accountability_screen.dart';
import 'settings_screen.dart';
import 'analytics_screen.dart';

/// Home — the editorial spread, now in color.
///
/// Composition follows the user's Pinterest-board pattern of
/// "each card its own color" (image 38 library grid, image 40
/// calendar where each day is a different color). The page is
/// still the cream paper — the colors live in the action cards
/// and the spectrum row, so the editorial typography still reads
/// on its muted background.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // 01 // HOME ─────────────────────────────────────
              const _Masthead(),
              Container(
                height: 1,
                color: AppTheme.rule,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 8),

              // 02 // CURRENT STREAK ───────────────────────────
              const StreakWidget(),

              // 03 // PROTECTION (this week) ──────────────────
              const SectionHeader(number: '03', label: 'PROTECTION'),
              Container(
                height: 1,
                color: AppTheme.rule,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 16),
              const ProgressWidget(),

              // 04 // ACTIONS — one colored card per action ────
              const SectionHeader(number: '04', label: 'ACTIONS'),
              Container(
                height: 1,
                color: AppTheme.rule,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 16),

              const _SiteBlockerCard(),
              const SizedBox(height: 8),
              _ColorCard(
                number: '04·02',
                color: AppTheme.catUrge,
                iconWidget: const Icon(Icons.air, size: 22, color: AppTheme.paper),
                title: 'URGE SURFING',
                subtitle:
                    '4-7-8 BREATHING  ·  COLD WATER  ·  PUSH-UPS  ·  WALK',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UrgeSurfingScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _ColorCard(
                number: '04·03',
                color: AppTheme.catAccount,
                iconWidget: AppIcons.bell(size: 22, color: AppTheme.paper),
                title: 'ACCOUNTABILITY',
                subtitle: 'TRUSTED PARTNER  ·  RELAPSE NOTIFICATIONS',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccountabilityScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _ColorCard(
                number: '04·04',
                color: AppTheme.catSetting,
                iconWidget: AppIcons.gear(size: 22, color: AppTheme.paper),
                title: 'SETTINGS',
                subtitle: 'DANGER HOURS  ·  SENSITIVITY  ·  HAPTICS',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _ColorCard(
                number: '04·05',
                color: AppTheme.catStats,
                iconWidget: const Icon(Icons.bar_chart, size: 22, color: AppTheme.paper),
                title: 'ANALYTICS',
                subtitle: 'STREAKS  ·  URGES  ·  BLOCKER  ·  SESSIONS',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                ),
              ),
              const SizedBox(height: 4),

              // 05 // STATUS — a row of small category swatches ─
              const SectionHeader(number: '05', label: 'STATUS'),
              Container(
                height: 1,
                color: AppTheme.rule,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // 4 category swatches + 1 active dot
                    _Swatch(color: AppTheme.catBlocker),
                    _Swatch(color: AppTheme.catUrge),
                    _Swatch(color: AppTheme.catAccount),
                    _Swatch(color: AppTheme.catSetting),
                    const SizedBox(width: 16),
                    Text('ARMED',
                        style: AppTheme.label
                            .copyWith(color: AppTheme.ink)),
                    const Spacer(),
                    Text('v2.0.0  ·  MAN WEN', style: AppTheme.labelSoft),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// 01 // HOME  — the masthead. Big editorial display title, version
/// stamp on the right, hairline rule below.
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
              Text('01 // HOME',
                  style: AppTheme.label.copyWith(color: AppTheme.inkSoft)),
              Text('v2.0.0', style: AppTheme.labelSoft),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'MAN WEN',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              height: 0.95,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text('QUIT.  STAY CLEAN.',
              style: AppTheme.label.copyWith(color: AppTheme.inkSoft)),
        ],
      ),
    );
  }
}

/// 4px colored square — the status swatch at the bottom of the home
/// screen. Each swatch echoes one of the action card colors so the
/// palette reads end-to-end.
class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(width: 10, height: 10, color: color),
    );
  }
}

/// A solid-color action card. All text in `paper` (cream) on the
/// category color. The card is full-width, no hairline, no rounded
/// corners — the color block IS the visual.
class _ColorCard extends StatelessWidget {
  final String number;
  final Color color;
  final Widget iconWidget;
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback onTap;

  const _ColorCard({
    required this.number,
    required this.color,
    required this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: color,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number column — mono, on color
              SizedBox(
                width: 56,
                child: Text(
                  number,
                  style: AppTheme.label.copyWith(
                    color: AppTheme.paper.withOpacity(0.75),
                  ),
                ),
              ),
              // Icon
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 16),
                child: iconWidget,
              ),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.sectionTitle.copyWith(
                        fontSize: 17,
                        color: AppTheme.paper,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: AppTheme.labelSoft.copyWith(
                        color: AppTheme.paper.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              // Status tag (optional)
              if (status != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Text(
                    status!,
                    style: AppTheme.label.copyWith(color: AppTheme.paper),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Site Blocker — the first action card. Stateful because the
/// enabled/blocked-count values come from native prefs.
class _SiteBlockerCard extends StatefulWidget {
  const _SiteBlockerCard();

  @override
  State<_SiteBlockerCard> createState() => _SiteBlockerCardState();
}

class _SiteBlockerCardState extends State<_SiteBlockerCard> {
  bool _isEnabled = false;
  int _blockedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    bool enabled = false;
    int count = 0;
    try {
      enabled = await SiteBlockerService.isEnabled();
      count = SiteBlockerService.getBlockedSiteCount();
    } catch (_) {
      // SharedPreferences can throw — fall through with defaults.
    }
    if (!mounted) return;
    setState(() {
      _isEnabled = enabled;
      _blockedCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SiteBlockerSettingsScreen(),
            ),
          ).then((_) => _loadStatus());
        },
        child: Container(
          color: AppTheme.catBlocker,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  '04·01',
                  style: AppTheme.label.copyWith(
                    color: AppTheme.paper.withOpacity(0.75),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 16),
                child: AppIcons.shieldWarning(size: 22, color: AppTheme.paper),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SITE BLOCKER',
                      style: AppTheme.sectionTitle.copyWith(
                        fontSize: 17,
                        color: AppTheme.paper,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isEnabled
                          ? 'BLOCKING $_blockedCount ADULT SITES'
                          : '$_blockedCount SITES AVAILABLE TO BLOCK',
                      style: AppTheme.labelSoft.copyWith(
                        color: AppTheme.paper.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Text(
                  _isEnabled ? 'ACTIVE' : 'OFF',
                  style: AppTheme.label.copyWith(color: AppTheme.paper),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
