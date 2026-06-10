import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/site_blocker_service.dart';
import '../widgets/streak_widget.dart';
import '../widgets/progress_widget.dart';
import 'site_blocker_settings_screen.dart';

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
              children: [
                const SizedBox(height: 16),
                const StreakWidget(),
                const SizedBox(height: 16),
                const ProgressWidget(),
                const SizedBox(height: 16),
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
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.notifications_active,
            title: 'Accountability',
            subtitle: 'Add partner',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Danger hours, sensitivity',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SiteBlockerTile extends StatefulWidget {
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
    final enabled = await SiteBlockerService.isEnabled();
    setState(() {
      _isEnabled = enabled;
      _blockedCount = SiteBlockerService.getBlockedSiteCount();
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

  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

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