import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../services/kyc_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/dialogs/document_viewer_dialog.dart';

class KYCReviewDetailScreen extends StatefulWidget {
  final String submissionId;
  final String userId;

  const KYCReviewDetailScreen({
    super.key,
    required this.submissionId,
    required this.userId,
  });

  @override
  State<KYCReviewDetailScreen> createState() => _KYCReviewDetailScreenState();
}

class _KYCReviewDetailScreenState extends State<KYCReviewDetailScreen> {
  final KycService _kycService = KycService();

  Map<String, dynamic>? _submissionDetails;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  // Rejection reason state
  final List<String> _predefinedReasons = [
    'Document is blurry or unreadable',
    'Document has expired',
    'Document is incomplete or cut off',
    'Photo does not match document',
    'Document appears invalid or tampered',
    'Wrong type of document submitted',
  ];
  final Map<String, bool> _selectedReasons = {};
  final TextEditingController _customReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubmissionDetails();
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissionDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _kycService.getKycSubmissionById(widget.submissionId);

      if (response.success && response.data != null) {
        setState(() {
          _submissionDetails = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load submission details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprove() async {
    final confirmed = await _showConfirmDialog(
      'Approve KYC',
      'Are you sure you want to approve this KYC submission?',
      isApprove: true,
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _kycService.reviewKycSubmission(
        submissionId: widget.submissionId,
        action: 'approve',
        remarks: 'KYC approved by admin',
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('KYC approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to approve KYC'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleReject() async {
    // Show rejection reason dialog
    final reasons = await _showRejectionDialog();
    if (reasons == null || reasons.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Reject KYC',
      'Are you sure you want to reject this KYC submission?',
      isApprove: false,
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _kycService.reviewKycSubmission(
        submissionId: widget.submissionId,
        action: 'reject',
        remarks: reasons,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('KYC rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to reject KYC'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message, {required bool isApprove}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppColors.success : AppColors.error,
            ),
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRejectionDialog() {
    // Reset state
    _selectedReasons.clear();
    _customReasonController.clear();

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rejection Reasons'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select one or more reasons:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  ..._predefinedReasons.map((reason) {
                    return CheckboxListTile(
                      value: _selectedReasons[reason] ?? false,
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedReasons[reason] = value ?? false;
                        });
                      },
                      title: Text(
                        reason,
                        style: const TextStyle(fontSize: 14),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    'Custom reason (optional):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  TextField(
                    controller: _customReasonController,
                    decoration: const InputDecoration(
                      hintText: 'Enter custom reason...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final selectedReasonsList = _selectedReasons.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();

                final customReason = _customReasonController.text.trim();
                if (customReason.isNotEmpty) {
                  selectedReasonsList.add(customReason);
                }

                if (selectedReasonsList.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one reason'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context, selectedReasonsList.join('\n• '));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Confirm Rejection'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Review'),
        actions: [
          if (!_isLoading && _submissionDetails != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSubmissionDetails,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          'Error Loading Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.space24),
                        ElevatedButton.icon(
                          onPressed: _loadSubmissionDetails,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isMobile ? AppTheme.space16 : AppTheme.space24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfoSection(isMobile),
                      const SizedBox(height: AppTheme.space24),
                      _buildDocumentsSection(isMobile),
                      const SizedBox(height: AppTheme.space24),
                      _buildBankDetailsSection(isMobile),
                      const SizedBox(height: AppTheme.space32),
                      _buildActionButtons(isMobile),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserInfoSection(bool isMobile) {
    final user = _submissionDetails!['user'];
    final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final email = user['email'] ?? '';
    final phone = user['phone'] ?? '';
    final kycStatus = user['kyc_status'] ?? 'PENDING';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Information',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            _buildInfoRow('Name', name.isNotEmpty ? name : 'Unknown'),
            _buildInfoRow('Email', email),
            _buildInfoRow('Phone', phone),
            _buildInfoRow('Status', kycStatus, isStatus: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isStatus
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(value).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(value),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(bool isMobile) {
    final documents = _submissionDetails!['documents'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uploaded Documents',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            if (documents.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Text(
                    'No documents uploaded',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...documents.map((doc) => _buildDocumentCard(doc, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc, bool isMobile) {
    final documentType = doc['document_type'] ?? 'Unknown';
    final documentUrl = doc['document_url'] ?? '';
    final documentNumber = doc['document_number'] ?? '';
    final status = doc['status'] ?? 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      padding: EdgeInsets.all(isMobile ? AppTheme.space12 : AppTheme.space16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getDocumentIcon(documentType),
                size: 20,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  _formatDocumentType(documentType),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space8,
                  vertical: AppTheme.space4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          if (documentNumber.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space8),
            Text(
              'Number: $documentNumber',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.space12),
          OutlinedButton.icon(
            onPressed: documentUrl.isNotEmpty
                ? () {
                    DocumentViewerDialog.show(
                      context,
                      documentUrl: documentUrl,
                      documentType: documentType,
                      documentNumber: documentNumber,
                    );
                  }
                : null,
            icon: const Icon(Icons.visibility, size: 16),
            label: Text(documentUrl.isNotEmpty ? 'View Document' : 'No Document'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType.toUpperCase()) {
      case 'NATIONAL_ID':
        return Icons.badge;
      case 'PASSPORT':
        return Icons.menu_book;
      case 'DRIVERS_LICENSE':
        return Icons.directions_car;
      case 'VOTER_CARD':
        return Icons.how_to_vote;
      case 'BANK_RECEIPT':
        return Icons.receipt_long;
      case 'AGREEMENT':
        return Icons.handshake;
      case 'INSURANCE_POLICY':
        return Icons.security;
      case 'SELFIE':
        return Icons.face;
      default:
        return Icons.description;
    }
  }

  String _formatDocumentType(String documentType) {
    return documentType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  Widget _buildBankDetailsSection(bool isMobile) {
    final bankAccounts = _submissionDetails!['bank_accounts'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppTheme.space16 : AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Details',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            if (bankAccounts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Text(
                    'No bank details provided',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...bankAccounts.map((account) {
                final bankName = account['bank_name'] ?? '';
                final accountNumberMasked = account['account_number_masked'] ?? '';
                final accountHolder = account['account_holder_name'] ?? '';
                final isPrimary = account['is_primary'] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.space12),
                  padding: EdgeInsets.all(isMobile ? AppTheme.space12 : AppTheme.space16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    color: isPrimary ? AppColors.accentBlue.withValues(alpha: 0.05) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            size: 20,
                            color: AppColors.accentBlue,
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Expanded(
                            child: Text(
                              bankName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isPrimary)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space8,
                                vertical: AppTheme.space4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                'Primary',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentBlue,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        'Account: $accountNumberMasked',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        'Holder: $accountHolder',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    final kycStatus = _submissionDetails!['user']['kyc_status'] ?? 'PENDING';

    // Only show buttons if status is PENDING or SUBMITTED
    if (kycStatus != 'PENDING' && kycStatus != 'SUBMITTED') {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _handleReject,
            icon: const Icon(Icons.cancel),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 12 : 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleApprove,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isSubmitting ? 'Processing...' : 'Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 12 : 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'SUBMITTED':
        return AppColors.warning;
      case 'PENDING':
      default:
        return AppColors.textSecondary;
    }
  }
}
