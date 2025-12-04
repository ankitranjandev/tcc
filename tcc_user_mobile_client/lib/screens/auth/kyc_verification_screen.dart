import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

class KYCVerificationScreen extends StatefulWidget {
  final Map<String, dynamic>? extraData;

  const KYCVerificationScreen({super.key, this.extraData});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _securityNumberController = TextEditingController();
  String _selectedDocumentType = 'National ID';
  bool _documentUploaded = false;
  bool _photoUploaded = false;

  final List<String> _documentTypes = [
    'National ID',
    'Passport',
    'Driver\'s License',
    'Voter Card',
  ];

  @override
  void dispose() {
    _securityNumberController.dispose();
    super.dispose();
  }

  void _handleUploadDocument() {
    setState(() {
      _documentUploaded = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document uploaded successfully (Mock)'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleUploadPhoto() {
    setState(() {
      _photoUploaded = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo uploaded successfully (Mock)'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSkip() {
    context.go('/bank-details', extra: widget.extraData);
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      if (!_documentUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please upload your document'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (!_photoUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please upload your photo'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Navigate to bank details
      context.go('/bank-details', extra: widget.extraData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _handleSkip,
            child: Text(
              'Skip Onboarding',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Illustration
                Center(
                  child: SizedBox(
                    height: 150,
                    child: Icon(
                      Icons.verified_outlined,
                      size: 100,
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'KYC Verification',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please upload your document',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                ),
                SizedBox(height: 32),
                // Document Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedDocumentType,
                  decoration: InputDecoration(
                    hintText: 'Document Type',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  items: _documentTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDocumentType = value!;
                    });
                  },
                ),
                SizedBox(height: 24),
                // Document Upload Card
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedDocumentType,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'John Doe',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              child: Center(
                                child: Icon(
                                  _documentUploaded ? Icons.check_circle : Icons.image_outlined,
                                  color: _documentUploaded ? AppColors.success : Theme.of(context).disabledColor,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person_outline,
                                  color: Theme.of(context).disabledColor,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _handleUploadDocument,
                        icon: Icon(Icons.upload_file),
                        label: Text('Upload Doc'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Security Number
                TextFormField(
                  controller: _securityNumberController,
                  decoration: InputDecoration(
                    hintText: 'National Security Number',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your security number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                // Take Photo Section
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardColor,
                        border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                      ),
                      child: Icon(
                        _photoUploaded ? Icons.check_circle : Icons.person,
                        size: 40,
                        color: _photoUploaded ? AppColors.success : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Take a photo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _handleUploadPhoto,
                            icon: Icon(Icons.camera_alt),
                            label: Text('Upload Picture'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Upload Document',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
