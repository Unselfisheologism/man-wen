import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accountability partner management. The "social cost" of breaking a
/// streak is a strong lever for habit-change. The user adds one or
/// more trusted people (name + contact), and on a relapse the app
/// can be configured to ping them. This screen manages that list.
class AccountabilityScreen extends StatefulWidget {
  const AccountabilityScreen({super.key});

  @override
  State<AccountabilityScreen> createState() => _AccountabilityScreenState();
}

class _AccountabilityScreenState extends State<AccountabilityScreen> {
  static const _partnersKey = 'accountability_partners';
  static const _notifyOnRelapseKey = 'accountability_notify_on_relapse';

  List<AccountabilityPartner> _partners = [];
  bool _notifyOnRelapse = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_partnersKey);
      final list = (raw == null || raw.isEmpty) ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      final partners = list.map((e) => AccountabilityPartner.fromJson(e as Map<String, dynamic>)).toList();
      final notify = prefs.getBool(_notifyOnRelapseKey) ?? true;
      if (!mounted) return;
      setState(() {
        _partners = partners;
        _notifyOnRelapse = notify;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _partners = [];
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _partnersKey,
        jsonEncode(_partners.map((p) => p.toJson()).toList()),
      );
      await prefs.setBool(_notifyOnRelapseKey, _notifyOnRelapse);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _addPartner() async {
    final result = await showDialog<AccountabilityPartner>(
      context: context,
      builder: (ctx) => const _PartnerEditor(),
    );
    if (result == null) return;
    setState(() => _partners.add(result));
    await _save();
  }

  Future<void> _removePartner(int index) async {
    setState(() => _partners.removeAt(index));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accountability')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Trusted contacts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These people get pinged if you relapse. Pick someone '
                    'who actually cares and who you don\'t want to disappoint — '
                    'that\'s the whole point.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Notify on relapse'),
                    subtitle: const Text('Send a message automatically if a relapse is logged.'),
                    value: _notifyOnRelapse,
                    onChanged: (v) {
                      setState(() => _notifyOnRelapse = v);
                      _save();
                    },
                  ),
                  const Divider(),
                  if (_partners.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No partners yet.\nTap + to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._partners.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(p.name),
                          subtitle: Text('${p.contact}  •  ${p.channel.name}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removePartner(i),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addPartner,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add partner'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton(
              onPressed: _addPartner,
              child: const Icon(Icons.add),
            ),
    );
  }
}

class _PartnerEditor extends StatefulWidget {
  const _PartnerEditor();

  @override
  State<_PartnerEditor> createState() => _PartnerEditorState();
}

class _PartnerEditorState extends State<_PartnerEditor> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  ContactChannel _channel = ContactChannel.email;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty || _contact.text.trim().isEmpty) return;
    Navigator.of(context).pop(AccountabilityPartner(
      name: _name.text.trim(),
      contact: _contact.text.trim(),
      channel: _channel,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add accountability partner'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Mom, Alex, sponsor...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contact,
            decoration: InputDecoration(
              labelText: _channel == ContactChannel.email ? 'Email' : 'Phone',
              hintText: _channel == ContactChannel.email ? 'name@example.com' : '+1 555 123 4567',
            ),
            keyboardType: _channel == ContactChannel.email
                ? TextInputType.emailAddress
                : TextInputType.phone,
          ),
          const SizedBox(height: 12),
          SegmentedButton<ContactChannel>(
            segments: const [
              ButtonSegment(value: ContactChannel.email, icon: Icon(Icons.email), label: Text('Email')),
              ButtonSegment(value: ContactChannel.sms, icon: Icon(Icons.sms), label: Text('SMS')),
            ],
            selected: {_channel},
            onSelectionChanged: (s) => setState(() => _channel = s.first),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}

enum ContactChannel { email, sms }

class AccountabilityPartner {
  final String name;
  final String contact;
  final ContactChannel channel;

  AccountabilityPartner({
    required this.name,
    required this.contact,
    required this.channel,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'contact': contact,
        'channel': channel.name,
      };

  factory AccountabilityPartner.fromJson(Map<String, dynamic> j) => AccountabilityPartner(
        name: j['name'] as String,
        contact: j['contact'] as String,
        channel: ContactChannel.values.firstWhere(
          (e) => e.name == j['channel'],
          orElse: () => ContactChannel.email,
        ),
      );
}
