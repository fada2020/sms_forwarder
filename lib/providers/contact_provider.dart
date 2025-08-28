import 'package:flutter/foundation.dart';
import '../models/contact_model.dart';
import '../services/database_service.dart';

class ContactProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<ContactModel> _contacts = [];
  bool _isLoading = false;

  List<ContactModel> get contacts => _contacts;
  List<ContactModel> get activeContacts => 
      _contacts.where((contact) => contact.isActive).toList();
  bool get isLoading => _isLoading;

  Future<void> loadContacts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _contacts = await _databaseService.getAllContacts();
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addContact(ContactModel contact) async {
    try {
      final id = await _databaseService.insertContact(contact);
      if (id > 0) {
        final newContact = contact.copyWith(id: id);
        _contacts.add(newContact);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
    return false;
  }

  Future<bool> updateContact(ContactModel contact) async {
    try {
      final result = await _databaseService.updateContact(contact);
      if (result > 0) {
        final index = _contacts.indexWhere((c) => c.id == contact.id);
        if (index != -1) {
          _contacts[index] = contact;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error updating contact: $e');
    }
    return false;
  }

  Future<bool> deleteContact(int id) async {
    try {
      final result = await _databaseService.deleteContact(id);
      if (result > 0) {
        _contacts.removeWhere((contact) => contact.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting contact: $e');
    }
    return false;
  }

  Future<bool> toggleContactStatus(int id) async {
    final contact = _contacts.firstWhere((c) => c.id == id);
    final updatedContact = contact.copyWith(isActive: !contact.isActive);
    return await updateContact(updatedContact);
  }

  ContactModel? getContactById(int id) {
    try {
      return _contacts.firstWhere((contact) => contact.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ContactModel> searchContacts(String query) {
    if (query.isEmpty) return _contacts;
    
    final lowercaseQuery = query.toLowerCase();
    return _contacts.where((contact) =>
        contact.name.toLowerCase().contains(lowercaseQuery) ||
        contact.phoneNumber.contains(query)
    ).toList();
  }
}