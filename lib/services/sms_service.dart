import 'package:flutter/services.dart';
import '../models/sms_log_model.dart';
import '../models/contact_model.dart';
import '../providers/sms_provider.dart';
import '../providers/sender_filter_provider.dart';
import '../providers/group_provider.dart';
import 'debug_log_service.dart';

class SmsService {
  static const MethodChannel _channel = MethodChannel('sms_forwarder/sms');
  static SmsProvider? _smsProvider;
  static SenderFilterProvider? _senderFilterProvider;
  static GroupProvider? _groupProvider;
  static final DebugLogService _debugLog = DebugLogService();

  static void initialize({
    required SmsProvider smsProvider,
    required SenderFilterProvider senderFilterProvider,
    required GroupProvider groupProvider,
  }) {
    _smsProvider = smsProvider;
    _senderFilterProvider = senderFilterProvider;
    _groupProvider = groupProvider;
    
    _channel.setMethodCallHandler(_handleMethodCall);
    _debugLog.logSystemEvent('SMS Service initialized');
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSmsReceived':
        final String sender = call.arguments['sender'] ?? '';
        final String message = call.arguments['message'] ?? '';
        _debugLog.logSmsReceived(sender, message);
        await _processSms(sender, message);
        break;
      default:
        _debugLog.logWarning('system', 'Unknown method: ${call.method}');
    }
  }

  static Future<void> _processSms(String sender, String message) async {
    if (_senderFilterProvider == null || _groupProvider == null || _smsProvider == null) {
      _debugLog.logError('system', 'SMS Service not properly initialized');
      return;
    }

    // Check if sender is in the allowed list
    if (!_senderFilterProvider!.isPhoneNumberAllowed(sender)) {
      _debugLog.logSmsFiltered(sender, 'Not in allowed senders list');
      return;
    }

    try {
      // Get contacts to forward to based on sender
      final contacts = await _groupProvider!.getContactsForSender(sender);
      
      if (contacts.isEmpty) {
        _debugLog.logWarning('filter', 'No contacts found for sender: $sender', {
          'sender': sender,
          'configured_groups': await _groupProvider!.getGroupCount(),
        });
        return;
      }

      _debugLog.logInfo('system', 'Processing SMS forwarding to ${contacts.length} contacts', {
        'sender': sender,
        'contact_count': contacts.length,
      });

      // Forward SMS to all contacts in the mapped groups
      for (final contact in contacts) {
        await _forwardSms(contact, sender, message);
      }
    } catch (e) {
      _debugLog.logError('system', 'Error processing SMS: $e', {
        'sender': sender,
        'error': e.toString(),
      });
    }
  }

  static Future<void> _forwardSms(ContactModel contact, String originalSender, String message) async {
    try {
      final forwardedMessage = 'From: $originalSender\n$message';
      
      _debugLog.logInfo('sms_sent', 'Attempting to send SMS to ${contact.name}', {
        'recipient': contact.phoneNumber,
        'original_sender': originalSender,
      });
      
      final result = await _channel.invokeMethod('sendSms', {
        'phoneNumber': contact.phoneNumber,
        'message': forwardedMessage,
      });

      final success = result == 'SMS sent successfully';
      
      // Log the SMS
      final smsLog = SmsLogModel(
        sender: originalSender,
        message: message,
        forwardedTo: '${contact.name} (${contact.phoneNumber})',
        timestamp: DateTime.now(),
        success: success,
      );

      await _smsProvider!.addSmsLog(smsLog);
      
      _debugLog.logSmsForwarded(originalSender, '${contact.name} (${contact.phoneNumber})', success);
    } catch (e) {
      // Log failed SMS
      final smsLog = SmsLogModel(
        sender: originalSender,
        message: message,
        forwardedTo: '${contact.name} (${contact.phoneNumber})',
        timestamp: DateTime.now(),
        success: false,
      );

      await _smsProvider!.addSmsLog(smsLog);
      _debugLog.logSmsForwarded(originalSender, '${contact.name} (${contact.phoneNumber})', false);
      _debugLog.logError('sms_sent', 'SMS send failed: $e', {
        'recipient': contact.phoneNumber,
        'error': e.toString(),
      });
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      _debugLog.logInfo('permission', 'Requesting SMS permissions');
      final result = await _channel.invokeMethod('requestPermissions');
      final granted = result == true;
      _debugLog.logPermissionStatus(granted);
      return granted;
    } catch (e) {
      _debugLog.logError('permission', 'Error requesting permissions: $e');
      return false;
    }
  }

  static Future<bool> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod('checkPermissions');
      final granted = result == true;
      _debugLog.logPermissionStatus(granted);
      return granted;
    } catch (e) {
      _debugLog.logError('permission', 'Error checking permissions: $e');
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  static Future<String> initializeSmsReceiver() async {
    try {
      final result = await _channel.invokeMethod('initializeSmsReceiver');
      return result ?? 'Unknown status';
    } catch (e) {
      print('Error initializing SMS receiver: $e');
      return 'Error: $e';
    }
  }

  static Future<bool> sendTestMessage(String phoneNumber, String message) async {
    try {
      final result = await _channel.invokeMethod('sendSms', {
        'phoneNumber': phoneNumber,
        'message': message,
      });
      return result == 'SMS sent successfully';
    } catch (e) {
      print('Error sending test message: $e');
      return false;
    }
  }
}