import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/bank_account_model.dart';
import '../services/bank_account_service.dart';

class BankAccountProvider with ChangeNotifier {
  final BankAccountService _service = BankAccountService();
  List<BankAccountModel> _accounts = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<BankAccountModel> get accounts => _accounts;
  BankAccountModel? get primaryAccount {
    try {
      return _accounts.firstWhere((acc) => acc.isPrimary);
    } catch (e) {
      return null;
    }
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasAccounts => _accounts.isNotEmpty;

  // Fetch all bank accounts
  Future<bool> fetchAccounts() async {
    developer.log('🟢 BankAccountProvider: Fetching bank accounts', name: 'BankAccountProvider');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getBankAccounts();
      developer.log('🟢 BankAccountProvider: Fetch result: ${result['success']}', name: 'BankAccountProvider');

      if (result['success'] == true && result['data'] != null) {
        final dynamic data = result['data'];

        // Handle different response structures
        List<dynamic> accountsJson;
        if (data is List) {
          accountsJson = data;
        } else if (data is Map && data['accounts'] != null) {
          accountsJson = data['accounts'];
        } else if (data is Map && data['data'] != null) {
          final innerData = data['data'];
          if (innerData is List) {
            accountsJson = innerData;
          } else if (innerData is Map && innerData['accounts'] != null) {
            accountsJson = innerData['accounts'];
          } else {
            accountsJson = [];
          }
        } else {
          accountsJson = [];
        }

        _accounts = accountsJson
            .map((json) => BankAccountModel.fromJson(json))
            .toList();

        developer.log('🟢 BankAccountProvider: Loaded ${_accounts.length} accounts', name: 'BankAccountProvider');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to fetch bank accounts';
        developer.log('🔴 BankAccountProvider: Fetch failed: $_errorMessage', name: 'BankAccountProvider');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('🔴 BankAccountProvider: Fetch exception: $e', name: 'BankAccountProvider');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create new bank account
  Future<bool> createAccount(BankAccountModel account) async {
    developer.log('🟢 BankAccountProvider: Creating bank account', name: 'BankAccountProvider');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.createBankAccount(
        bankName: account.bankName,
        accountNumber: account.accountNumber,
        accountHolderName: account.accountHolderName,
        branchAddress: account.branchAddress,
        swiftCode: account.swiftCode,
        routingNumber: account.routingNumber,
        isPrimary: account.isPrimary,
      );

      developer.log('🟢 BankAccountProvider: Create result: ${result['success']}', name: 'BankAccountProvider');

      if (result['success'] == true) {
        // Refresh the list after creating
        await fetchAccounts();
        developer.log('🟢 BankAccountProvider: Account created successfully', name: 'BankAccountProvider');
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to create bank account';
        developer.log('🔴 BankAccountProvider: Create failed: $_errorMessage', name: 'BankAccountProvider');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('🔴 BankAccountProvider: Create exception: $e', name: 'BankAccountProvider');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update existing bank account
  Future<bool> updateAccount(String id, BankAccountModel account) async {
    developer.log('🟢 BankAccountProvider: Updating bank account: $id', name: 'BankAccountProvider');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.updateBankAccount(
        accountId: id,
        bankName: account.bankName,
        accountNumber: account.accountNumber,
        accountHolderName: account.accountHolderName,
        branchAddress: account.branchAddress,
        swiftCode: account.swiftCode,
        routingNumber: account.routingNumber,
        isPrimary: account.isPrimary,
      );

      developer.log('🟢 BankAccountProvider: Update result: ${result['success']}', name: 'BankAccountProvider');

      if (result['success'] == true) {
        // Refresh the list after updating
        await fetchAccounts();
        developer.log('🟢 BankAccountProvider: Account updated successfully', name: 'BankAccountProvider');
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to update bank account';
        developer.log('🔴 BankAccountProvider: Update failed: $_errorMessage', name: 'BankAccountProvider');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('🔴 BankAccountProvider: Update exception: $e', name: 'BankAccountProvider');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete bank account
  Future<bool> deleteAccount(String id) async {
    developer.log('🟢 BankAccountProvider: Deleting bank account: $id', name: 'BankAccountProvider');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.deleteBankAccount(id);
      developer.log('🟢 BankAccountProvider: Delete result: ${result['success']}', name: 'BankAccountProvider');

      if (result['success'] == true) {
        // Refresh the list after deleting
        await fetchAccounts();
        developer.log('🟢 BankAccountProvider: Account deleted successfully', name: 'BankAccountProvider');
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to delete bank account';
        developer.log('🔴 BankAccountProvider: Delete failed: $_errorMessage', name: 'BankAccountProvider');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('🔴 BankAccountProvider: Delete exception: $e', name: 'BankAccountProvider');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Set primary bank account
  Future<bool> setPrimaryAccount(String id) async {
    developer.log('🟢 BankAccountProvider: Setting primary account: $id', name: 'BankAccountProvider');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.setPrimaryAccount(id);
      developer.log('🟢 BankAccountProvider: Set primary result: ${result['success']}', name: 'BankAccountProvider');

      if (result['success'] == true) {
        // Update local state: set all to non-primary, then set selected as primary
        _accounts = _accounts.map((account) {
          return account.copyWith(isPrimary: account.id == id);
        }).toList();

        _isLoading = false;
        developer.log('🟢 BankAccountProvider: Primary account set successfully', name: 'BankAccountProvider');
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to set primary account';
        developer.log('🔴 BankAccountProvider: Set primary failed: $_errorMessage', name: 'BankAccountProvider');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      developer.log('🔴 BankAccountProvider: Set primary exception: $e', name: 'BankAccountProvider');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
