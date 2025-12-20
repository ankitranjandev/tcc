import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../services/kyc_service.dart';

class KYCStatusScreen extends StatefulWidget {
  final Map<String, dynamic>? extraData;

  const KYCStatusScreen({super.key, this.extraData});

  @override
  State<KYCStatusScreen> createState() => _KYCStatusScreenState();
}

class _KYCStatusScreenState extends State<KYCStatusScreen> {
  final _kycService = KYCService();
  bool _isLoading = true;
  String _kycStatus = 'PENDING';
  List<dynamic> _documents = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKYCStatus();
  }

  Future<void> _loadKYCStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _kycService.getKYCStatus();

      if (mounted) {
        if (result['success'] == true) {
          final data = result['data']['data'];
          setState(() {
            _kycStatus = data['kyc_status'] ?? 'PENDING';
            _documents = data['documents'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['error'] ?? 'Failed to load KYC status';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _handleRefresh() {
    _loadKYCStatus();
  }

  void _handleGoToDashboard() {
    context.go('/dashboard');
  }

  void _handleResubmit() {
    // Pass flag to indicate this is a resubmission
    final resubmitData = {
      ...?widget.extraData,
      'isResubmission': true,
    };
    context.go('/kyc-verification', extra: resubmitData);
  }

  Widget _buildPendingStatus() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.hourglass_empty,
          size: 100,
          color: AppColors.warning,
        ),
        SizedBox(height: 32),
        Text(
          'Documents Under Review',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Your KYC documents are being reviewed by our team. This usually takes 24-48 hours. We\'ll notify you once the review is complete.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: _handleRefresh,
          icon: Icon(Icons.refresh),
          label: Text('Refresh Status'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedStatus() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.1),
          ),
          child: Icon(
            Icons.check_circle,
            size: 80,
            color: AppColors.success,
          ),
        ),
        SizedBox(height: 32),
        Text(
          'KYC Approved!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Congratulations! Your KYC verification has been approved. You now have full access to all features.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 48),
        ElevatedButton(
          onPressed: _handleGoToDashboard,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            backgroundColor: AppColors.success,
          ),
          child: Text(
            'Go to Dashboard',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedStatus() {
    // Get rejection reasons from documents
    final rejectedDocs = _documents.where((doc) =>
      doc['status'] == 'REJECTED' && doc['rejection_reason'] != null
    ).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: 0.1),
          ),
          child: Icon(
            Icons.cancel,
            size: 80,
            color: AppColors.error,
          ),
        ),
        SizedBox(height: 32),
        Text(
          'KYC Rejected',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Your KYC documents were rejected. Please review the reasons below and resubmit with corrections.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 32),
        // Rejection Reasons
        if (rejectedDocs.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejection Reasons:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...rejectedDocs.map((doc) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc['document_type'] ?? 'Document',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                doc['rejection_reason'] ?? 'No reason provided',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _handleResubmit,
          icon: Icon(Icons.upload),
          label: Text('Re-upload Documents'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KYC Status'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading KYC status...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error Loading Status',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _handleRefresh,
                            icon: Icon(Icons.refresh),
                            label: Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 150,
                      child: _kycStatus == 'APPROVED'
                          ? _buildApprovedStatus()
                          : _kycStatus == 'REJECTED'
                              ? _buildRejectedStatus()
                              : _buildPendingStatus(),
                    ),
                  ),
      ),
    );
  }
}
