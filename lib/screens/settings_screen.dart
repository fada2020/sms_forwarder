import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sms_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/sender_filter_provider.dart';
import '../providers/group_provider.dart';
import '../services/sms_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _testPhoneController = TextEditingController();
  final _testMessageController = TextEditingController();
  bool _hasPermissions = false;
  String _serviceStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _testMessageController.text = 'Test message from SMS Forwarder';
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await SmsService.checkPermissions();
    final status = await SmsService.initializeSmsReceiver();
    
    setState(() {
      _hasPermissions = hasPermissions;
      _serviceStatus = hasPermissions ? 'Active' : 'Inactive - Permissions needed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceStatusSection(),
            const SizedBox(height: 24),
            _buildPermissionsSection(),
            const SizedBox(height: 24),
            _buildTestSection(),
            const SizedBox(height: 24),
            _buildStatisticsSection(),
            const SizedBox(height: 24),
            _buildDataManagementSection(),
            const SizedBox(height: 24),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _hasPermissions ? Icons.check_circle : Icons.error,
                  color: _hasPermissions ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMS Forwarding Service',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _serviceStatus,
                        style: TextStyle(
                          color: _hasPermissions ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!_hasPermissions) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _requestPermissions(),
                  child: const Text('Grant Permissions'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              'SMS Permissions',
              'Required to receive and send SMS messages',
              Icons.sms,
              _hasPermissions,
            ),
            _buildPermissionItem(
              'Contacts Permission',
              'Required to access your phone contacts',
              Icons.contacts,
              _hasPermissions,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => SmsService.openAppSettings(),
                child: const Text('Open App Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String title, String description, IconData icon, bool granted) {
    return ListTile(
      leading: Icon(
        icon,
        color: granted ? Colors.green : Colors.red,
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: Icon(
        granted ? Icons.check_circle : Icons.cancel,
        color: granted ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test SMS Sending',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _testPhoneController,
              decoration: const InputDecoration(
                labelText: 'Test Phone Number',
                border: OutlineInputBorder(),
                hintText: '+1234567890',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _testMessageController,
              decoration: const InputDecoration(
                labelText: 'Test Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasPermissions ? () => _sendTestMessage() : null,
                child: const Text('Send Test Message'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: This will send a real SMS message',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer4<ContactProvider, SenderFilterProvider, GroupProvider, SmsProvider>(
              builder: (context, contactProvider, senderFilterProvider, groupProvider, smsProvider, child) {
                return Column(
                  children: [
                    _buildStatRow('Active Contacts', contactProvider.activeContacts.length.toString()),
                    _buildStatRow('Active Groups', groupProvider.activeGroups.length.toString()),
                    _buildStatRow('Allowed Senders', senderFilterProvider.activeSenderFilters.length.toString()),
                    _buildStatRow('Total SMS Sent', smsProvider.successfulLogs.toString()),
                    _buildStatRow('Failed SMS', smsProvider.failedLogs.toString()),
                    _buildStatRow('Success Rate', '${smsProvider.successRate.toStringAsFixed(1)}%'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Clear All SMS Logs'),
              subtitle: const Text('Delete all SMS forwarding logs'),
              onTap: () => _showClearLogsDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Refresh Data'),
              subtitle: const Text('Reload all data from database'),
              onTap: () => _refreshAllData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('SMS Forwarder'),
              subtitle: Text('Version 1.0.0'),
            ),
            const ListTile(
              leading: Icon(Icons.description),
              title: Text('Description'),
              subtitle: Text('Forward incoming SMS messages to multiple contacts based on sender groups'),
            ),
            const ListTile(
              leading: Icon(Icons.security),
              title: Text('Privacy'),
              subtitle: Text('All data is stored locally on your device'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final granted = await SmsService.requestPermissions();
    if (granted) {
      await _checkPermissions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions granted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions denied. Please grant permissions in settings.')),
      );
    }
  }

  Future<void> _sendTestMessage() async {
    if (_testPhoneController.text.trim().isEmpty || _testMessageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final success = await SmsService.sendTestMessage(
      _testPhoneController.text.trim(),
      _testMessageController.text.trim(),
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test message sent successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send test message')),
      );
    }
  }

  void _showClearLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text('Are you sure you want to delete all SMS logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _clearLogs(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearLogs() async {
    final success = await Provider.of<SmsProvider>(context, listen: false).clearLogs();
    
    Navigator.pop(context);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All logs cleared successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear logs')),
      );
    }
  }

  Future<void> _refreshAllData() async {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final smsProvider = Provider.of<SmsProvider>(context, listen: false);
    final senderFilterProvider = Provider.of<SenderFilterProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    await Future.wait([
      contactProvider.loadContacts(),
      smsProvider.loadSmsLogs(),
      senderFilterProvider.loadSenderFilters(),
      groupProvider.loadGroups(),
    ]);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data refreshed successfully')),
    );
  }

  @override
  void dispose() {
    _testPhoneController.dispose();
    _testMessageController.dispose();
    super.dispose();
  }
}