import 'package:flutter/foundation.dart';
import '../models/sms_log_model.dart';
import '../services/database_service.dart';

class SmsProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<SmsLogModel> _smsLogs = [];
  bool _isLoading = false;

  List<SmsLogModel> get smsLogs => _smsLogs;
  bool get isLoading => _isLoading;

  Future<void> loadSmsLogs({int? limit}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (limit != null) {
        _smsLogs = await _databaseService.getRecentSmsLogs(limit);
      } else {
        _smsLogs = await _databaseService.getAllSmsLogs();
      }
    } catch (e) {
      debugPrint('Error loading SMS logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSmsLog(SmsLogModel smsLog) async {
    try {
      final id = await _databaseService.insertSmsLog(smsLog);
      if (id > 0) {
        final newSmsLog = SmsLogModel(
          id: id,
          sender: smsLog.sender,
          message: smsLog.message,
          forwardedTo: smsLog.forwardedTo,
          timestamp: smsLog.timestamp,
          success: smsLog.success,
        );
        _smsLogs.insert(0, newSmsLog); // Add to the beginning for recent-first order
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding SMS log: $e');
    }
    return false;
  }

  Future<bool> clearLogs() async {
    try {
      final result = await _databaseService.clearSmsLogs();
      if (result >= 0) {
        _smsLogs.clear();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error clearing SMS logs: $e');
    }
    return false;
  }

  List<SmsLogModel> getLogsBySender(String sender) {
    return _smsLogs.where((log) => log.sender == sender).toList();
  }

  List<SmsLogModel> getSuccessfulLogs() {
    return _smsLogs.where((log) => log.success).toList();
  }

  List<SmsLogModel> getFailedLogs() {
    return _smsLogs.where((log) => !log.success).toList();
  }

  int get totalLogs => _smsLogs.length;
  int get successfulLogs => getSuccessfulLogs().length;
  int get failedLogs => getFailedLogs().length;

  double get successRate {
    if (_smsLogs.isEmpty) return 0.0;
    return (successfulLogs / totalLogs) * 100;
  }
}