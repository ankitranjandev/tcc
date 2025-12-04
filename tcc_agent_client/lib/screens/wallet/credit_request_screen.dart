import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../utils/responsive_helper.dart';

class CreditRequestScreen extends StatefulWidget {
  const CreditRequestScreen({super.key});

  @override
  State<CreditRequestScreen> createState() => _CreditRequestScreenState();
}

class _CreditRequestScreenState extends State<CreditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _receiptImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _captureReceipt() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture image: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
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
                  'Add Receipt Image',
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
                    _captureReceipt();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primaryOrange),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
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
    if (!_formKey.currentState!.validate()) return;

    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload deposit receipt'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Credit request submitted successfully'),
        backgroundColor: AppColors.successGreen,
      ),
    );

    // Wait a bit for user to see the success message before popping
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Wallet Credit'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
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
                            'How it Works',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Deposit cash at any TCC office\n'
                        '2. Get a deposit receipt\n'
                        '3. Upload receipt and request amount\n'
                        '4. Admin will verify and credit your wallet',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Amount Input
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount (SLL)',
                    hintText: 'Enter deposit amount',
                    prefixIcon: Icon(Icons.money, color: AppColors.primaryOrange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryOrange, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter valid amount';
                    }
                    if (amount < 100000) {
                      return 'Minimum amount is SLL 100,000';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any additional information',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.note, color: AppColors.primaryOrange),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryOrange, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Receipt Upload Section
                Text(
                  'Upload Deposit Receipt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                if (_receiptImage != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _receiptImage!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: AppColors.errorRed,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.white,
                            onPressed: () {
                              setState(() => _receiptImage = null);
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
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
                              Icons.cloud_upload_outlined,
                              size: 64,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to Upload Receipt',
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
                  ),

                if (_receiptImage != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Change Receipt'),
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

                // Warning Notice
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
                        Icons.warning_amber_rounded,
                        color: AppColors.warningOrange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Credit requests are processed within 24-48 hours',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Request',
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
    );
  }
}
