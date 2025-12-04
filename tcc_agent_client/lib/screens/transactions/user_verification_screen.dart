import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../utils/responsive_helper.dart';

class UserVerificationScreen extends StatefulWidget {
  const UserVerificationScreen({super.key});

  @override
  State<UserVerificationScreen> createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  File? _userPhoto;
  File? _userIdPhoto;

  Future<void> _capturePhoto(bool isUserPhoto) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        setState(() {
          if (isUserPhoto) {
            _userPhoto = File(image.path);
          } else {
            _userIdPhoto = File(image.path);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _handleContinue() {
    if (_userPhoto == null || _userIdPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please capture both user photo and ID photo'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Navigate to currency counter screen
    context.push('/currency-counter');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify User Identity'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warningOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: AppColors.warningOrange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verify user identity by capturing their photo and ID document',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // User Photo Section
              Text(
                'Step 1: Capture User Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              _buildPhotoCapture(
                title: 'User Face Photo',
                subtitle: 'Take a clear photo of the user\'s face',
                image: _userPhoto,
                icon: Icons.person,
                onCapture: () => _capturePhoto(true),
              ),

              const SizedBox(height: 32),

              // ID Photo Section
              Text(
                'Step 2: Capture ID Document',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              _buildPhotoCapture(
                title: 'National ID Photo',
                subtitle: 'Take a photo of user\'s national ID',
                image: _userIdPhoto,
                icon: Icons.badge_outlined,
                onCapture: () => _capturePhoto(false),
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
                          'Photo Requirements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem('Clear and well-lit photos'),
                    _buildRequirementItem('Face and ID must be fully visible'),
                    _buildRequirementItem('No glare or shadows on ID'),
                    _buildRequirementItem('Photos are for verification only'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Continue Button
              ElevatedButton.icon(
                onPressed: _handleContinue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  'Continue to Amount Entry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCapture({
    required String title,
    required String subtitle,
    required File? image,
    required IconData icon,
    required VoidCallback onCapture,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onCapture,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (image != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        image,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: AppColors.successGreen,
                        radius: 20,
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 64,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (image != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Retake Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                    side: BorderSide(color: AppColors.primaryOrange),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
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
