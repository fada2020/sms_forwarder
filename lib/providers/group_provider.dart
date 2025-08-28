import 'package:flutter/foundation.dart';
import '../models/group_model.dart';
import '../models/contact_model.dart';
import '../models/sender_filter_model.dart';
import '../models/group_member_model.dart';
import '../models/sender_group_mapping_model.dart';
import '../services/database_service.dart';

class GroupProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<GroupModel> _groups = [];
  bool _isLoading = false;

  List<GroupModel> get groups => _groups;
  List<GroupModel> get activeGroups => 
      _groups.where((group) => group.isActive).toList();
  bool get isLoading => _isLoading;

  Future<int> getGroupCount() async {
    return _groups.length;
  }

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await _databaseService.getAllGroups();
    } catch (e) {
      debugPrint('Error loading groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addGroup(GroupModel group) async {
    try {
      final id = await _databaseService.insertGroup(group);
      if (id > 0) {
        final newGroup = group.copyWith(id: id);
        _groups.add(newGroup);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding group: $e');
    }
    return false;
  }

  Future<bool> updateGroup(GroupModel group) async {
    try {
      final result = await _databaseService.updateGroup(group);
      if (result > 0) {
        final index = _groups.indexWhere((g) => g.id == group.id);
        if (index != -1) {
          _groups[index] = group;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error updating group: $e');
    }
    return false;
  }

  Future<bool> deleteGroup(int id) async {
    try {
      final result = await _databaseService.deleteGroup(id);
      if (result > 0) {
        _groups.removeWhere((group) => group.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting group: $e');
    }
    return false;
  }

  Future<bool> toggleGroupStatus(int id) async {
    final group = _groups.firstWhere((g) => g.id == id);
    final updatedGroup = group.copyWith(isActive: !group.isActive);
    return await updateGroup(updatedGroup);
  }

  // Group member management
  Future<bool> addMemberToGroup(int groupId, int contactId) async {
    try {
      final groupMember = GroupMemberModel(
        groupId: groupId,
        contactId: contactId,
      );
      final id = await _databaseService.insertGroupMember(groupMember);
      return id > 0;
    } catch (e) {
      debugPrint('Error adding member to group: $e');
      return false;
    }
  }

  Future<bool> removeMemberFromGroup(int groupId, int contactId) async {
    try {
      final result = await _databaseService.removeGroupMember(groupId, contactId);
      return result > 0;
    } catch (e) {
      debugPrint('Error removing member from group: $e');
      return false;
    }
  }

  Future<List<ContactModel>> getGroupMembers(int groupId) async {
    try {
      return await _databaseService.getGroupMembers(groupId);
    } catch (e) {
      debugPrint('Error getting group members: $e');
      return [];
    }
  }

  Future<List<GroupModel>> getContactGroups(int contactId) async {
    try {
      return await _databaseService.getContactGroups(contactId);
    } catch (e) {
      debugPrint('Error getting contact groups: $e');
      return [];
    }
  }

  Future<bool> isContactInGroup(int groupId, int contactId) async {
    try {
      return await _databaseService.isContactInGroup(groupId, contactId);
    } catch (e) {
      debugPrint('Error checking if contact is in group: $e');
      return false;
    }
  }

  // Sender group mapping management
  Future<bool> mapSenderToGroup(int senderFilterId, int groupId) async {
    try {
      final mapping = SenderGroupMappingModel(
        senderFilterId: senderFilterId,
        groupId: groupId,
      );
      final id = await _databaseService.insertSenderGroupMapping(mapping);
      return id > 0;
    } catch (e) {
      debugPrint('Error mapping sender to group: $e');
      return false;
    }
  }

  Future<bool> removeSenderFromGroup(int senderFilterId, int groupId) async {
    try {
      final result = await _databaseService.removeSenderGroupMapping(senderFilterId, groupId);
      return result > 0;
    } catch (e) {
      debugPrint('Error removing sender from group: $e');
      return false;
    }
  }

  Future<List<GroupModel>> getSenderGroups(int senderFilterId) async {
    try {
      return await _databaseService.getSenderGroups(senderFilterId);
    } catch (e) {
      debugPrint('Error getting sender groups: $e');
      return [];
    }
  }

  Future<List<SenderFilterModel>> getGroupSenders(int groupId) async {
    try {
      return await _databaseService.getGroupSenders(groupId);
    } catch (e) {
      debugPrint('Error getting group senders: $e');
      return [];
    }
  }

  Future<bool> isSenderMappedToGroup(int senderFilterId, int groupId) async {
    try {
      return await _databaseService.isSenderMappedToGroup(senderFilterId, groupId);
    } catch (e) {
      debugPrint('Error checking sender group mapping: $e');
      return false;
    }
  }

  Future<List<ContactModel>> getContactsForSender(String senderPhoneNumber) async {
    try {
      return await _databaseService.getContactsForSender(senderPhoneNumber);
    } catch (e) {
      debugPrint('Error getting contacts for sender: $e');
      return [];
    }
  }

  GroupModel? getGroupById(int id) {
    try {
      return _groups.firstWhere((group) => group.id == id);
    } catch (e) {
      return null;
    }
  }

  List<GroupModel> searchGroups(String query) {
    if (query.isEmpty) return _groups;
    
    final lowercaseQuery = query.toLowerCase();
    return _groups.where((group) =>
        group.name.toLowerCase().contains(lowercaseQuery) ||
        group.description.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
}