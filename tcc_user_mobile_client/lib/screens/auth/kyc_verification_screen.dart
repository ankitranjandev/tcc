import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/kyc_service.dart';

class KYCVerificationScreen extends StatefulWidget {
  final Map<String, dynamic>? extraData;

  const KYCVerificationScreen({super.key, this.extraData});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _securityNumberController = TextEditingController();
  final _kycService = KYCService();
  final _imagePicker = ImagePicker();

  String _selectedDocumentType = 'NATIONAL_ID';
  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  bool _isSubmitting = false;

  final Map<String, String> _documentTypeMapping = {
    'National ID': 'NATIONAL_ID',
    'Passport': 'PASSPORT',
    'Driver\'s License': 'DRIVERS_LICENSE',
    'Voter Card': 'VOTER_CARD',
  };

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

  Future<void> _pickImage(ImageSource source, String imageType) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (imageType == 'front') {
            _frontImage = File(pickedFile.path);
          } else if (imageType == 'back') {
            _backImage = File(pickedFile.path);
          } else if (imageType == 'selfie') {
            _selfieImage = File(pickedFile.path);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$imageType image captured successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(String imageType) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, imageType);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, imageType);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_frontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload the front of your document'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please take a selfie'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _kycService.submitKYC(
        documentType: _documentTypeMapping[_selectedDocumentType]!,
        documentNumber: _securityNumberController.text,
        frontImagePath: _frontImage!.path,
        backImagePath: _backImage?.path,
        selfiePath: _selfieImage!.path,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KYC submitted successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to bank details screen
        context.go('/bank-details', extra: widget.extraData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to submit KYC'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.fullName ?? 'User';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('KYC Verification'),
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
                  initialValue: _documentTypes.first,
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
                  onChanged: _isSubmitting ? null : (value) {
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
                        userName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                        ),
                      ),
                      SizedBox(height: 16),
                      // Front and Back Image Previews
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isSubmitting ? null : () => _showImageSourceDialog('front'),
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _frontImage != null ? AppColors.success : Theme.of(context).dividerColor,
                                    width: 2,
                                  ),
                                ),
                                child: _frontImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.file(
                                          _frontImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_outlined,
                                              color: Theme.of(context).disabledColor,
                                              size: 32,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Front',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).textTheme.bodySmall?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isSubmitting ? null : () => _showImageSourceDialog('back'),
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _backImage != null ? AppColors.success : Theme.of(context).dividerColor,
                                    width: 2,
                                  ),
                                ),
                                child: _backImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.file(
                                          _backImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_outlined,
                                              color: Theme.of(context).disabledColor,
                                              size: 32,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Back (Optional)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).textTheme.bodySmall?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Security Number
                TextFormField(
                  controller: _securityNumberController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Document Number',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your document number';
                    }
                    if (value.length < 3) {
                      return 'Document number must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                // Take Selfie Section
                Row(
                  children: [
                    GestureDetector(
                      onTap: _isSubmitting ? null : () => _showImageSourceDialog('selfie'),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).cardColor,
                          border: Border.all(
                            color: _selfieImage != null ? AppColors.success : Theme.of(context).dividerColor,
                            width: 2,
                          ),
                        ),
                        child: _selfieImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selfieImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 40,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Take a selfie',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : () => _showImageSourceDialog('selfie'),
                            icon: Icon(Icons.camera_alt),
                            label: Text(_selfieImage != null ? 'Retake Picture' : 'Take Picture'),
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
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Submit KYC',
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
