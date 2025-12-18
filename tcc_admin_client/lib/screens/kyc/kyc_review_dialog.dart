import 'package:flutter/material.dart';
import '../../models/agent_model.dart';
import '../../services/kyc_service.dart' as service;
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

class KYCReviewDialog extends StatefulWidget {
  final AgentModel agent;
  final Function() onStatusChanged;

  const KYCReviewDialog({
    super.key,
    required this.agent,
    required this.onStatusChanged,
  });

  @override
  State<KYCReviewDialog> createState() => _KYCReviewDialogState();
}

class _KYCReviewDialogState extends State<KYCReviewDialog> {
  final service.KycService _kycService = service.KycService();
  bool _isLoading = false;
  String? _selectedRejectionReason;
  final TextEditingController _customReasonController = TextEditingController();

  // Predefined rejection reasons
  final List<String> _rejectionReasons = [
    'Document unclear/blurry',
    'Document expired',
    'Name mismatch',
    'Invalid document type',
    'Missing information',
    'Document appears to be tampered',
    'Face not clearly visible in selfie',
    'Other',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    setState(() => _isLoading = true);

    try {
      final response = await _kycService.reviewKycSubmission(
        submissionId: widget.agent.id,
        action: 'approve',
      );

      if (response.success) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC approved successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        widget.onStatusChanged();
      } else {
        throw Exception(response.message ?? 'Failed to approve KYC');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReject() async {
    final rejectionReason = _selectedRejectionReason == 'Other'
        ? _customReasonController.text
        : _selectedRejectionReason;

    if (rejectionReason == null || rejectionReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a rejection reason'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _kycService.reviewKycSubmission(
        submissionId: widget.agent.id,
        action: 'reject',
        remarks: rejectionReason,
      );

      if (response.success) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC rejected'),
            backgroundColor: AppColors.warningOrange,
          ),
        );
        widget.onStatusChanged();
      } else {
        throw Exception(response.message ?? 'Failed to reject KYC');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFullImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 600, maxWidth: 800),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.background,
                      child: const Center(
                        child: Icon(Icons.error, color: AppColors.errorRed, size: 50),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.background,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KYC Review',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Review and verify agent KYC documents',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agent Information
                    _buildSectionTitle('Agent Information'),
                    _buildInfoCard([
                      _buildInfoRow('Name', '${widget.agent.firstName} ${widget.agent.lastName}'),
                      _buildInfoRow('Email', widget.agent.email),
                      _buildInfoRow('Phone', widget.agent.mobileNumber),
                      _buildInfoRow('Business', widget.agent.businessName),
                      _buildInfoRow('Registration Number', widget.agent.registrationNumber),
                      _buildInfoRow('Submitted Date', _formatDate(widget.agent.createdAt)),
                    ]),

                    const SizedBox(height: 24),

                    // KYC Documents
                    _buildSectionTitle('KYC Documents'),
                    _buildDocumentSection(),

                    const SizedBox(height: 24),

                    // Bank Details
                    _buildSectionTitle('Bank Details'),
                    _buildBankDetailsCard(),

                    const SizedBox(height: 24),

                    // Rejection Reason (if rejecting)
                    _buildRejectionReasonSection(),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleReject,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel, size: 18),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleApprove,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.h4.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection() {
    final nationalIdUrl = widget.agent.nationalIdUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'National ID',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (nationalIdUrl != null && nationalIdUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _showFullImage(nationalIdUrl),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    nationalIdUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.background,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: AppColors.errorRed, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          else
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Center(
                child: Text(
                  'No document uploaded',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Click on image to view full size',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsCard() {
    final bankDetails = widget.agent.bankDetails;

    if (bankDetails == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            'No bank details submitted',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return _buildInfoCard([
      _buildInfoRow('Bank Name', bankDetails['bank_name'] ?? 'N/A'),
      _buildInfoRow('Branch Address', bankDetails['branch_address'] ?? 'N/A'),
      _buildInfoRow('IFSC Code', bankDetails['ifsc_code'] ?? 'N/A'),
      _buildInfoRow('Account Holder', bankDetails['account_holder_name'] ?? 'N/A'),
      _buildInfoRow('Account Type', bankDetails['account_type'] ?? 'SAVINGS'),
      if (bankDetails['is_verified'] != null)
        _buildInfoRow(
          'Verification Status',
          bankDetails['is_verified'] == true ? 'Verified' : 'Not Verified',
        ),
    ]);
  }

  Widget _buildRejectionReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rejection Reason (Optional)'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a reason if rejecting:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedRejectionReason,
                decoration: InputDecoration(
                  hintText: 'Choose a reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _rejectionReasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRejectionReason = value;
                  });
                },
              ),
              if (_selectedRejectionReason == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customReasonController,
                  decoration: InputDecoration(
                    hintText: 'Enter custom reason',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}