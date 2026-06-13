import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/preferences_service.dart';
import '../services/site_blocker_service.dart';
import '../widgets/app_icons.dart';
import '../widgets/streak_widget.dart';
import '../widgets/progress_widget.dart';
import 'site_blocker_settings_screen.dart';
import 'urge_surfing_screen.dart';
import 'accountability_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Man Wen'),
            pinned: true,
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                SizedBox(height: 16),
                StreakWidget(),
                SizedBox(height: 16),
                ProgressWidget(),
                SizedBox(height: 16),
                _QuickActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _SiteBlockerTile(),
          _ActionTile(
            icon: Icon(Icons.air, size: 24, color: Theme.of(context).colorScheme.onSurface),
            title: 'Urge Surfing',
            subtitle: '4-7-8 breathing',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UrgeSurfingScreen()),
              );
            },
          ),
          _ActionTile(
            icon: AppIcons.bell(size: 24, color: Theme.of(context).colorScheme.onSurface),
            title: 'Accountability',
            subtitle: 'Add partner',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountabilityScreen()),
              );
            },
          ),
          _ActionTile(
            icon: AppIcons.gear(size: 24, color: Theme.of(context).colorScheme.onSurface),
            title: 'Settings',
            subtitle: 'Danger hours, sensitivity',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

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
      // SharedPreferences can throw if the platform plugin response is
      // malformed. Fall through with defaults.
    }
    if (!mounted) return;
    setState(() {
      _isEnabled = enabled;
      _blockedCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Surface is always a light tint (green.shade50 / grey.shade100) to
    // signal enabled/disabled state. Default theme text would be white
    // in dark mode and disappear on these light backgrounds — so we
    // force explicit dark colors that read in both themes.
    final iconColor =
        _isEnabled ? Colors.green.shade700 : Colors.grey.shade700;
    return Card(
      color: _isEnabled ? Colors.green.shade50 : Colors.grey.shade100,
      child: ListTile(
        textColor: Colors.black87,
        iconColor: iconColor,
        leading: AppIcons.shieldWarning(size: 28, color: iconColor),
        title: const Text('Site Blocker'),
        subtitle: Text(
          _isEnabled
              ? 'Blocking $_blockedCount adult sites'
              : '$_blockedCount sites available to block',
        ),
        trailing: Icon(Icons.chevron_right, color: iconColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SiteBlockerSettingsScreen(),
            ),
          ).then((_) => _loadStatus());
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
