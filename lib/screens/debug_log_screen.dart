import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/debug_log_model.dart';
import '../services/debug_log_service.dart';

class DebugLogScreen extends StatefulWidget {
  @override
  _DebugLogScreenState createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  final DebugLogService _debugLogService = DebugLogService();
  List<DebugLogModel> _logs = [];
  String? _levelFilter;
  String? _categoryFilter;
  
  final List<String> _levels = ['info', 'warning', 'error', 'success'];
  final List<String> _categories = [
    'sms_received', 'sms_sent', 'filter', 'permission', 'system'
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    
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
        _loadLogs();
      });
    }
  }

  void _loadLogs() {
    _logs = _debugLogService.getLogs(
      levelFilter: _levelFilter,
      categoryFilter: _categoryFilter,
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      case 'info':
      default:
        return Icons.info;
    }
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Debug Logs'),
        content: Text('Are you sure you want to clear all debug logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _debugLogService.clearLogs();
              Navigator.pop(context);
              setState(() {
                _loadLogs();
              });
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No logs to export')),
      );
      return;
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('SMS Forwarder Debug Logs');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total logs: ${_logs.length}');
    buffer.writeln('${'='*50}');
    buffer.writeln();

    for (final log in _logs.reversed) {
      buffer.writeln('[${log.timestamp}] [${log.level.toUpperCase()}] [${log.category.toUpperCase()}]');
      buffer.writeln('${log.message}');
      if (log.data != null) {
        buffer.writeln('Data: ${log.data}');
      }
      buffer.writeln();
    }

    Share.share(
      buffer.toString(),
      subject: 'SMS Forwarder Debug Logs - ${DateTime.now().toLocal()}',
    );
  }

  void _simulateSmsReceived() {
    showDialog(
      context: context,
      builder: (context) {
        String sender = '+82101234567';
        String message = 'Test SMS message';
        
        return AlertDialog(
          title: Text('Simulate SMS Received'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Sender Phone Number'),
                onChanged: (value) => sender = value,
                controller: TextEditingController(text: sender),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: 'Message'),
                maxLines: 3,
                onChanged: (value) => message = value,
                controller: TextEditingController(text: message),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _debugLogService.logSmsReceived(sender, message);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('SMS reception simulated')),
                );
              },
              child: Text('Simulate'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Logs'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearLogs();
                  break;
                case 'export':
                  _exportLogs();
                  break;
                case 'simulate':
                  _simulateSmsReceived();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'simulate',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text('Simulate SMS'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Export Logs'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Logs'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: InputDecoration(
                      labelText: 'Level Filter',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _levelFilter,
                    items: [
                      DropdownMenuItem(value: null, child: Text('All Levels')),
                      ..._levels.map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(level.toUpperCase()),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _levelFilter = value;
                        _loadLogs();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: InputDecoration(
                      labelText: 'Category Filter',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _categoryFilter,
                    items: [
                      DropdownMenuItem(value: null, child: Text('All Categories')),
                      ..._categories.map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.replaceAll('_', ' ').toUpperCase()),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _categoryFilter = value;
                        _loadLogs();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          
          // Logs count
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Showing ${_logs.length} logs',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Spacer(),
                if (_logs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _loadLogs()),
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('Refresh'),
                  ),
              ],
            ),
          ),
          
          // Logs list
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No debug logs found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Logs will appear here as the app processes SMS messages',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _logs.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return ListTile(
                        leading: Icon(
                          _getLevelIcon(log.level),
                          color: _getLevelColor(log.level),
                        ),
                        title: Text(log.message),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  log.timestamp.toString().substring(11, 19),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getLevelColor(log.level).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getLevelColor(log.level).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    log.category.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getLevelColor(log.level),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (log.data != null) ...[
                              SizedBox(height: 4),
                              Text(
                                'Data: ${log.data.toString()}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                        isThreeLine: log.data != null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}