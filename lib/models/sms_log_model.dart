class SmsLogModel {
  final int? id;
  final String sender;
  final String message;
  final String forwardedTo;
  final DateTime timestamp;
  final bool success;

  SmsLogModel({
    this.id,
    required this.sender,
    required this.message,
    required this.forwardedTo,
    required this.timestamp,
    this.success = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'forwardedTo': forwardedTo,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'success': success ? 1 : 0,
    };
  }

  factory SmsLogModel.fromMap(Map<String, dynamic> map) {
    return SmsLogModel(
      id: map['id'],
      sender: map['sender'] ?? '',
      message: map['message'] ?? '',
      forwardedTo: map['forwardedTo'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      success: map['success'] == 1,
    );
  }
}