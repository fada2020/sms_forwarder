import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contact_provider.dart';
import '../providers/group_provider.dart';
import '../providers/sender_filter_provider.dart';
import '../services/sms_service.dart';
import '../services/debug_log_service.dart';
import '../models/contact_model.dart';

class ConfigurationTestScreen extends StatefulWidget {
  @override
  _ConfigurationTestScreenState createState() => _ConfigurationTestScreenState();
}

class _ConfigurationTestScreenState extends State<ConfigurationTestScreen> {
  final DebugLogService _debugLogService = DebugLogService();
  final TextEditingController _testSenderController = TextEditingController(text: '+82101234567');
  final TextEditingController _testMessageController = TextEditingController(text: 'Test SMS message');
  final TextEditingController _testRecipientController = TextEditingController(text: '+82109876543');
  
  List<String> _validationResults = [];
  bool _isValidating = false;

  @override
  void dispose() {
    _testSenderController.dispose();
    _testMessageController.dispose();
    _testRecipientController.dispose();
    super.dispose();
  }

  Future<void> _runFullValidation() async {
    setState(() {
      _isValidating = true;
      _validationResults.clear();
    });

    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final senderFilterProvider = Provider.of<SenderFilterProvider>(context, listen: false);

    // 1. Check SMS permissions
    _validationResults.add('🔍 Checking SMS permissions...');
    setState(() {});
    
    try {
      final hasPermissions = await SmsService.checkPermissions();
      if (hasPermissions) {
        _validationResults.add('✅ SMS permissions: GRANTED');
      } else {
        _validationResults.add('❌ SMS permissions: MISSING - App cannot receive or send SMS');
      }
    } catch (e) {
      _validationResults.add('❌ SMS permissions check failed: $e');
    }
    setState(() {});

    // 2. Check contacts
    _validationResults.add('\n🔍 Checking contacts configuration...');
    setState(() {});
    
    await contactProvider.loadContacts();
    final activeContacts = contactProvider.activeContacts;
    if (activeContacts.isEmpty) {
      _validationResults.add('⚠️ No active contacts found - SMS cannot be forwarded');
    } else {
      _validationResults.add('✅ Found ${activeContacts.length} active contacts');
      for (final contact in activeContacts.take(3)) {
        _validationResults.add('   • ${contact.name}: ${contact.phoneNumber}');
      }
      if (activeContacts.length > 3) {
        _validationResults.add('   • ... and ${activeContacts.length - 3} more');
      }
    }
    setState(() {});

    // 3. Check groups
    _validationResults.add('\n🔍 Checking groups configuration...');
    setState(() {});
    
    await groupProvider.loadGroups();
    final activeGroups = groupProvider.activeGroups;
    if (activeGroups.isEmpty) {
      _validationResults.add('⚠️ No active groups found - Consider organizing contacts into groups');
    } else {
      _validationResults.add('✅ Found ${activeGroups.length} active groups');
      for (final group in activeGroups.take(3)) {
        final members = await groupProvider.getGroupMembers(group.id!);
        _validationResults.add('   • ${group.name}: ${members.length} members');
      }
      if (activeGroups.length > 3) {
        _validationResults.add('   • ... and ${activeGroups.length - 3} more');
      }
    }
    setState(() {});

    // 4. Check sender filters
    _validationResults.add('\n🔍 Checking sender filters configuration...');
    setState(() {});
    
    await senderFilterProvider.loadSenderFilters();
    final senderFilters = senderFilterProvider.senderFilters;
    if (senderFilters.isEmpty) {
      _validationResults.add('⚠️ No sender filters configured - All SMS will be ignored');
    } else {
      _validationResults.add('✅ Found ${senderFilters.length} sender filters');
      for (final filter in senderFilters.take(3)) {
        _validationResults.add('   • ${filter.phoneNumber} (${filter.isActive ? "Active" : "Inactive"})');
      }
      if (senderFilters.length > 3) {
        _validationResults.add('   • ... and ${senderFilters.length - 3} more');
      }
    }
    setState(() {});

    // 5. Check sender-to-group mappings
    _validationResults.add('\n🔍 Checking sender-to-group mappings...');
    setState(() {});
    
    bool hasMappings = false;
    for (final filter in senderFilters) {
      if (filter.isActive) {
        try {
          final contacts = await groupProvider.getContactsForSender(filter.phoneNumber);
          if (contacts.isNotEmpty) {
            hasMappings = true;
            _validationResults.add('✅ ${filter.phoneNumber} → ${contacts.length} contacts');
          }
        } catch (e) {
          _validationResults.add('❌ Error checking mapping for ${filter.phoneNumber}: $e');
        }
      }
    }
    
    if (!hasMappings && senderFilters.isNotEmpty) {
      _validationResults.add('⚠️ No sender-to-group mappings found - SMS will be received but not forwarded');
    }
    
    setState(() {});

    // 6. Overall assessment
    _validationResults.add('\n📋 CONFIGURATION ASSESSMENT:');
    if (activeContacts.isEmpty || senderFilters.isEmpty || !hasMappings) {
      _validationResults.add('❌ Configuration incomplete - SMS forwarding may not work');
      _validationResults.add('\n💡 To fix:');
      if (activeContacts.isEmpty) {
        _validationResults.add('   1. Add contacts in the Contacts tab');
      }
      if (activeGroups.isEmpty) {
        _validationResults.add('   2. Create groups and add contacts to them');
      }
      if (senderFilters.isEmpty) {
        _validationResults.add('   3. Add allowed senders in the Senders tab');
      }
      if (!hasMappings) {
        _validationResults.add('   4. Map senders to groups for forwarding');
      }
    } else {
      _validationResults.add('✅ Configuration looks good - SMS forwarding should work!');
    }

    setState(() {
      _isValidating = false;
    });
  }

  Future<void> _testSmsFlow() async {
    final sender = _testSenderController.text.trim();
    final message = _testMessageController.text.trim();

    if (sender.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both sender and message')),
      );
      return;
    }

    _debugLogService.logInfo('test', 'Starting SMS flow simulation', {
      'sender': sender,
      'message': message.length > 50 ? '${message.substring(0, 50)}...' : message,
    });

    final senderFilterProvider = Provider.of<SenderFilterProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    // Simulate the SMS processing flow
    await senderFilterProvider.loadSenderFilters();
    
    if (!senderFilterProvider.isPhoneNumberAllowed(sender)) {
      _debugLogService.logWarning('test', 'SMS would be filtered - sender not in allowed list', {
        'sender': sender,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SMS would be BLOCKED - $sender is not in allowed senders list'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final contacts = await groupProvider.getContactsForSender(sender);
      
      if (contacts.isEmpty) {
        _debugLogService.logWarning('test', 'No forwarding contacts found for sender', {
          'sender': sender,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMS would be RECEIVED but NOT FORWARDED - no contacts mapped to $sender'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      _debugLogService.logSuccess('test', 'SMS would be forwarded to ${contacts.length} contacts', {
        'sender': sender,
        'recipients': contacts.map((c) => c.name).toList(),
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('SMS Flow Simulation Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ SMS from $sender would be forwarded to:'),
              SizedBox(height: 8),
              ...contacts.map((contact) => Padding(
                padding: EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• ${contact.name} (${contact.phoneNumber})'),
              )),
              SizedBox(height: 16),
              Text('Message preview:'),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'From: $sender\n$message',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _debugLogService.logError('test', 'Error in SMS flow simulation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SMS flow test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testSmsSend() async {
    final recipient = _testRecipientController.text.trim();
    final message = 'Test SMS from SMS Forwarder app at ${DateTime.now().toString().substring(11, 16)}';

    if (recipient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter recipient phone number')),
      );
      return;
    }

    try {
      _debugLogService.logInfo('test', 'Testing SMS send capability', {
        'recipient': recipient,
      });

      final success = await SmsService.sendTestMessage(recipient, message);
      
      if (success) {
        _debugLogService.logSuccess('test', 'Test SMS sent successfully', {
          'recipient': recipient,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Test SMS sent to $recipient'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _debugLogService.logError('test', 'Test SMS send failed', {
          'recipient': recipient,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send test SMS to $recipient'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _debugLogService.logError('test', 'SMS send test error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SMS send test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuration Test'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Validation section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Configuration Validation',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isValidating ? null : _runFullValidation,
                        icon: _isValidating 
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.play_arrow),
                        label: Text(_isValidating ? 'Validating...' : 'Run Full Validation'),
                      ),
                    ),
                    if (_validationResults.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _validationResults.join('\n'),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // SMS flow test section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'SMS Flow Simulation',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _testSenderController,
                      decoration: InputDecoration(
                        labelText: 'Test Sender Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _testMessageController,
                      decoration: InputDecoration(
                        labelText: 'Test Message',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testSmsFlow,
                        icon: Icon(Icons.play_arrow),
                        label: Text('Simulate SMS Flow'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // SMS send test section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.send, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'SMS Send Test',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Test if the app can actually send SMS messages',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _testRecipientController,
                      decoration: InputDecoration(
                        labelText: 'Test Recipient Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        helperText: 'Enter your own number to safely test',
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testSmsSend,
                        icon: Icon(Icons.send),
                        label: Text('Send Test SMS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}