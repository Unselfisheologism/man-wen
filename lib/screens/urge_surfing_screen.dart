import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Full implementation of the Urge Surfing feature. Surfaces the 4
/// techniques the Kotlin-side UrgeSurfingManager already declares
/// (4-7-8 Breathing, Cold Shower, Push-up Challenge, Walk Outside)
/// in a real Dart UI: technique picker, pre-session urge prompt,
/// running timer, post-session urge prompt, history saved to
/// SharedPreferences.
class UrgeSurfingScreen extends StatefulWidget {
  const UrgeSurfingScreen({super.key});

  @override
  State<UrgeSurfingScreen> createState() => _UrgeSurfingScreenState();
}

class _UrgeSurfingScreenState extends State<UrgeSurfingScreen> {
  static const _historyKey = 'urge_surfing_sessions';

  // Technique picker state
  final Map<String, _Technique> _techniques = {
    '4-7-8 Breathing': _Technique(
      icon: PhosphorIcons.wind(PhosphorIconsStyle.regular),
      description:
          'Inhale 4s, hold 7s, exhale 8s. Repeat for 2-5 minutes — '
          'slows your heart rate and gives the urge time to peak and pass.',
      recommendedSeconds: 180,
    ),
    'Cold Shower': _Technique(
      icon: PhosphorIcons.shower(PhosphorIconsStyle.regular),
      description:
          '30-60 seconds of cold water on your face and body. Activates '
          'the mammalian dive reflex — a hard physiological reset.',
      recommendedSeconds: 60,
    ),
    'Push-up Challenge': _Technique(
      icon: PhosphorIcons.barbell(PhosphorIconsStyle.regular),
      description:
          'Drop and do as many push-ups as you can (target 20-50). '
          'Physical exhaustion depletes the urge, and the endorphin '
          'afterglow lasts 20+ minutes.',
      recommendedSeconds: 180,
    ),
    'Walk Outside': _Technique(
      icon: PhosphorIcons.personSimpleWalk(PhosphorIconsStyle.regular),
      description:
          'Leave the room you\'re in. A 10-15 minute walk, ideally '
          'outdoors. The change of scenery and physical movement breaks '
          'the rumination loop the urge feeds on.',
      recommendedSeconds: 900,
    ),
  );

  // Active session state. null = on the technique picker screen.
  String? _activeTechniqueKey;
  DateTime? _startTime;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  int _initialUrge = 5;
  int _finalUrge = 5;
  bool _completing = false;

  // History
  List<UrgeSession> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _history = list
            .map((e) => UrgeSession.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      // Corrupt history — ignore, will be overwritten on next save.
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_history.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, json);
    } catch (_) {
      // Persistence is best-effort.
    }
  }

  void _pickTechnique(String key) {
    setState(() {
      _activeTechniqueKey = key;
      _startTime = null;
      _elapsed = Duration.zero;
      _initialUrge = 5;
      _finalUrge = 5;
      _completing = false;
    });
  }

  void _backToPicker() {
    _ticker?.cancel();
    setState(() {
      _activeTechniqueKey = null;
      _startTime = null;
      _elapsed = Duration.zero;
      _initialUrge = 5;
      _finalUrge = 5;
      _completing = false;
    });
  }

  void _startSession() {
    setState(() {
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime == null) return;
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
      });
    });
  }

  void _showCompletePrompt() {
    _ticker?.cancel();
    setState(() {
      _completing = true;
    });
  }

  Future<void> _saveSession() async {
    if (_activeTechniqueKey == null || _startTime == null) return;
    final session = UrgeSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      technique: _activeTechniqueKey!,
      startTime: _startTime!,
      endTime: DateTime.now(),
      initialUrge: _initialUrge,
      finalUrge: _finalUrge,
    );
    setState(() {
      _history.insert(0, session);
    });
    await _saveHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          session.wasSuccessful
              ? 'Session saved. ${session.duration.inSeconds}s — urge dropped ${session.urgeDelta}.'
              : 'Session saved. ${session.duration.inSeconds}s — urge held steady.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    _backToPicker();
  }

  void _cancelSession() {
    _ticker?.cancel();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session cancelled.'),
        duration: Duration(seconds: 2),
      ),
    );
    _backToPicker();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_activeTechniqueKey == null) {
      return _buildPicker();
    }
    if (_startTime == null) {
      return _buildInitialUrgePrompt();
    }
    if (_completing) {
      return _buildFinalUrgePrompt();
    }
    return _buildActiveSession();
  }

  Widget _buildPicker() {
    return Scaffold(
      appBar: AppBar(title: const Text('Urge Surfing')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Ride out the urge. It always passes.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Pick a technique. Most urges lose 50% of their intensity '
                'within 90 seconds and disappear within 5 minutes — you '
                'just have to outlast the wave.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ..._techniques.entries.map((entry) {
              final t = entry.value;
              return Card(
                child: ListTile(
                  leading: Icon(t.icon, size: 32, color: Theme.of(context).colorScheme.primary),
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(t.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickTechnique(entry.key),
                ),
              );
            }),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Recent sessions (${_history.length})',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._history.take(5).map((s) => _HistoryTile(session: s)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitialUrgePrompt() {
    final t = _techniques[_activeTechniqueKey!]!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_activeTechniqueKey!),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _backToPicker),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(t.icon, size: 96, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(t.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 32),
              const Text('How strong is the urge right now?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('$_initialUrge / 10',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              Slider(
                value: _initialUrge.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$_initialUrge',
                onChanged: (v) => setState(() => _initialUrge = v.round()),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _startSession,
                icon: Icon(PhosphorIcons.play(PhosphorIconsStyle.regular)),
                label: const Text('Start session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSession() {
    final t = _techniques[_activeTechniqueKey!]!;
    final progress = (_elapsed.inSeconds / t.recommendedSeconds).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: Text(_activeTechniqueKey!),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancelSession),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Icon(t.icon, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              const Text('Breathe. You\'re doing this.',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 32),
              Text(_formatDuration(_elapsed),
                  style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w200)),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 8),
              Text('Target: ${(t.recommendedSeconds / 60).toStringAsFixed(1)} min',
                  style: const TextStyle(color: Colors.grey)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showCompletePrompt,
                icon: const Icon(Icons.check),
                label: const Text('I made it through'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalUrgePrompt() {
    final delta = _initialUrge - _finalUrge;
    return Scaffold(
      appBar: AppBar(
        title: Text(_activeTechniqueKey!),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
          setState(() => _completing = false);
          _startSession();  // resume the timer if they go back
        }),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.check_circle, size: 96, color: Colors.green),
              const SizedBox(height: 24),
              const Text('How strong is the urge now?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('$_finalUrge / 10',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              Slider(
                value: _finalUrge.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$_finalUrge',
                onChanged: (v) => setState(() => _finalUrge = v.round()),
              ),
              const SizedBox(height: 16),
              if (delta > 0)
                Text('Urge dropped by $delta points — that\'s a win.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.green, fontSize: 16))
              else if (delta == 0)
                const Text('Urge held steady. You still won — you didn\'t give in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange, fontSize: 16))
              else
                Text('Urge is higher. That happens. Try again next time.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saveSession,
                icon: Icon(PhosphorIcons.floppyDisk(PhosphorIconsStyle.regular)),
                label: const Text('Save session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Technique {
  final IconData icon;
  final String description;
  final int recommendedSeconds;
  _Technique({required this.icon, required this.description, required this.recommendedSeconds});
}

class _HistoryTile extends StatelessWidget {
  final UrgeSession session;
  const _HistoryTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final delta = session.urgeDelta;
    final color = delta > 0 ? Colors.green : (delta == 0 ? Colors.orange : Colors.grey);
    return ListTile(
      dense: true,
      leading: Icon(
        session.wasSuccessful ? Icons.check_circle : Icons.cancel,
        color: color,
      ),
      title: Text(session.technique),
      subtitle: Text(
        '${session.formattedDate}  •  ${session.duration.inSeconds}s  •  urge ${session.initialUrge}→${session.finalUrge}',
      ),
    );
  }
}

class UrgeSession {
  final String id;
  final String technique;
  final DateTime startTime;
  final DateTime endTime;
  final int initialUrge;
  final int finalUrge;

  UrgeSession({
    required this.id,
    required this.technique,
    required this.startTime,
    required this.endTime,
    required this.initialUrge,
    required this.finalUrge,
  });

  Duration get duration => endTime.difference(startTime);
  int get urgeDelta => initialUrge - finalUrge;
  bool get wasSuccessful => duration.inSeconds >= 60; // any session >= 1 min counts

  String get formattedDate {
    final m = startTime.month.toString().padLeft(2, '0');
    final d = startTime.day.toString().padLeft(2, '0');
    final h = startTime.hour.toString().padLeft(2, '0');
    final min = startTime.minute.toString().padLeft(2, '0');
    return '$m/$d $h:$min';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'technique': technique,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'initialUrge': initialUrge,
        'finalUrge': finalUrge,
      };

  factory UrgeSession.fromJson(Map<String, dynamic> j) => UrgeSession(
        id: j['id'] as String,
        technique: j['technique'] as String,
        startTime: DateTime.fromMillisecondsSinceEpoch(j['startTime'] as int),
        endTime: DateTime.fromMillisecondsSinceEpoch(j['endTime'] as int),
        initialUrge: j['initialUrge'] as int,
        finalUrge: j['finalUrge'] as int,
      );
}
