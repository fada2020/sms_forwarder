class DebugLogModel {
  final String id;
  final DateTime timestamp;
  final String level; // 'info', 'warning', 'error', 'success'
  final String category; // 'sms_received', 'sms_sent', 'permission', 'filter', 'system'
  final String message;
  final Map<String, dynamic>? data;

  DebugLogModel({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'level': level,
      'category': category,
      'message': message,
      'data': data,
    };
  }

  factory DebugLogModel.fromJson(Map<String, dynamic> json) {
    return DebugLogModel(
      id: json['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      level: json['level'],
      category: json['category'],
      message: json['message'],
      data: json['data'],
    );
  }

  // Helper methods for different log levels
  static DebugLogModel info(String category, String message, [Map<String, dynamic>? data]) {
    return DebugLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: 'info',
      category: category,
      message: message,
      data: data,
    );
  }

  static DebugLogModel warning(String category, String message, [Map<String, dynamic>? data]) {
    return DebugLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: 'warning',
      category: category,
      message: message,
      data: data,
    );
  }

  static DebugLogModel error(String category, String message, [Map<String, dynamic>? data]) {
    return DebugLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: 'error',
      category: category,
      message: message,
      data: data,
    );
  }

  static DebugLogModel success(String category, String message, [Map<String, dynamic>? data]) {
    return DebugLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: 'success',
      category: category,
      message: message,
      data: data,
    );
  }
}