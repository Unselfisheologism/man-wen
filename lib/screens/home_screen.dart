import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/preferences_service.dart';
import '../services/site_blocker_service.dart';
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
            icon: Icons.air,
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
            icon: Icons.notifications_active,
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
            icon: Icons.settings,
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
    return Card(
      color: _isEnabled ? Colors.green.shade50 : Colors.grey.shade100,
      child: ListTile(
        leading: Icon(
          _isEnabled ? Icons.shield : Icons.shield_outlined,
          color: _isEnabled ? Colors.green : Colors.grey,
        ),
        title: const Text('Site Blocker'),
        subtitle: Text(
          _isEnabled
              ? 'Blocking $_blockedCount adult sites'
              : '$_blockedCount sites available to block',
        ),
        trailing: const Icon(Icons.chevron_right),
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
  final IconData icon;
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
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
