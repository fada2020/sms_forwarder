import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contact_provider.dart';
import '../providers/group_provider.dart';
import '../providers/sender_filter_provider.dart';
import '../services/sms_service.dart';
import '../services/debug_log_service.dart';

class SetupGuideScreen extends StatefulWidget {
  @override
  _SetupGuideScreenState createState() => _SetupGuideScreenState();
}

class _SetupGuideScreenState extends State<SetupGuideScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final DebugLogService _debugLogService = DebugLogService();

  final List<SetupStep> _steps = [
    SetupStep(
      title: 'Welcome to SMS Forwarder',
      description: 'This guide will help you set up SMS forwarding in just a few steps.',
      icon: Icons.waving_hand,
      color: Colors.blue,
    ),
    SetupStep(
      title: 'Grant SMS Permissions',
      description: 'The app needs permissions to receive and send SMS messages.',
      icon: Icons.security,
      color: Colors.orange,
    ),
    SetupStep(
      title: 'Add Contacts',
      description: 'Add contacts who will receive forwarded SMS messages.',
      icon: Icons.contacts,
      color: Colors.green,
    ),
    SetupStep(
      title: 'Create Groups (Optional)',
      description: 'Organize contacts into groups for easier management.',
      icon: Icons.group,
      color: Colors.purple,
    ),
    SetupStep(
      title: 'Configure Senders',
      description: 'Specify which phone numbers are allowed to send SMS for forwarding.',
      icon: Icons.filter_list,
      color: Colors.red,
    ),
    SetupStep(
      title: 'Setup Complete!',
      description: 'Your SMS forwarder is now ready to use. Test it to make sure everything works.',
      icon: Icons.celebration,
      color: Colors.teal,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestPermissions() async {
    _debugLogService.logInfo('setup', 'User requesting permissions from setup guide');
    try {
      final granted = await SmsService.requestPermissions();
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Permissions granted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _nextStep();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Permissions denied. Please grant them in settings.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => SmsService.openAppSettings(),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting permissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStepContent(int index) {
    final step = _steps[index];

    switch (index) {
      case 0:
        return _buildWelcomeStep(step);
      case 1:
        return _buildPermissionsStep(step);
      case 2:
        return _buildContactsStep(step);
      case 3:
        return _buildGroupsStep(step);
      case 4:
        return _buildSendersStep(step);
      case 5:
        return _buildCompleteStep(step);
      default:
        return _buildDefaultStep(step);
    }
  }

  Widget _buildWelcomeStep(SetupStep step) {
    return Column(
      children: [
        Icon(step.icon, size: 80, color: step.color),
        SizedBox(height: 24),
        Text(
          step.title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          step.description,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What this app does:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 12),
                _buildFeatureItem(Icons.sms, 'Receives SMS from specific senders'),
                _buildFeatureItem(Icons.forward, 'Forwards them to your contacts'),
                _buildFeatureItem(Icons.group, 'Supports contact groups'),
                _buildFeatureItem(Icons.filter_list, 'Filters by sender phone number'),
                _buildFeatureItem(Icons.history, 'Keeps a log of all forwarded messages'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildPermissionsStep(SetupStep step) {
    return Column(
      children: [
        Icon(step.icon, size: 80, color: step.color),
        SizedBox(height: 24),
        Text(
          step.title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          step.description,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        Card(
          color: Colors.orange[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Required Permissions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildPermissionItem('RECEIVE_SMS', 'To receive incoming SMS messages'),
                _buildPermissionItem('SEND_SMS', 'To forward SMS messages to contacts'),
                _buildPermissionItem('READ_SMS', 'To read SMS content for forwarding'),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _requestPermissions,
            icon: Icon(Icons.security),
            label: Text('Grant Permissions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: step.color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionItem(String permission, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsStep(SetupStep step) {
    return Consumer<ContactProvider>(
      builder: (context, contactProvider, child) {
        return Column(
          children: [
            Icon(step.icon, size: 80, color: step.color),
            SizedBox(height: 24),
            Text(
              step.title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              step.description,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.contacts, color: step.color),
                        SizedBox(width: 8),
                        Text(
                          'Current Contacts: ${contactProvider.activeContacts.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (contactProvider.activeContacts.isNotEmpty) ...[
                      SizedBox(height: 12),
                      ...contactProvider.activeContacts.take(3).map(
                        (contact) => ListTile(
                          leading: CircleAvatar(child: Text(contact.name[0])),
                          title: Text(contact.name),
                          subtitle: Text(contact.phoneNumber),
                          dense: true,
                        ),
                      ),
                      if (contactProvider.activeContacts.length > 3)
                        Text('... and ${contactProvider.activeContacts.length - 3} more'),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to contacts screen - you'll need to implement this
                },
                icon: Icon(Icons.person_add),
                label: Text('Add Contacts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: step.color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupsStep(SetupStep step) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        return Column(
          children: [
            Icon(step.icon, size: 80, color: step.color),
            SizedBox(height: 24),
            Text(
              step.title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              step.description,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group, color: step.color),
                        SizedBox(width: 8),
                        Text(
                          'Current Groups: ${groupProvider.activeGroups.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (groupProvider.activeGroups.isNotEmpty) ...[
                      SizedBox(height: 12),
                      ...groupProvider.activeGroups.take(3).map(
                        (group) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: step.color,
                            child: Icon(Icons.group, color: Colors.white),
                          ),
                          title: Text(group.name),
                          subtitle: Text(group.description ?? 'No description'),
                          dense: true,
                        ),
                      ),
                      if (groupProvider.activeGroups.length > 3)
                        Text('... and ${groupProvider.activeGroups.length - 3} more'),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Groups are optional but help organize your contacts. You can skip this step and add groups later.',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _nextStep,
                    child: Text('Skip for Now'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to groups screen
                    },
                    icon: Icon(Icons.group_add),
                    label: Text('Create Group'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: step.color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSendersStep(SetupStep step) {
    return Consumer<SenderFilterProvider>(
      builder: (context, senderFilterProvider, child) {
        return Column(
          children: [
            Icon(step.icon, size: 80, color: step.color),
            SizedBox(height: 24),
            Text(
              step.title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              step.description,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list, color: step.color),
                        SizedBox(width: 8),
                        Text(
                          'Allowed Senders: ${senderFilterProvider.senderFilters.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (senderFilterProvider.senderFilters.isNotEmpty) ...[
                      SizedBox(height: 12),
                      ...senderFilterProvider.senderFilters.take(3).map(
                        (filter) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: filter.isActive ? Colors.green : Colors.grey,
                            child: Icon(Icons.phone, color: Colors.white),
                          ),
                          title: Text(filter.phoneNumber),
                          subtitle: Text(filter.isActive ? 'Active' : 'Inactive'),
                          dense: true,
                        ),
                      ),
                      if (senderFilterProvider.senderFilters.length > 3)
                        Text('... and ${senderFilterProvider.senderFilters.length - 3} more'),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only SMS from these numbers will be forwarded. Add at least one sender to enable forwarding.',
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to sender filters screen
                },
                icon: Icon(Icons.add),
                label: Text('Add Allowed Sender'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: step.color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompleteStep(SetupStep step) {
    return Column(
      children: [
        Icon(step.icon, size: 80, color: step.color),
        SizedBox(height: 24),
        Text(
          step.title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          step.description,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        Card(
          color: Colors.green[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'What to do next:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildNextStepItem('Test your configuration using the "Test Config" button'),
                _buildNextStepItem('Send a test SMS to verify forwarding works'),
                _buildNextStepItem('Check the Debug logs to monitor SMS activity'),
                _buildNextStepItem('Adjust settings as needed in the Settings tab'),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.home),
            label: Text('Go to Home Screen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: step.color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.arrow_forward, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildDefaultStep(SetupStep step) {
    return Column(
      children: [
        Icon(step.icon, size: 80, color: step.color),
        SizedBox(height: 24),
        Text(
          step.title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          step.description,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Guide'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_steps[_currentStep].color),
          ),
          
          // Step indicator
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Step ${_currentStep + 1} of ${_steps.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: _buildStepContent(index),
                );
              },
            ),
          ),

          // Navigation buttons
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0 && _currentStep < _steps.length - 1)
                  SizedBox(width: 16),
                if (_currentStep < _steps.length - 1)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      child: Text('Next'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SetupStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  SetupStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}