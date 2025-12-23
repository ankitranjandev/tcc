import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/kyc_service.dart';
import '../../utils/responsive_helper.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  final _kycService = KYCService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _documentNumberController = TextEditingController();

  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  bool _isSubmitting = false;

  String _selectedDocumentType = 'National ID';
  final List<String> _documentTypes = ['National ID', 'Passport', 'Driver\'s License'];

  final Map<String, String> _documentTypeMapping = {
    'National ID': 'NATIONAL_ID',
    'Passport': 'PASSPORT',
    'Driver\'s License': 'DRIVERS_LICENSE',
  };

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, String imageType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (imageType) {
            case 'front':
              _frontImage = File(image.path);
              break;
            case 'back':
              _backImage = File(image.path);
              break;
            case 'selfie':
              _selfieImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showImageSourceDialog(String imageType, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.primaryOrange),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, imageType);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primaryOrange),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, imageType);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    // Validation
    if (_frontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload front image of your document'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload a selfie'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_documentNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your document number'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _kycService.submitKYC(
        documentType: _documentTypeMapping[_selectedDocumentType]!,
        documentNumber: _documentNumberController.text.trim(),
        frontImagePath: _frontImage!.path,
        backImagePath: _backImage?.path,
        selfiePath: _selfieImage!.path,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('KYC documents submitted successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );

        // Navigate to bank details screen (MANDATORY for agents)
        context.push('/bank-details');
      } else {
        throw Exception(result['error'] ?? 'Failed to submit KYC');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit KYC: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'KYC Verification',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 24 : 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Indicator
                  Row(
                    children: [
                      _buildProgressStep(1, 'OTP', true),
                      _buildProgressLine(true),
                      _buildProgressStep(2, 'KYC', true),
                      _buildProgressLine(false),
                      _buildProgressStep(3, 'Bank', false),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // User Info Card
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final agent = authProvider.agent;
                      final userName = agent != null
                          ? '${agent.firstName} ${agent.lastName}'
                          : 'User';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryOrange.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.person,
                                color: AppColors.primaryOrange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verifying Identity',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.badge_outlined,
                      size: 40,
                      color: AppColors.primaryOrange,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Header
                  Text(
                    'Upload National ID',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Please provide your identification documents and a selfie for verification',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Document Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDocumentType,
                    decoration: InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                    ),
                    items: _documentTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedDocumentType = newValue;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Document Number Field
                  TextFormField(
                    controller: _documentNumberController,
                    decoration: InputDecoration(
                      labelText: 'Document Number',
                      hintText: 'Enter your document number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Upload Areas
                  _buildUploadSection(
                    'Front Image',
                    'Upload front of your document',
                    _frontImage,
                    'front',
                    required: true,
                  ),

                  const SizedBox(height: 20),

                  _buildUploadSection(
                    'Back Image',
                    'Upload back of your document (if applicable)',
                    _backImage,
                    'back',
                    required: false,
                  ),

                  const SizedBox(height: 20),

                  _buildUploadSection(
                    'Selfie',
                    'Upload a selfie holding your document',
                    _selfieImage,
                    'selfie',
                    required: true,
                  ),

                  const SizedBox(height: 32),

                  // Requirements
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.infoBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.infoBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Requirements',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRequirementItem('Clear and readable image'),
                        _buildRequirementItem('All corners visible'),
                        _buildRequirementItem('No glare or shadows'),
                        _buildRequirementItem('Valid government-issued ID'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit KYC',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection(
    String title,
    String subtitle,
    File? image,
    String imageType, {
    required bool required,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isSubmitting ? null : () => _showImageSourceDialog(imageType, 'Choose Image Source'),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: image != null
                    ? AppColors.successGreen
                    : AppColors.borderLight,
                width: 2,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          image,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: AppColors.successGreen,
                            radius: 16,
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryOrange : AppColors.backgroundLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primaryOrange : AppColors.borderLight,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primaryOrange : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.primaryOrange : AppColors.borderLight,
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.successGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
