import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show themeModeNotifier;

/// Settings screen. Wires the existing PreferencesService plus a few
/// additional knobs (danger hours, blocking sensitivity) up to
/// persisted user preferences. The blocking sensitivity value matches
/// the AppPreferencesKeys.BLOCKING_SENSITIVITY / DANGER_HOURS_*
/// constants in AppPreferencesKeys.kt so future native code can read
/// them off the same keys.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Keys mirror the constants in AppPreferencesKeys.kt on the native side.
  static const _themeKey = 'settings_theme_mode';
  static const _dangerStartKey = 'danger_hours_start';
  static const _dangerEndKey = 'danger_hours_end';
  static const _sensitivityKey = 'blocking_sensitivity';
  static const _hapticsKey = 'settings_haptic_feedback';

  bool _loading = true;
  ThemeMode _themeMode = ThemeMode.system;
  TimeOfDay _dangerStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dangerEnd = const TimeOfDay(hour: 6, minute: 0);
  double _sensitivity = 0.75;
  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString(_themeKey) ?? 'system';
      final startH = prefs.getInt(_dangerStartKey) ?? 22;
      final endH = prefs.getInt(_dangerEndKey) ?? 6;
      final sens = prefs.getDouble(_sensitivityKey) ?? 0.75;
      final haptics = prefs.getBool(_hapticsKey) ?? true;
      if (!mounted) return;
      setState(() {
        _themeMode = ThemeMode.values.firstWhere(
          (e) => e.name == themeStr,
          orElse: () => ThemeMode.system,
        );
        _dangerStart = TimeOfDay(hour: startH, minute: 0);
        _dangerEnd = TimeOfDay(hour: endH, minute: 0);
        _sensitivity = sens;
        _haptics = haptics;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode.name);
      await prefs.setInt(_dangerStartKey, _dangerStart.hour);
      await prefs.setInt(_dangerEndKey, _dangerEnd.hour);
      await prefs.setDouble(_sensitivityKey, _sensitivity);
      await prefs.setBool(_hapticsKey, _haptics);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _dangerStart : _dangerEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _dangerStart = picked;
      } else {
        _dangerEnd = picked;
      }
    });
    await _saveAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const _SectionHeader('Appearance'),
                RadioListTile<ThemeMode>(
                  title: const Text('System default'),
                  value: ThemeMode.system,
                  groupValue: _themeMode,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _themeMode = v);
                    themeModeNotifier.value = v;
                    _saveAll();
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: _themeMode,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _themeMode = v);
                    themeModeNotifier.value = v;
                    _saveAll();
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: _themeMode,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _themeMode = v);
                    themeModeNotifier.value = v;
                    _saveAll();
                  },
                ),
                const Divider(),
                const _SectionHeader('Danger hours'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Hours of the day when urges hit hardest. We\'ll tighten '
                    'blocking and surface urge-surfing options more '
                    'aggressively during this window.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ListTile(
                  title: const Text('Start'),
                  trailing: Text(_dangerStart.format(context)),
                  onTap: () => _pickTime(isStart: true),
                ),
                ListTile(
                  title: const Text('End'),
                  trailing: Text(_dangerEnd.format(context)),
                  onTap: () => _pickTime(isStart: false),
                ),
                const Divider(),
                const _SectionHeader('Blocking sensitivity'),
                ListTile(
                  title: const Text('Threshold'),
                  subtitle: Text(
                    '${(_sensitivity * 100).round()}%  —  '
                    '${_sensitivity >= 0.8 ? "aggressive" : _sensitivity >= 0.5 ? "balanced" : "lenient"}',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Slider(
                    value: _sensitivity,
                    onChanged: (v) => setState(() => _sensitivity = v),
                    onChangeEnd: (_) => _saveAll(),
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                  ),
                ),
                const Divider(),
                const _SectionHeader('Feedback'),
                SwitchListTile(
                  title: const Text('Haptic feedback'),
                  subtitle: const Text('Vibrate on button presses and important events.'),
                  value: _haptics,
                  onChanged: (v) {
                    setState(() => _haptics = v);
                    _saveAll();
                  },
                ),
                const Divider(),
                const _SectionHeader('About'),
                const ListTile(
                  title: Text('Man Wen'),
                  subtitle: Text('Version 1.0.0'),
                ),
                const ListTile(
                  title: Text('Quit porn with site blocking and urge surfing.'),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
