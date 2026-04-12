import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _alarmsEnabled = true;
  int _snoozeDuration = 10;
  bool _escalationEnabled = true;
  int _escalationDelay = 10;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alarmsEnabled = prefs.getBool('alarms_enabled') ?? true;
      _snoozeDuration = prefs.getInt('snooze_duration') ?? 10;
      _escalationEnabled = prefs.getBool('escalation_enabled') ?? true;
      _escalationDelay = prefs.getInt('escalation_delay') ?? 10;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarms_enabled', _alarmsEnabled);
    await prefs.setInt('snooze_duration', _snoozeDuration);
    await prefs.setBool('escalation_enabled', _escalationEnabled);
    await prefs.setInt('escalation_delay', _escalationDelay);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Alarm Section
          _sectionTitle('Alarm & Reminders'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Alarms'),
                  subtitle: const Text('Turn off to silence all medicine reminders'),
                  value: _alarmsEnabled,
                  onChanged: (v) {
                    setState(() => _alarmsEnabled = v);
                    _saveSettings();
                  },
                  secondary: Icon(Icons.alarm, color: _alarmsEnabled ? Theme.of(context).primaryColor : Colors.grey),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.snooze),
                  title: const Text('Snooze Duration'),
                  subtitle: Text('$_snoozeDuration minutes'),
                  trailing: DropdownButton<int>(
                    value: _snoozeDuration,
                    underline: const SizedBox(),
                    items: [5, 10, 15, 20, 30].map((v) => DropdownMenuItem(
                      value: v,
                      child: Text('$v min'),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _snoozeDuration = v);
                        _saveSettings();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Escalation Section
          _sectionTitle('Family Escalation'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Escalation'),
                  subtitle: const Text('Alert family if medicine is not taken'),
                  value: _escalationEnabled,
                  onChanged: (v) {
                    setState(() => _escalationEnabled = v);
                    _saveSettings();
                  },
                  secondary: Icon(Icons.family_restroom, color: _escalationEnabled ? Colors.orange : Colors.grey),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Escalation Delay'),
                  subtitle: Text('Alert family after $_escalationDelay minutes'),
                  trailing: DropdownButton<int>(
                    value: _escalationDelay,
                    underline: const SizedBox(),
                    items: [5, 10, 15, 20].map((v) => DropdownMenuItem(
                      value: v,
                      child: Text('$v min'),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _escalationDelay = v);
                        _saveSettings();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About Section
          _sectionTitle('About'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                  title: const Text('Aaspaas'),
                  subtitle: const Text('Family-connected Medicine Reminder'),
                  trailing: const Text('v1.0.0', style: TextStyle(color: Colors.grey)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.favorite, color: Colors.red.shade300),
                  title: const Text('Made with love for families'),
                  subtitle: const Text('Caring for your loved ones, together'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
