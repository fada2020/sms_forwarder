import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sender_filter_provider.dart';
import '../models/sender_filter_model.dart';

class SenderFiltersScreen extends StatefulWidget {
  @override
  _SenderFiltersScreenState createState() => _SenderFiltersScreenState();
}

class _SenderFiltersScreenState extends State<SenderFiltersScreen> {
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SenderFilterProvider>(
        builder: (context, senderFilterProvider, child) {
          final filteredSenders = _searchQuery.isEmpty
              ? senderFilterProvider.senderFilters
              : senderFilterProvider.searchSenderFilters(_searchQuery);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search allowed senders',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: filteredSenders.isEmpty
                    ? const Center(child: Text('No allowed senders found'))
                    : ListView.builder(
                        itemCount: filteredSenders.length,
                        itemBuilder: (context, index) {
                          final sender = filteredSenders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: sender.isActive ? Colors.green : Colors.grey,
                                child: const Icon(Icons.phone, color: Colors.white),
                              ),
                              title: Text(sender.displayName),
                              subtitle: Text(sender.phoneNumber),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: sender.isActive,
                                    onChanged: (value) async {
                                      await senderFilterProvider.toggleSenderFilterStatus(sender.id!);
                                    },
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: const Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        _showEditSenderDialog(sender);
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmDialog(sender);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSenderDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSenderDialog() {
    _displayNameController.clear();
    _phoneNumberController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Allowed Sender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., John Doe, Bank, etc.',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                hintText: 'e.g., +1234567890',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Info:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only SMS messages from these allowed senders will be forwarded. You can later assign each sender to specific groups.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveSender(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditSenderDialog(SenderFilterModel sender) {
    _displayNameController.text = sender.displayName;
    _phoneNumberController.text = sender.phoneNumber;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Allowed Sender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateSender(sender),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(SenderFilterModel sender) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Allowed Sender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${sender.displayName}"?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Warning: This will also remove all group mappings for this sender.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteSender(sender),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSender() async {
    if (_displayNameController.text.trim().isEmpty || _phoneNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final sender = SenderFilterModel(
      displayName: _displayNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
    );

    final success = await Provider.of<SenderFilterProvider>(context, listen: false).addSenderFilter(sender);
    
    Navigator.pop(context);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allowed sender added successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add allowed sender. Phone number might already exist.')),
      );
    }
  }

  Future<void> _updateSender(SenderFilterModel originalSender) async {
    if (_displayNameController.text.trim().isEmpty || _phoneNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final updatedSender = originalSender.copyWith(
      displayName: _displayNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
    );

    final success = await Provider.of<SenderFilterProvider>(context, listen: false).updateSenderFilter(updatedSender);
    
    Navigator.pop(context);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allowed sender updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update allowed sender')),
      );
    }
  }

  Future<void> _deleteSender(SenderFilterModel sender) async {
    final success = await Provider.of<SenderFilterProvider>(context, listen: false).deleteSenderFilter(sender.id!);
    
    Navigator.pop(context);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allowed sender deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete allowed sender')),
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
}