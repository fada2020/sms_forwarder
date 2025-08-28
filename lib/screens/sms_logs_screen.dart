import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sms_provider.dart';
import '../models/sms_log_model.dart';

class SmsLogsScreen extends StatefulWidget {
  @override
  _SmsLogsScreenState createState() => _SmsLogsScreenState();
}

class _SmsLogsScreenState extends State<SmsLogsScreen> {
  String _filterType = 'all'; // all, success, failed
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SmsProvider>(
        builder: (context, smsProvider, child) {
          List<SmsLogModel> filteredLogs = _getFilteredLogs(smsProvider);

          return Column(
            children: [
              _buildFilterHeader(smsProvider),
              Expanded(
                child: filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return _buildLogItem(log);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClearLogsDialog(),
        backgroundColor: Colors.red,
        child: const Icon(Icons.delete_forever),
      ),
    );
  }

  Widget _buildFilterHeader(SmsProvider smsProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search logs',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All (${smsProvider.totalLogs})'),
                const SizedBox(width: 8),
                _buildFilterChip('success', 'Successful (${smsProvider.successfulLogs})'),
                const SizedBox(width: 8),
                _buildFilterChip('failed', 'Failed (${smsProvider.failedLogs})'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats card
          if (smsProvider.totalLogs > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      smsProvider.totalLogs.toString(),
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'Success Rate',
                      '${smsProvider.successRate.toStringAsFixed(1)}%',
                      Colors.green,
                    ),
                    _buildStatItem(
                      'Failed',
                      smsProvider.failedLogs.toString(),
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    return FilterChip(
      label: Text(label),
      selected: _filterType == type,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filterType = type);
        }
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No SMS logs found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SMS forwarding activity will appear here',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(SmsLogModel log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: log.success ? Colors.green : Colors.red,
          child: Icon(
            log.success ? Icons.check : Icons.error,
            color: Colors.white,
          ),
        ),
        title: Text(
          'From: ${log.sender}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To: ${log.forwardedTo}'),
            Text(
              _formatTimestamp(log.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    log.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      log.success ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: log.success ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.success ? 'Successfully forwarded' : 'Failed to forward',
                      style: TextStyle(
                        fontSize: 12,
                        color: log.success ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<SmsLogModel> _getFilteredLogs(SmsProvider smsProvider) {
    List<SmsLogModel> logs;
    
    switch (_filterType) {
      case 'success':
        logs = smsProvider.getSuccessfulLogs();
        break;
      case 'failed':
        logs = smsProvider.getFailedLogs();
        break;
      default:
        logs = smsProvider.smsLogs;
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((log) {
        return log.sender.toLowerCase().contains(query) ||
               log.message.toLowerCase().contains(query) ||
               log.forwardedTo.toLowerCase().contains(query);
      }).toList();
    }

    return logs;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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
}