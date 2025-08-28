import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sms_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/sender_filter_provider.dart';
import '../providers/group_provider.dart';
import '../services/sms_service.dart';
import '../services/debug_log_service.dart';
import '../models/debug_log_model.dart';
import '../widgets/banner_ad_widget.dart';
import 'contacts_screen.dart';
import 'groups_screen.dart';
import 'sender_filters_screen.dart';
import 'sms_logs_screen.dart';
import 'settings_screen.dart';
import 'debug_log_screen.dart';
import 'configuration_test_screen.dart';
import 'setup_guide_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _hasPermissions = false;
  String _serviceStatus = 'Checking...';
  final DebugLogService _debugLogService = DebugLogService();
  List<DebugLogModel> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadRecentLogs();
    
    // Listen for new logs
    _debugLogService.addListener(_onNewLog);
  }

  @override
  void dispose() {
    _debugLogService.removeListener(_onNewLog);
    super.dispose();
  }

  void _onNewLog(DebugLogModel log) {
    if (mounted) {
      setState(() {
        _loadRecentLogs();
      });
    }
  }

  void _loadRecentLogs() {
    _recentLogs = _debugLogService.getLogs().take(3).toList();
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await SmsService.checkPermissions();
    setState(() {
      _hasPermissions = hasPermissions;
      _serviceStatus = hasPermissions ? 'Active' : 'Inactive - Permissions needed';
    });
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

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return ContactsScreen();
      case 2:
        return GroupsScreen();
      case 3:
        return SenderFiltersScreen();
      case 4:
        return SmsLogsScreen();
      case 5:
        return DebugLogScreen();
      case 6:
        return SettingsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Consumer4<SmsProvider, ContactProvider, SenderFilterProvider, GroupProvider>(
      builder: (context, smsProvider, contactProvider, senderFilterProvider, groupProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceStatusCard(),
              const SizedBox(height: 16),
              
              // Banner ad after service status
              Center(child: const BannerAdWidget()),
              const SizedBox(height: 16),
              
              _buildStatsCards(smsProvider, contactProvider, senderFilterProvider, groupProvider),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              
              // Large banner ad between sections
              Center(child: const LargeBannerAdWidget()),
              const SizedBox(height: 16),
              
              _buildRecentDebugLogs(),
              const SizedBox(height: 16),
              _buildRecentSmsLogs(smsProvider),
              
              // Final banner ad at the bottom
              const SizedBox(height: 16),
              Center(child: const BannerAdWidget()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _hasPermissions ? Icons.check_circle : Icons.error,
                  color: _hasPermissions ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'SMS Forwarding Service',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Status: $_serviceStatus',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!_hasPermissions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _requestPermissions,
                      child: const Text('Grant Permissions'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SetupGuideScreen()),
                    ),
                    icon: const Icon(Icons.help),
                    label: const Text('Guide'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SetupGuideScreen()),
                ),
                icon: const Icon(Icons.help),
                label: const Text('Setup Guide'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(SmsProvider smsProvider, ContactProvider contactProvider, 
                         SenderFilterProvider senderFilterProvider, GroupProvider groupProvider) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Contacts',
          contactProvider.activeContacts.length.toString(),
          Icons.contacts,
          Colors.blue,
        ),
        _buildStatCard(
          'Groups',
          groupProvider.activeGroups.length.toString(),
          Icons.group,
          Colors.green,
        ),
        _buildStatCard(
          'SMS Sent',
          smsProvider.successfulLogs.toString(),
          Icons.send,
          Colors.orange,
        ),
        _buildStatCard(
          'Allowed Senders',
          senderFilterProvider.activeSenderFilters.length.toString(),
          Icons.filter_list,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Contact'),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Create Group'),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 3),
                  icon: const Icon(Icons.add_box),
                  label: const Text('Add Sender'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConfigurationTestScreen()),
                  ),
                  icon: const Icon(Icons.science),
                  label: const Text('Test Config'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDebugLogs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 5),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentLogs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No recent activity',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._recentLogs.map((log) => _buildLogItem(log)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(DebugLogModel log) {
    Color levelColor;
    IconData levelIcon;
    
    switch (log.level) {
      case 'error':
        levelColor = Colors.red;
        levelIcon = Icons.error;
        break;
      case 'warning':
        levelColor = Colors.orange;
        levelIcon = Icons.warning;
        break;
      case 'success':
        levelColor = Colors.green;
        levelIcon = Icons.check_circle;
        break;
      case 'info':
      default:
        levelColor = Colors.blue;
        levelIcon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: levelColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(levelIcon, size: 16, color: levelColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${log.timestamp.toString().substring(11, 19)} • ${log.category.replaceAll('_', ' ').toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSmsLogs(SmsProvider smsProvider) {
    final recentLogs = smsProvider.smsLogs.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent SMS Logs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 4),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentLogs.isEmpty)
              const Text('No SMS logs yet')
            else
              ...recentLogs.map((log) => ListTile(
                leading: Icon(
                  log.success ? Icons.check_circle : Icons.error,
                  color: log.success ? Colors.green : Colors.red,
                ),
                title: Text('From: ${log.sender}'),
                subtitle: Text('To: ${log.forwardedTo}'),
                trailing: Text(
                  '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                ),
              )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Forwarder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _getSelectedScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.contacts), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Groups'),
          NavigationDestination(icon: Icon(Icons.filter_list), label: 'Senders'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Logs'),
          NavigationDestination(icon: Icon(Icons.bug_report), label: 'Debug'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}