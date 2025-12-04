import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/app_colors.dart';
import '../../utils/responsive_helper.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  File? _nationalIdImage;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _nationalIdImage = File(image.path);
        });

        // In a real app, you would upload the image here
        // and get back a URL
        // For now, we'll simulate it
        await _simulateUpload();
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

  Future<void> _simulateUpload() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ID document uploaded successfully'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  void _showImageSourceDialog() {
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
                  'Choose Image Source',
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
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primaryOrange),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleContinue() {
    if (_nationalIdImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload your National ID'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Navigate to bank details screen (MANDATORY for agents)
    context.push('/bank-details');
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
                    'Please upload a clear photo of your national ID card for verification',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Upload Area
                  GestureDetector(
                    onTap: _isLoading ? null : _showImageSourceDialog,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _nationalIdImage != null
                              ? AppColors.successGreen
                              : AppColors.borderLight,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _nationalIdImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    _nationalIdImage!,
                                    fit: BoxFit.cover,
                                  ),
                                  if (_isLoading)
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                    )
                                  else
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
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap to upload ID',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Camera or Gallery',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  if (_nationalIdImage != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _showImageSourceDialog,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Change Image'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryOrange,
                        side: BorderSide(color: AppColors.primaryOrange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

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

                  // Continue Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Continue',
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
