import 'package:flutter/foundation.dart';
import '../models/sender_filter_model.dart';
import '../services/database_service.dart';

class SenderFilterProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<SenderFilterModel> _senderFilters = [];
  bool _isLoading = false;

  List<SenderFilterModel> get senderFilters => _senderFilters;
  List<SenderFilterModel> get activeSenderFilters => 
      _senderFilters.where((filter) => filter.isActive).toList();
  bool get isLoading => _isLoading;

  Future<void> loadSenderFilters() async {
    _isLoading = true;
    notifyListeners();

    try {
      _senderFilters = await _databaseService.getAllSenderFilters();
    } catch (e) {
      debugPrint('Error loading sender filters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSenderFilter(SenderFilterModel senderFilter) async {
    try {
      final id = await _databaseService.insertSenderFilter(senderFilter);
      if (id > 0) {
        final newSenderFilter = senderFilter.copyWith(id: id);
        _senderFilters.add(newSenderFilter);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding sender filter: $e');
    }
    return false;
  }

  Future<bool> updateSenderFilter(SenderFilterModel senderFilter) async {
    try {
      final result = await _databaseService.updateSenderFilter(senderFilter);
      if (result > 0) {
        final index = _senderFilters.indexWhere((f) => f.id == senderFilter.id);
        if (index != -1) {
          _senderFilters[index] = senderFilter;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error updating sender filter: $e');
    }
    return false;
  }

  Future<bool> deleteSenderFilter(int id) async {
    try {
      final result = await _databaseService.deleteSenderFilter(id);
      if (result > 0) {
        _senderFilters.removeWhere((filter) => filter.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting sender filter: $e');
    }
    return false;
  }

  Future<bool> toggleSenderFilterStatus(int id) async {
    final filter = _senderFilters.firstWhere((f) => f.id == id);
    final updatedFilter = filter.copyWith(isActive: !filter.isActive);
    return await updateSenderFilter(updatedFilter);
  }

  bool isPhoneNumberAllowed(String phoneNumber) {
    if (_senderFilters.isEmpty) return false;
    
    return _senderFilters.any((filter) => 
        filter.isActive && filter.phoneNumber == phoneNumber);
  }

  SenderFilterModel? getSenderFilterByPhoneNumber(String phoneNumber) {
    try {
      return _senderFilters.firstWhere(
        (filter) => filter.phoneNumber == phoneNumber && filter.isActive);
    } catch (e) {
      return null;
    }
  }

  SenderFilterModel? getSenderFilterById(int id) {
    try {
      return _senderFilters.firstWhere((filter) => filter.id == id);
    } catch (e) {
      return null;
    }
  }

  List<SenderFilterModel> searchSenderFilters(String query) {
    if (query.isEmpty) return _senderFilters;
    
    final lowercaseQuery = query.toLowerCase();
    return _senderFilters.where((filter) =>
        filter.displayName.toLowerCase().contains(lowercaseQuery) ||
        filter.phoneNumber.contains(query)
    ).toList();
  }
}