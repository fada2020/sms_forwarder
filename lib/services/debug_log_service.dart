import 'dart:collection';
import '../models/debug_log_model.dart';

class DebugLogService {
  static final DebugLogService _instance = DebugLogService._internal();
  factory DebugLogService() => _instance;
  DebugLogService._internal();

  final Queue<DebugLogModel> _logs = Queue<DebugLogModel>();
  static const int maxLogs = 1000;

  // Stream controller for real-time log updates
  final List<Function(DebugLogModel)> _listeners = [];

  void addListener(Function(DebugLogModel) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(DebugLogModel) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(DebugLogModel log) {
    for (var listener in _listeners) {
      try {
        listener(log);
      } catch (e) {
        print('Error notifying log listener: $e');
      }
    }
  }

  void addLog(DebugLogModel log) {
    // Add to queue
    _logs.add(log);
    
    // Keep only the most recent logs
    while (_logs.length > maxLogs) {
      _logs.removeFirst();
    }

    // Print to console for Flutter run debugging
    _printToConsole(log);
    
    // Notify listeners
    _notifyListeners(log);
  }

  void _printToConsole(DebugLogModel log) {
    final timestamp = log.timestamp.toString().substring(11, 19);
    final level = log.level.toUpperCase().padRight(7);
    final category = log.category.toUpperCase().padRight(12);
    print('[$timestamp] [$level] [$category] ${log.message}');
    if (log.data != null) {
      print('                                    Data: ${log.data}');
    }
  }

  List<DebugLogModel> getLogs({String? levelFilter, String? categoryFilter}) {
    var filteredLogs = _logs.toList();
    
    if (levelFilter != null && levelFilter.isNotEmpty) {
      filteredLogs = filteredLogs.where((log) => log.level == levelFilter).toList();
    }
    
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      filteredLogs = filteredLogs.where((log) => log.category == categoryFilter).toList();
    }
    
    return filteredLogs.reversed.toList(); // Most recent first
  }

  void clearLogs() {
    _logs.clear();
    addLog(DebugLogModel.info('system', 'Debug logs cleared'));
  }

  // Convenience methods
  void logInfo(String category, String message, [Map<String, dynamic>? data]) {
    addLog(DebugLogModel.info(category, message, data));
  }

  void logWarning(String category, String message, [Map<String, dynamic>? data]) {
    addLog(DebugLogModel.warning(category, message, data));
  }

  void logError(String category, String message, [Map<String, dynamic>? data]) {
    addLog(DebugLogModel.error(category, message, data));
  }

  void logSuccess(String category, String message, [Map<String, dynamic>? data]) {
    addLog(DebugLogModel.success(category, message, data));
  }

  // SMS specific logging methods
  void logSmsReceived(String sender, String message) {
    logInfo('sms_received', 'SMS received from $sender', {
      'sender': sender,
      'message': message.length > 50 ? '${message.substring(0, 50)}...' : message,
    });
  }

  void logSmsFiltered(String sender, String reason) {
    logWarning('filter', 'SMS from $sender filtered: $reason', {
      'sender': sender,
      'reason': reason,
    });
  }

  void logSmsForwarded(String sender, String recipient, bool success) {
    if (success) {
      logSuccess('sms_sent', 'SMS forwarded to $recipient', {
        'original_sender': sender,
        'recipient': recipient,
      });
    } else {
      logError('sms_sent', 'Failed to forward SMS to $recipient', {
        'original_sender': sender,
        'recipient': recipient,
      });
    }
  }

  void logPermissionStatus(bool granted) {
    if (granted) {
      logSuccess('permission', 'All SMS permissions granted');
    } else {
      logError('permission', 'SMS permissions missing or denied');
    }
  }

  void logSystemEvent(String event, [Map<String, dynamic>? data]) {
    logInfo('system', event, data);
  }
}