import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../providers/contact_provider.dart';
import '../models/contact_model.dart';

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ContactProvider>(
        builder: (context, contactProvider, child) {
          final filteredContacts = _searchQuery.isEmpty
              ? contactProvider.contacts
              : contactProvider.searchContacts(_searchQuery);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search contacts',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: filteredContacts.isEmpty
                    ? const Center(child: Text('No contacts found'))
                    : ListView.builder(
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = filteredContacts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?'),
                            ),
                            title: Text(contact.name),
                            subtitle: Text(contact.phoneNumber),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: contact.isActive,
                                  onChanged: (value) async {
                                    await contactProvider.toggleContactStatus(contact.id!);
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
                                      _showEditContactDialog(contact);
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmDialog(contact);
                                    }
                                  },
                                ),
                              ],
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
        onPressed: () => _showAddContactDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddContactDialog() {
    _nameController.clear();
    _phoneController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectFromPhoneContacts,
              icon: const Icon(Icons.contacts),
              label: const Text('Select from Phone Contacts'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveContact(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(ContactModel contact) {
    _nameController.text = contact.name;
    _phoneController.text = contact.phoneNumber;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
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
            onPressed: () => _updateContact(contact),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(ContactModel contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteContact(contact),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFromPhoneContacts() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(withProperties: true);
        
        final selectedContact = await showDialog<Contact>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Select Contact'),
            children: contacts.map((contact) {
              final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, contact),
                child: ListTile(
                  title: Text(contact.displayName),
                  subtitle: Text(phone),
                ),
              );
            }).toList(),
          ),
        );

        if (selectedContact != null) {
          _nameController.text = selectedContact.displayName;
          if (selectedContact.phones.isNotEmpty) {
            _phoneController.text = selectedContact.phones.first.number;
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact permission denied')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing contacts: $e')),
      );
    }
  }

  Future<void> _saveContact() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final contact = ContactModel(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    final success = await Provider.of<ContactProvider>(context, listen: false).addContact(contact);
    
    Navigator.pop(context);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact added successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add contact')),
      );
    }
  }

  Future<void> _updateContact(ContactModel originalContact) async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final updatedContact = originalContact.copyWith(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    final success = await Provider.of<ContactProvider>(context, listen: false).updateContact(updatedContact);
    
    Navigator.pop(context);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update contact')),
      );
    }
  }

  Future<void> _deleteContact(ContactModel contact) async {
    final success = await Provider.of<ContactProvider>(context, listen: false).deleteContact(contact.id!);
    
    Navigator.pop(context);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete contact')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}