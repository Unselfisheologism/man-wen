import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/site_blocker_service.dart';

class SiteBlockerSettingsScreen extends StatefulWidget {
  const SiteBlockerSettingsScreen({super.key});

  @override
  State<SiteBlockerSettingsScreen> createState() => _SiteBlockerSettingsScreenState();
}

class _SiteBlockerSettingsScreenState extends State<SiteBlockerSettingsScreen> {
  bool _isEnabled = false;
  bool _isLoading = true;
  final TextEditingController _customSiteController = TextEditingController();
  List<String> _customSites = [];
  bool _showBlocklist = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await SiteBlockerService.isEnabled();
    setState(() {
      _isEnabled = enabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleBlocker(bool value) async {
    setState(() => _isEnabled = value);
    await SiteBlockerService.setEnabled(value);
    
    if (value) {
      // Notify native platform to start blocking
      await MethodChannel('com.manwen.app/manwen').invokeMethod('startSiteBlocking');
    } else {
      await MethodChannel('com.manwen.app/manwen').invokeMethod('stopSiteBlocking');
    }
  }

  Future<void> _addCustomSite() async {
    final site = _customSiteController.text.trim();
    if (site.isEmpty) return;
    
    String formattedSite = site;
    if (!formattedSite.startsWith('http://') && !formattedSite.startsWith('https://')) {
      formattedSite = formattedSite.replaceFirst(RegExp(r'^www\.'), '');
    }
    
    setState(() {
      _customSites.add(formattedSite);
      _customSiteController.clear();
    });
    await SiteBlockerService.saveCustomSites(_customSites);
  }

  Future<void> _removeCustomSite(String site) async {
    setState(() {
      _customSites.remove(site);
    });
    await SiteBlockerService.saveCustomSites(_customSites);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Blocker'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Master Switch
                SwitchListTile(
                  title: const Text('Enable Site Blocking'),
                  subtitle: Text(
                    _isEnabled 
                        ? 'Blocking ${SiteBlockerService.getBlockedSiteCount()} sites'
                        : 'Site blocking is disabled',
                  ),
                  value: _isEnabled,
                  onChanged: _toggleBlocker,
                ),
                const Divider(),

                // Info Card
                if (_isEnabled)
                  Card(
                    margin: const EdgeInsets.all(16),
                    color: Colors.green.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Protection Active',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Adult and NSFW sites are being blocked. '
                            'If you need to access a legitimate site that '
                            'happens to be on the list, you can add custom '
                            'exceptions below.',
                          ),
                        ],
                      ),
                    ),
                  ),

                // Custom Sites Section
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Add Custom Site to Block'),
                  subtitle: const Text('Block a specific domain or subdomain'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customSiteController,
                          decoration: const InputDecoration(
                            hintText: 'example.com',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.url,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addCustomSite,
                      ),
                    ],
                  ),
                ),

                // Custom Sites List
                if (_customSites.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Custom Blocked Sites:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._customSites.map((site) => ListTile(
                    leading: const Icon(Icons.block, color: Colors.red),
                    title: Text(site),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeCustomSite(site),
                    ),
                  )),
                ],

                const Divider(),

                // Blocklist Toggle
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('View Full Blocklist'),
                  subtitle: Text('${SiteBlockerService.defaultBlocklist.length} sites'),
                  trailing: Icon(
                    _showBlocklist ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() => _showBlocklist = !_showBlocklist);
                  },
                ),

                // Expanded Blocklist
                if (_showBlocklist)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: SiteBlockerService.defaultBlocklist.length,
                      itemBuilder: (context, index) {
                        final site = SiteBlockerService.defaultBlocklist[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.block, size: 16, color: Colors.grey),
                          title: Text(
                            site,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 32),

                // Disclaimer
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Note: Site blocking works by intercepting DNS requests '
                    'on Android and using Content Blocker rules on iOS. '
                    'Some sites may use alternative domains or HTTPS DNS '
                    'which cannot be blocked by this method. For complete '
                    'blocking, consider using a device-level parental '
                    'control solution.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _customSiteController.dispose();
    super.dispose();
  }
}