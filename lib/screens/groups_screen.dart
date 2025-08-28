import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/sender_filter_provider.dart';
import '../models/group_model.dart';
import '../models/contact_model.dart';
import '../models/sender_filter_model.dart';

class GroupsScreen extends StatefulWidget {
  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, child) {
          final filteredGroups = _searchQuery.isEmpty
              ? groupProvider.groups
              : groupProvider.searchGroups(_searchQuery);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search groups',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: filteredGroups.isEmpty
                    ? const Center(child: Text('No groups found'))
                    : ListView.builder(
                        itemCount: filteredGroups.length,
                        itemBuilder: (context, index) {
                          final group = filteredGroups[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: group.isActive ? Colors.green : Colors.grey,
                                child: const Icon(Icons.group, color: Colors.white),
                              ),
                              title: Text(group.name),
                              subtitle: Text(group.description.isEmpty ? 'No description' : group.description),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'manage_members',
                                    child: const Text('Manage Members'),
                                  ),
                                  PopupMenuItem(
                                    value: 'manage_senders',
                                    child: const Text('Manage Senders'),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: const Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Text(group.isActive ? 'Deactivate' : 'Activate'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: const Text('Delete'),
                                  ),
                                ],
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'manage_members':
                                      _showManageMembersDialog(group);
                                      break;
                                    case 'manage_senders':
                                      _showManageSendersDialog(group);
                                      break;
                                    case 'edit':
                                      _showEditGroupDialog(group);
                                      break;
                                    case 'toggle':
                                      await groupProvider.toggleGroupStatus(group.id!);
                                      break;
                                    case 'delete':
                                      _showDeleteConfirmDialog(group);
                                      break;
                                  }
                                },
                              ),
                              children: [
                                FutureBuilder<List<ContactModel>>(
                                  future: groupProvider.getGroupMembers(group.id!),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final members = snapshot.data!;
                                      return Column(
                                        children: members.map((member) => ListTile(
                                          leading: const Icon(Icons.person),
                                          title: Text(member.name),
                                          subtitle: Text(member.phoneNumber),
                                        )).toList(),
                                      );
                                    }
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    );
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
        onPressed: () => _showAddGroupDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddGroupDialog() {
    _nameController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveGroup(),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(GroupModel group) {
    _nameController.text = group.name;
    _descriptionController.text = group.description;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateGroup(group),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showManageMembersDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => _GroupMembersDialog(group: group),
    );
  }

  void _showManageSendersDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => _GroupSendersDialog(group: group),
    );
  }

  void _showDeleteConfirmDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteGroup(group),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    final group = GroupModel(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    final success = await Provider.of<GroupProvider>(context, listen: false).addGroup(group);
    
    Navigator.pop(context);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create group')),
      );
    }
  }

  Future<void> _updateGroup(GroupModel originalGroup) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    final updatedGroup = originalGroup.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    final success = await Provider.of<GroupProvider>(context, listen: false).updateGroup(updatedGroup);
    
    Navigator.pop(context);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update group')),
      );
    }
  }

  Future<void> _deleteGroup(GroupModel group) async {
    final success = await Provider.of<GroupProvider>(context, listen: false).deleteGroup(group.id!);
    
    Navigator.pop(context);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete group')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _GroupMembersDialog extends StatefulWidget {
  final GroupModel group;

  const _GroupMembersDialog({required this.group});

  @override
  _GroupMembersDialogState createState() => _GroupMembersDialogState();
}

class _GroupMembersDialogState extends State<_GroupMembersDialog> {
  List<ContactModel> _allContacts = [];
  List<ContactModel> _groupMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    _allContacts = contactProvider.activeContacts;
    _groupMembers = await groupProvider.getGroupMembers(widget.group.id!);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Manage Members - ${widget.group.name}'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: _allContacts.length,
                itemBuilder: (context, index) {
                  final contact = _allContacts[index];
                  final isMember = _groupMembers.any((m) => m.id == contact.id);

                  return CheckboxListTile(
                    title: Text(contact.name),
                    subtitle: Text(contact.phoneNumber),
                    value: isMember,
                    onChanged: (value) async {
                      if (value == true) {
                        await _addMember(contact);
                      } else {
                        await _removeMember(contact);
                      }
                    },
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Future<void> _addMember(ContactModel contact) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final success = await groupProvider.addMemberToGroup(widget.group.id!, contact.id!);
    
    if (success) {
      setState(() {
        _groupMembers.add(contact);
      });
    }
  }

  Future<void> _removeMember(ContactModel contact) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final success = await groupProvider.removeMemberFromGroup(widget.group.id!, contact.id!);
    
    if (success) {
      setState(() {
        _groupMembers.removeWhere((m) => m.id == contact.id);
      });
    }
  }
}

class _GroupSendersDialog extends StatefulWidget {
  final GroupModel group;

  const _GroupSendersDialog({required this.group});

  @override
  _GroupSendersDialogState createState() => _GroupSendersDialogState();
}

class _GroupSendersDialogState extends State<_GroupSendersDialog> {
  List<SenderFilterModel> _allSenders = [];
  List<SenderFilterModel> _groupSenders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final senderFilterProvider = Provider.of<SenderFilterProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    _allSenders = senderFilterProvider.activeSenderFilters;
    _groupSenders = await groupProvider.getGroupSenders(widget.group.id!);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Manage Senders - ${widget.group.name}'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: _allSenders.length,
                itemBuilder: (context, index) {
                  final sender = _allSenders[index];
                  final isMapped = _groupSenders.any((s) => s.id == sender.id);

                  return CheckboxListTile(
                    title: Text(sender.displayName),
                    subtitle: Text(sender.phoneNumber),
                    value: isMapped,
                    onChanged: (value) async {
                      if (value == true) {
                        await _mapSender(sender);
                      } else {
                        await _unmapSender(sender);
                      }
                    },
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Future<void> _mapSender(SenderFilterModel sender) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final success = await groupProvider.mapSenderToGroup(sender.id!, widget.group.id!);
    
    if (success) {
      setState(() {
        _groupSenders.add(sender);
      });
    }
  }

  Future<void> _unmapSender(SenderFilterModel sender) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final success = await groupProvider.removeSenderFromGroup(sender.id!, widget.group.id!);
    
    if (success) {
      setState(() {
        _groupSenders.removeWhere((s) => s.id == sender.id);
      });
    }
  }
}