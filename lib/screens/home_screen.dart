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

/// Home — the editorial spread.
///
/// Composition follows the Pinterest-board pattern: numbered sections
/// (`01 // HOME`, `02 // CURRENT STREAK`, ...), mono labels,
/// hairline rules between every section, no rounded corners, one
/// accent color (faded brick) used sparingly for status.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              SizedBox(height: 16),

              // 01 // HOME ─────────────────────────────────────
              _Masthead(),
              Container(height: 1, color: AppTheme.rule),
              const SizedBox(height: 24),

              // 02 // CURRENT STREAK ───────────────────────────
              StreakWidget(),

              // 03 // PROTECTION (this week) ──────────────────
              SectionHeader(number: '03', label: 'PROTECTION'),
              Container(
                height: 1,
                color: AppTheme.rule,
                margin: EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 16),
              ProgressWidget(),

              // 04 // ACTIONS ──────────────────────────────────
              SectionHeader(number: '04', label: 'ACTIONS'),
              Container(
                height: 1,
                color: AppTheme.rule,
                margin: EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 8),

              _SiteBlockerTile(),
              const _Hairline(),
              _ActionRow(
                number: '04·02',
                icon: Icon(Icons.air, size: 20, color: AppTheme.ink),
                title: 'URGE SURFING',
                subtitle: '4-7-8 BREATHING  ·  COLD WATER  ·  PUSH-UPS  ·  WALK',
                onTap: _openUrgeSurfing,
              ),
              const _Hairline(),
              _ActionRow(
                number: '04·03',
                icon: AppIcons.bell(size: 20, color: AppTheme.ink),
                title: 'ACCOUNTABILITY',
                subtitle: 'TRUSTED PARTNER  ·  RELAPSE NOTIFICATIONS',
                onTap: _openAccountability,
              ),
              const _Hairline(),
              _ActionRow(
                number: '04·04',
                icon: AppIcons.gear(size: 20, color: AppTheme.ink),
                title: 'SETTINGS',
                subtitle: 'DANGER HOURS  ·  SENSITIVITY  ·  HAPTICS',
                onTap: _openSettings,
              ),

              // 05 // STATUS ───────────────────────────────────
              SectionHeader(number: '05', label: 'STATUS'),
              Container(
                height: 1,
                color: AppTheme.rule,
                margin: EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 12),
                    Text('ARMED', style: AppTheme.label.copyWith(color: AppTheme.accent)),
                    const Spacer(),
                    Text('v2.0.0  ·  MAN WEN', style: AppTheme.labelSoft),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static void _openUrgeSurfing(BuildContext c) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => const UrgeSurfingScreen()));
  }

  static void _openAccountability(BuildContext c) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => const AccountabilityScreen()));
  }

  static void _openSettings(BuildContext c) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
          // Top row: 01 // HOME         v2.0.0.001
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('01 // HOME', style: AppTheme.label.copyWith(color: AppTheme.inkSoft)),
              Text('v2.0.0', style: AppTheme.labelSoft),
            ],
          ),
          const SizedBox(height: 16),
          // Big display title
          const Text('MAN WEN', style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
            height: 0.95,
            color: AppTheme.ink,
          )),
          const SizedBox(height: 8),
          Text('QUIT.  STAY CLEAN.', style: AppTheme.label.copyWith(color: AppTheme.inkSoft)),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppTheme.rule,
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}

/// Row in the actions list. `04·01 SITE BLOCKER  [ACTIVE]` — number
/// on the left in mono, title in bold sans, status tag on the right
/// in mono (color = accent for active, muted for inactive).
class _ActionRow extends StatelessWidget {
  final String number;
  final Widget icon;
  final String title;
  final String subtitle;
  final String? status;
  final bool statusAccent;
  final VoidCallback onTap;

  const _ActionRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.status,
    this.statusAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number column
            SizedBox(
              width: 56,
              child: Text(
                number,
                style: AppTheme.label.copyWith(color: AppTheme.inkMuted),
              ),
            ),
            // Icon
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 16),
              child: icon,
            ),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.sectionTitle.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: AppTheme.labelSoft),
                ],
              ),
            ),
            // Status tag
            if (status != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Text(
                  status!,
                  style: AppTheme.label.copyWith(
                    color: statusAccent ? AppTheme.accent : AppTheme.inkMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The Site Blocker tile — stateful because it reads native prefs.
/// Shown as the first row in the actions list, before the static
/// `_ActionRow`s.
class _SiteBlockerTile extends StatefulWidget {
  const _SiteBlockerTile();

  @override
  State<_SiteBlockerTile> createState() => _SiteBlockerTileState();
}

class _SiteBlockerTileState extends State<_SiteBlockerTile> {
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
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SiteBlockerSettingsScreen(),
          ),
        ).then((_) => _loadStatus());
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                '04·01',
                style: AppTheme.label.copyWith(color: AppTheme.inkMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 16),
              child: AppIcons.shieldWarning(
                size: 20,
                color: _isEnabled ? AppTheme.ink : AppTheme.inkMuted,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SITE BLOCKER',
                    style: AppTheme.sectionTitle.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isEnabled
                        ? 'BLOCKING $_blockedCount ADULT SITES'
                        : '$_blockedCount SITES AVAILABLE TO BLOCK',
                    style: AppTheme.labelSoft,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: Text(
                _isEnabled ? 'ACTIVE' : 'OFF',
                style: AppTheme.label.copyWith(
                  color: _isEnabled ? AppTheme.accent : AppTheme.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
