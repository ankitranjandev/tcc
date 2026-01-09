import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/wallet_service.dart';
import '../../widgets/add_money_bottom_sheet.dart';

class SendGiftScreen extends StatefulWidget {
  const SendGiftScreen({super.key});

  @override
  State<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends State<SendGiftScreen> {
  final currencyFormat = NumberFormat.currency(symbol: 'TCC', decimalDigits: 2);

  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _messageController = TextEditingController();

  // Contacts state
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoadingContacts = false;
  final _searchController = TextEditingController();

  // Track which contacts are registered TCC users
  Set<String> _registeredPhoneNumbers = {};

  @override
  void initState() {
    super.initState();
    // Refresh user profile to get latest wallet balance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.loadUserProfile();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Send Gift',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipient Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recipient Mobile Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _isLoadingContacts
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _fetchContacts,
                          icon: Icon(Icons.contacts, size: 18),
                          label: Text('From Contacts'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                          ),
                        ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  controller: _recipientController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'e.g., 076123456',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(
                      Icons.phone,
                      color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Amount Section
              Text(
                'Gift Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixText: 'TCC',
                    prefixStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Quick Amount Selection (minimum 100 TCC)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickAmountChip('100'),
                  _buildQuickAmountChip('200'),
                  _buildQuickAmountChip('500'),
                  _buildQuickAmountChip('1000'),
                ],
              ),

              SizedBox(height: 24),

              // Personal Message
              Text(
                'Personal Message (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a personal message to your gift...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Summary Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withValues(alpha: 0.1),
                      AppColors.primaryBlue.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gift Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    if (_amountController.text.isNotEmpty) ...[
                      SizedBox(height: 12),
                      _buildSummaryRow(
                        'Amount',
                        'TCC${_amountController.text}',
                        highlight: true,
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sendGift,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard, color: AppColors.white),
                      SizedBox(width: 8),
                      Text(
                        'Send Gift',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchContacts() async {
    try {
      developer.log('=== CONTACT FETCH START ===', name: 'Contacts');

      // Check current permission status using permission_handler
      final permissionStatus = await Permission.contacts.status;
      developer.log('Current permission status: $permissionStatus', name: 'Contacts');
      debugPrint('[Contacts] Current permission status: $permissionStatus');

      if (permissionStatus.isDenied) {
        developer.log('Permission is denied, requesting...', name: 'Contacts');
        debugPrint('[Contacts] Permission is denied, requesting...');

        final requestResult = await Permission.contacts.request();
        developer.log('Permission request result: $requestResult', name: 'Contacts');
        debugPrint('[Contacts] Permission request result: $requestResult');

        if (!requestResult.isGranted) {
          developer.log('Permission NOT granted after request', name: 'Contacts');
          debugPrint('[Contacts] Permission NOT granted after request');

          if (requestResult.isPermanentlyDenied) {
            debugPrint('[Contacts] Permission is permanently denied');
            if (mounted) {
              _showPermissionDeniedDialog();
            }
            return;
          }

          if (mounted) {
            _showError('Contact permission is required to fetch contacts');
          }
          return;
        }
      } else if (permissionStatus.isPermanentlyDenied) {
        developer.log('Permission is permanently denied', name: 'Contacts');
        debugPrint('[Contacts] Permission is permanently denied');
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return;
      } else if (permissionStatus.isRestricted) {
        developer.log('Permission is restricted', name: 'Contacts');
        debugPrint('[Contacts] Permission is restricted (parental controls)');
        if (mounted) {
          _showError('Contact access is restricted on this device');
        }
        return;
      }

      developer.log('Permission granted, fetching contacts...', name: 'Contacts');
      debugPrint('[Contacts] Permission granted, fetching contacts...');

      setState(() {
        _isLoadingContacts = true;
      });

      // Fetch all contacts with phone properties
      developer.log('Calling FlutterContacts.getContacts...', name: 'Contacts');
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      developer.log('Fetched ${contacts.length} total contacts', name: 'Contacts');
      debugPrint('[Contacts] Fetched ${contacts.length} total contacts');

      // Filter contacts that have at least one phone number
      final contactsWithPhone = contacts.where((c) => c.phones.isNotEmpty).toList();
      developer.log('Contacts with phone numbers: ${contactsWithPhone.length}', name: 'Contacts');
      debugPrint('[Contacts] Contacts with phone numbers: ${contactsWithPhone.length}');

      // Extract all phone numbers for batch verification
      final phoneNumbers = <String>[];
      for (final contact in contactsWithPhone) {
        for (final phone in contact.phones) {
          final cleanedNumber = _cleanPhoneNumber(phone.number);
          if (cleanedNumber.isNotEmpty) {
            phoneNumbers.add(cleanedNumber);
          }
        }
      }

      developer.log('Checking ${phoneNumbers.length} phone numbers for TCC registration', name: 'Contacts');
      debugPrint('[Contacts] Checking ${phoneNumbers.length} phone numbers for TCC registration');

      // Query the database to find registered users
      Set<String> registeredNumbers = {};
      if (phoneNumbers.isNotEmpty) {
        try {
          final walletService = WalletService();
          final result = await walletService.verifyMultiplePhones(
            phoneNumbers: phoneNumbers,
          );

          if (result['success'] == true && result['data'] != null) {
            final data = result['data'];
            // Expecting response format: { registered_phones: ["076123456", "077654321", ...] }
            if (data['registered_phones'] != null) {
              registeredNumbers = Set<String>.from(
                (data['registered_phones'] as List).map((e) => e.toString()),
              );
            }
          }

          developer.log('Found ${registeredNumbers.length} registered TCC users', name: 'Contacts');
          debugPrint('[Contacts] Found ${registeredNumbers.length} registered TCC users');
        } catch (e) {
          developer.log('Error checking registered users: $e', name: 'Contacts');
          debugPrint('[Contacts] Error checking registered users: $e');
          // Continue without registration info - just show all contacts
        }
      }

      // Sort contacts: registered TCC users first, then alphabetically within each group
      contactsWithPhone.sort((a, b) {
        final aIsRegistered = _isContactRegistered(a, registeredNumbers);
        final bIsRegistered = _isContactRegistered(b, registeredNumbers);

        if (aIsRegistered && !bIsRegistered) return -1;
        if (!aIsRegistered && bIsRegistered) return 1;
        return a.displayName.compareTo(b.displayName);
      });

      setState(() {
        _contacts = contactsWithPhone;
        _filteredContacts = contactsWithPhone;
        _registeredPhoneNumbers = registeredNumbers;
        _isLoadingContacts = false;
      });

      developer.log('=== CONTACT FETCH SUCCESS ===', name: 'Contacts');
      debugPrint('[Contacts] === CONTACT FETCH SUCCESS ===');

      // Show the contacts bottom sheet
      if (mounted) {
        _showContactsBottomSheet();
      }
    } catch (e, stackTrace) {
      developer.log('=== CONTACT FETCH ERROR ===', name: 'Contacts');
      developer.log('Error: $e', name: 'Contacts');
      developer.log('Stack trace: $stackTrace', name: 'Contacts');
      debugPrint('[Contacts] === CONTACT FETCH ERROR ===');
      debugPrint('[Contacts] Error: $e');
      debugPrint('[Contacts] Stack trace: $stackTrace');

      setState(() {
        _isLoadingContacts = false;
      });
      if (mounted) {
        _showError('Failed to fetch contacts: ${e.toString()}');
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.contacts, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Contact Access Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact permission has been denied. Please enable it in your device settings to select contacts for gift transfers.',
            ),
            SizedBox(height: 16),
            Text(
              'Go to Settings > Apps > TCC > Permissions > Contacts',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final nameLower = contact.displayName.toLowerCase();
          final queryLower = query.toLowerCase();
          // Also search by phone number
          final phoneMatch = contact.phones.any((phone) =>
              phone.number.replaceAll(RegExp(r'[^\d]'), '').contains(query.replaceAll(RegExp(r'[^\d]'), '')));
          return nameLower.contains(queryLower) || phoneMatch;
        }).toList();

        // Maintain sorting: registered users first, then alphabetically
        _filteredContacts.sort((a, b) {
          final aIsRegistered = _isContactRegistered(a, _registeredPhoneNumbers);
          final bIsRegistered = _isContactRegistered(b, _registeredPhoneNumbers);

          if (aIsRegistered && !bIsRegistered) return -1;
          if (!aIsRegistered && bIsRegistered) return 1;
          return a.displayName.compareTo(b.displayName);
        });
      }
    });
  }

  String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except leading +
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Remove country code if present (assuming Sierra Leone +232)
    if (phoneNumber.startsWith('+232')) {
      phoneNumber = phoneNumber.substring(4);
    } else if (phoneNumber.startsWith('232')) {
      phoneNumber = phoneNumber.substring(3);
    }

    return phoneNumber;
  }

  // Check if any of the contact's phone numbers is registered
  bool _isContactRegistered(Contact contact, Set<String> registeredNumbers) {
    for (final phone in contact.phones) {
      final cleanedNumber = _cleanPhoneNumber(phone.number);
      if (registeredNumbers.contains(cleanedNumber)) {
        return true;
      }
    }
    return false;
  }

  void _showContactsBottomSheet() {
    _searchController.clear();
    _filteredContacts = _contacts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.contacts, color: AppColors.primaryBlue),
                      SizedBox(width: 12),
                      Text(
                        'Select Contact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                // Search field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or number...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterContacts('');
                                  setModalState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        _filterContacts(value);
                        setModalState(() {});
                      },
                    ),
                  ),
                ),

                SizedBox(height: 8),

                // Contact count with registered user info
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredContacts.length} contacts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_registeredPhoneNumbers.isNotEmpty) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_filteredContacts.where((c) => _isContactRegistered(c, _registeredPhoneNumbers)).length} on TCC',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Contacts list
                Expanded(
                  child: _filteredContacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'No contacts found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            final phoneNumber = contact.phones.first.number;
                            final isRegistered = _isContactRegistered(contact, _registeredPhoneNumbers);

                            return InkWell(
                              onTap: () {
                                final cleanedNumber = _cleanPhoneNumber(phoneNumber);
                                setState(() {
                                  _recipientController.text = cleanedNumber;
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: isRegistered
                                    ? BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.03),
                                      )
                                    : null,
                                child: Row(
                                  children: [
                                    // Contact avatar with TCC indicator
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: isRegistered
                                              ? AppColors.success.withValues(alpha: 0.1)
                                              : AppColors.primaryBlue.withValues(alpha: 0.1),
                                          backgroundImage: contact.photo != null
                                              ? MemoryImage(contact.photo!)
                                              : null,
                                          child: contact.photo == null
                                              ? Text(
                                                  contact.displayName.isNotEmpty
                                                      ? contact.displayName[0].toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    color: isRegistered
                                                        ? AppColors.success
                                                        : AppColors.primaryBlue,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 18,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        if (isRegistered)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: AppColors.success,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Theme.of(context).scaffoldBackgroundColor,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                size: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(width: 12),

                                    // Contact info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  contact.displayName,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isRegistered) ...[
                                                SizedBox(width: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.success.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'TCC',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.success,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            phoneNumber,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Arrow icon
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAmountChip(String amount) {
    final isSelected = _amountController.text == amount.replaceAll(',', '');

    return GestureDetector(
      onTap: () {
        setState(() {
          _amountController.text = amount.replaceAll(',', '');
        });
      },
      child: Chip(
        label: Text(
          'TCC$amount',
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.primaryBlue,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isSelected
            ? AppColors.primaryBlue
            : AppColors.primaryBlue.withValues(alpha: 0.1),
        side: BorderSide(
          color: AppColors.primaryBlue,
          width: isSelected ? 0 : 1,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
            color: highlight ? AppColors.primaryBlue : null,
          ),
        ),
      ],
    );
  }

  Future<void> _sendGift() async {
    // Validation
    if (_recipientController.text.isEmpty) {
      _showError('Please enter recipient details');
      return;
    }

    if (_amountController.text.isEmpty) {
      _showError('Please enter gift amount');
      return;
    }

    // Parse the amount
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    // Validate minimum transfer amount (backend requirement)
    if (amount < 100) {
      _showError('Minimum transfer amount is 100 TCC');
      return;
    }

    // Get user's wallet balance
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletBalance = authProvider.user?.walletBalance ?? 0;

    // Check if user has sufficient balance
    if (walletBalance < amount) {
      _showInsufficientBalanceDialog(amount, walletBalance);
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showGiftConfirmationDialog(amount, walletBalance);

    if (confirmed == true) {
      await _processGiftTransfer(amount);
    }
  }

  void _showInsufficientBalanceDialog(double required, double available) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Insufficient Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You don\'t have enough TCC coins to send this gift.'),
            SizedBox(height: 16),
            Text('Required: Le ${required.toStringAsFixed(2)}'),
            Text('Available: Le ${available.toStringAsFixed(2)}'),
            Text(
              'Shortfall: Le ${(required - available).toStringAsFixed(2)}',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showAddMoneyBottomSheet(
                context,
                onSuccess: () {
                  // Refresh user profile to get updated balance
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  authProvider.loadUserProfile();
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text('Add Funds', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showGiftConfirmationDialog(double amount, double walletBalance) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Gift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to send a gift',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            _buildSummaryRow('Recipient', _recipientController.text),
            SizedBox(height: 8),
            _buildSummaryRow('Amount', 'TCC${amount.toStringAsFixed(2)}', highlight: true),
            if (_messageController.text.isNotEmpty) ...[
              SizedBox(height: 8),
              _buildSummaryRow('Message', _messageController.text),
            ],
            SizedBox(height: 16),
            Text(
              'New Balance: Le ${(walletBalance - amount).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Payment will be deducted from your TCC wallet',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text('Send Gift', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _processGiftTransfer(double amount) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verifying recipient...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final walletService = WalletService();

      // First, verify if the recipient user exists
      final verifyResult = await walletService.verifyUserExists(
        phoneNumber: _recipientController.text,
      );

      if (verifyResult['success'] != true) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          _showErrorDialog(
            'The phone number you entered is not registered with TCC. '
            'Please make sure the recipient has a TCC account.',
          );
        }
        return;
      }

      // Update loading message
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing gift...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Request OTP for transfer
      final otpResult = await walletService.requestTransferOTP(
        recipientPhone: _recipientController.text,
        amount: amount,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (otpResult['success'] == true) {
        // Show OTP dialog
        final otp = await _showOTPDialog();

        if (otp != null && otp.isNotEmpty) {
          // Process transfer with OTP
          await _completeGiftTransfer(amount, otp);
        }
      } else {
        if (mounted) {
          _showErrorDialog(otpResult['error'] ?? 'Failed to request OTP');
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<String?> _showOTPDialog() {
    final otpController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please enter the OTP sent to your registered phone number.'),
            SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, otpController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text('Verify', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeGiftTransfer(double amount, String otp) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verifying and processing...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final walletService = WalletService();
      final result = await walletService.transfer(
        recipientPhone: _recipientController.text,
        amount: amount,
        otp: otp,
        note: _messageController.text.isNotEmpty ? _messageController.text : null,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        // Reload user profile to update wallet balance
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.loadUserProfile();
        }

        if (mounted) {
          _showSuccessDialog(amount);
        }
      } else {
        if (mounted) {
          _showErrorDialog(result['error'] ?? 'Failed to send gift');
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Text('Gift Sent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your gift of Le ${amount.toStringAsFixed(2)} has been sent successfully.'),
            SizedBox(height: 16),
            Text(
              'The recipient will receive the TCC coins shortly.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard'); // Go back to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('Transfer Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}