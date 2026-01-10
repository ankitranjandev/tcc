import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/authenticated_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneWithCountryCode ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    // Debug logging for profile picture
    developer.log('🖼️ ProfileScreen: Building with user: ${user?.email}', name: 'ProfileScreen');
    developer.log('🖼️ ProfileScreen: Raw profilePicture value: ${user?.profilePicture}', name: 'ProfileScreen');
    if (user?.profilePicture != null) {
      final fixedUrl = _getFixedImageUrl(user!.profilePicture!);
      developer.log('🖼️ ProfileScreen: Fixed image URL: $fixedUrl', name: 'ProfileScreen');
    } else {
      developer.log('🖼️ ProfileScreen: profilePicture is NULL - showing default icon', name: 'ProfileScreen');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 24),

            // Profile Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: user?.profilePicture != null
                        ? ClipOval(
                            child: AuthenticatedImage(
                              key: ValueKey(user!.profilePicture!),
                              imageUrl: _getFixedImageUrl(user.profilePicture!),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                developer.log('🖼️ ProfileScreen: AuthenticatedImage error: $error', name: 'ProfileScreen');
                                return Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primaryBlue,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.primaryBlue,
                          ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Name
            if (!_isEditing) ...[
              Text(
                user?.fullName ?? 'User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],

            SizedBox(height: 24),

            // KYC Verification Banner
            if (user?.kycStatus != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getKycStatusColor(user!.kycStatus).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getKycStatusColor(user.kycStatus).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getKycStatusColor(user.kycStatus),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getKycStatusIcon(user.kycStatus),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KYC Verification',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _getKycStatusText(user.kycStatus),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getKycStatusColor(user.kycStatus),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (user.kycStatus.toUpperCase() == 'APPROVED' ||
                          user.kycStatus.toUpperCase() == 'VERIFIED')
                        Icon(
                          Icons.verified,
                          color: _getKycStatusColor(user.kycStatus),
                          size: 28,
                        ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 32),

            // Profile Information
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // First Name
                  _buildInfoField(
                    label: 'First Name',
                    controller: _firstNameController,
                    icon: Icons.person_outline,
                    enabled: false,
                  ),
                  SizedBox(height: 16),

                  // Last Name
                  _buildInfoField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    icon: Icons.person_outline,
                    enabled: false,
                  ),
                  SizedBox(height: 16),

                  // Email
                  _buildInfoField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    enabled: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),

                  // Phone
                  _buildInfoField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    enabled: false,
                    keyboardType: TextInputType.phone,
                  ),

                  SizedBox(height: 32),

                  // Action Buttons
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Reset controllers
                              setState(() {
                                _firstNameController.text = user?.firstName ?? '';
                                _lastNameController.text = user?.lastName ?? '';
                                _emailController.text = user?.email ?? '';
                                _phoneController.text = user?.phoneWithCountryCode ?? '';
                                _isEditing = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.primaryBlue),
                            ),
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primaryBlue,
                            ),
                            child: Text(
                              'Save Changes',
                              style: TextStyle(color: AppColors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: !enabled,
            fillColor: enabled ? null : Theme.of(context).disabledColor.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }

  void _saveProfile() {
    // TODO: Implement actual profile update API call
    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show dialog to choose image source
  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Pick and upload profile picture
  Future<void> _pickAndUploadImage(ImageSource source) async {
    developer.log('📸 ProfileScreen: Starting image pick from ${source == ImageSource.camera ? "camera" : "gallery"}', name: 'ProfileScreen');
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        developer.log('📸 ProfileScreen: Image picking cancelled by user', name: 'ProfileScreen');
        return;
      }

      developer.log('📸 ProfileScreen: Image picked successfully', name: 'ProfileScreen');
      developer.log('📸 ProfileScreen: Image path: ${image.path}', name: 'ProfileScreen');
      developer.log('📸 ProfileScreen: Image name: ${image.name}', name: 'ProfileScreen');

      if (!mounted) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading profile picture...'),
                ],
              ),
            ),
          ),
        ),
      );

      developer.log('📸 ProfileScreen: Calling authProvider.updateProfilePicture...', name: 'ProfileScreen');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateProfilePicture(image.path);
      developer.log('📸 ProfileScreen: updateProfilePicture returned: $success', name: 'ProfileScreen');

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Log the updated user data
        final updatedUser = authProvider.user;
        developer.log('📸 ProfileScreen: SUCCESS! Updated user profilePicture: ${updatedUser?.profilePicture}', name: 'ProfileScreen');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        developer.log('📸 ProfileScreen: FAILED! Error: ${authProvider.errorMessage}', name: 'ProfileScreen');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to update profile picture'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log('📸 ProfileScreen: EXCEPTION during image upload: $e', name: 'ProfileScreen');
      developer.log('📸 ProfileScreen: Stack trace: $stackTrace', name: 'ProfileScreen');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Fix image URL to use CloudFront endpoint
  String _getFixedImageUrl(String url) {
    developer.log('🔗 ProfileScreen._getFixedImageUrl: Input URL: $url', name: 'ProfileScreen');
    final fixedUrl = AppConstants.getImageUrl(url);
    developer.log('🔗 ProfileScreen._getFixedImageUrl: Fixed URL: $fixedUrl', name: 'ProfileScreen');
    return fixedUrl;
  }

  Color _getKycStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'VERIFIED':
        return AppColors.success;
      case 'PENDING':
      case 'PROCESSING':
      case 'IN_PROGRESS':
      case 'SUBMITTED':
        return AppColors.warning;
      case 'REJECTED':
      case 'FAILED':
        return AppColors.error;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _getKycStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'VERIFIED':
        return Icons.verified;
      case 'PENDING':
      case 'PROCESSING':
      case 'IN_PROGRESS':
      case 'SUBMITTED':
        return Icons.pending;
      case 'REJECTED':
      case 'FAILED':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  String _getKycStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'VERIFIED':
        return 'Verified';
      case 'PENDING':
      case 'PROCESSING':
      case 'IN_PROGRESS':
      case 'SUBMITTED':
        return 'In Progress';
      case 'REJECTED':
      case 'FAILED':
        return 'Rejected';
      default:
        return 'Not Verified';
    }
  }
}
