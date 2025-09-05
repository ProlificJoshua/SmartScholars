import 'package:flutter/material.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/database/database_helper.dart';

class SystemSettingsScreen extends StatefulWidget {
  final UserModel user;

  const SystemSettingsScreen({super.key, required this.user});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool _allowRegistration = true;
  bool _enableNotifications = true;
  bool _enableGamification = true;
  bool _enableOfflineMode = true;
  bool _enableVoiceInput = true;
  bool _enableTranslation = true;
  bool _enablePlagiarismDetection = true;
  bool _autoBackup = true;
  
  String _defaultLanguage = 'English';
  String _systemTheme = 'Light';
  int _maxFileSize = 10; // MB
  int _sessionTimeout = 30; // minutes
  
  final List<String> _languages = ['English', 'French', 'Spanish'];
  final List<String> _themes = ['Light', 'Dark', 'System'];
  final List<int> _fileSizes = [5, 10, 25, 50, 100];
  final List<int> _timeouts = [15, 30, 60, 120];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ System Settings'),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSettings(),
            const SizedBox(height: 24),
            _buildFeatureSettings(),
            const SizedBox(height: 24),
            _buildSecuritySettings(),
            const SizedBox(height: 24),
            _buildSystemMaintenance(),
            const SizedBox(height: 24),
            _buildDangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSettingsSection(
      'General Settings',
      Icons.settings,
      [
        _buildDropdownSetting(
          'Default Language',
          _defaultLanguage,
          _languages,
          (value) => setState(() => _defaultLanguage = value!),
        ),
        _buildDropdownSetting(
          'System Theme',
          _systemTheme,
          _themes,
          (value) => setState(() => _systemTheme = value!),
        ),
        _buildSwitchSetting(
          'Allow New Registrations',
          'Enable new users to register accounts',
          _allowRegistration,
          (value) => setState(() => _allowRegistration = value),
        ),
        _buildSwitchSetting(
          'Enable Notifications',
          'Send push notifications to users',
          _enableNotifications,
          (value) => setState(() => _enableNotifications = value),
        ),
      ],
    );
  }

  Widget _buildFeatureSettings() {
    return _buildSettingsSection(
      'Feature Settings',
      Icons.extension,
      [
        _buildSwitchSetting(
          'Gamification System',
          'Enable points, levels, and badges',
          _enableGamification,
          (value) => setState(() => _enableGamification = value),
        ),
        _buildSwitchSetting(
          'Offline Mode',
          'Allow users to download content for offline use',
          _enableOfflineMode,
          (value) => setState(() => _enableOfflineMode = value),
        ),
        _buildSwitchSetting(
          'Voice Input',
          'Enable voice recognition for questions',
          _enableVoiceInput,
          (value) => setState(() => _enableVoiceInput = value),
        ),
        _buildSwitchSetting(
          'Translation Service',
          'Enable multilingual translation',
          _enableTranslation,
          (value) => setState(() => _enableTranslation = value),
        ),
        _buildSwitchSetting(
          'Plagiarism Detection',
          'Check student answers for plagiarism',
          _enablePlagiarismDetection,
          (value) => setState(() => _enablePlagiarismDetection = value),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSettingsSection(
      'Security & Privacy',
      Icons.security,
      [
        _buildDropdownSetting(
          'Session Timeout (minutes)',
          _sessionTimeout.toString(),
          _timeouts.map((t) => t.toString()).toList(),
          (value) => setState(() => _sessionTimeout = int.parse(value!)),
        ),
        _buildDropdownSetting(
          'Max File Upload Size (MB)',
          _maxFileSize.toString(),
          _fileSizes.map((s) => s.toString()).toList(),
          (value) => setState(() => _maxFileSize = int.parse(value!)),
        ),
        ListTile(
          leading: const Icon(Icons.key),
          title: const Text('Change Admin Password'),
          subtitle: const Text('Update administrator password'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _showChangePasswordDialog,
        ),
        ListTile(
          leading: const Icon(Icons.shield),
          title: const Text('Two-Factor Authentication'),
          subtitle: const Text('Enable 2FA for admin accounts'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('2FA setup coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSystemMaintenance() {
    return _buildSettingsSection(
      'System Maintenance',
      Icons.build,
      [
        _buildSwitchSetting(
          'Automatic Backup',
          'Automatically backup database daily',
          _autoBackup,
          (value) => setState(() => _autoBackup = value),
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Manual Backup'),
          subtitle: const Text('Create a backup of all system data'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _performBackup,
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services),
          title: const Text('Clear Cache'),
          subtitle: const Text('Clear temporary files and cache'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _clearCache,
        ),
        ListTile(
          leading: const Icon(Icons.analytics),
          title: const Text('System Diagnostics'),
          subtitle: const Text('Run system health check'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _runDiagnostics,
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return _buildSettingsSection(
      'Danger Zone',
      Icons.warning,
      [
        ListTile(
          leading: const Icon(Icons.refresh, color: Colors.orange),
          title: const Text('Reset All Settings'),
          subtitle: const Text('Restore default system settings'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _showResetSettingsDialog,
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Reset Database'),
          subtitle: const Text('WARNING: This will delete all data'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _showResetDatabaseDialog,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.teal.shade600,
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _saveSettings() {
    // TODO: Implement settings save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully!')),
              );
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _performBackup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Creating backup...'),
          ],
        ),
      ),
    );

    // Simulate backup process
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _runDiagnostics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Diagnostics'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Database: Healthy'),
            Text('✅ File System: OK'),
            Text('✅ Memory Usage: Normal'),
            Text('✅ Network: Connected'),
            Text('✅ Services: Running'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showResetDatabaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ DANGER'),
        content: const Text(
          'This will permanently delete ALL data including users, courses, quizzes, and progress. This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Database reset cancelled for safety'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('I UNDERSTAND - RESET'),
          ),
        ],
      ),
    );
  }
}
