import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

/// Dialog for viewing KYC documents (images)
class DocumentViewerDialog extends StatefulWidget {
  final String documentUrl;
  final String documentType;
  final String? documentNumber;

  const DocumentViewerDialog({
    super.key,
    required this.documentUrl,
    required this.documentType,
    this.documentNumber,
  });

  /// Show the document viewer dialog
  static Future<void> show(
    BuildContext context, {
    required String documentUrl,
    required String documentType,
    String? documentNumber,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DocumentViewerDialog(
        documentUrl: documentUrl,
        documentType: documentType,
        documentNumber: documentNumber,
      ),
    );
  }

  @override
  State<DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<DocumentViewerDialog> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isLoading = true;
  bool _hasError = false;
  double _rotation = 0;

  String get _fullUrl {
    // If the URL is already absolute, use it as-is
    if (widget.documentUrl.startsWith('http://') ||
        widget.documentUrl.startsWith('https://')) {
      return widget.documentUrl;
    }
    // Otherwise, prepend the base URL (without /v1)
    final baseUrl = ApiService.baseUrl.replaceAll('/v1', '');
    return '$baseUrl${widget.documentUrl}';
  }

  String get _formattedDocumentType {
    return widget.documentType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _rotateImage() {
    setState(() {
      _rotation += 90;
      if (_rotation >= 360) {
        _rotation = 0;
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLarge),
                  topRight: Radius.circular(AppTheme.radiusLarge),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getDocumentIcon(widget.documentType),
                    color: AppColors.accentBlue,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formattedDocumentType,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.documentNumber != null &&
                            widget.documentNumber!.isNotEmpty)
                          Text(
                            'Document #: ${widget.documentNumber}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Toolbar buttons
                  IconButton(
                    onPressed: _rotateImage,
                    icon: const Icon(Icons.rotate_right),
                    tooltip: 'Rotate',
                    color: AppColors.textSecondary,
                  ),
                  IconButton(
                    onPressed: _resetZoom,
                    icon: const Icon(Icons.fit_screen),
                    tooltip: 'Reset zoom',
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            // Image viewer
            Expanded(
              child: Container(
                color: Colors.grey[900],
                child: Stack(
                  children: [
                    // Image with zoom and pan
                    Center(
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Transform.rotate(
                          angle: _rotation * 3.14159 / 180,
                          child: Image.network(
                            _fullUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted && _isLoading) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                });
                                return child;
                              }
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: AppColors.accentBlue,
                                    ),
                                    const SizedBox(height: AppTheme.space16),
                                    Text(
                                      'Loading document...',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_hasError) {
                                  setState(() {
                                    _hasError = true;
                                    _isLoading = false;
                                  });
                                }
                              });
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      size: 64,
                                      color: Colors.white54,
                                    ),
                                    const SizedBox(height: AppTheme.space16),
                                    Text(
                                      'Failed to load document',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.space8),
                                    Text(
                                      'The document could not be loaded.\nPlease try again later.',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppTheme.space16),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _hasError = false;
                                          _isLoading = true;
                                        });
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    // Zoom hint
                    if (!_isLoading && !_hasError)
                      Positioned(
                        bottom: AppTheme.space16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space12,
                              vertical: AppTheme.space8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Text(
                              'Pinch or scroll to zoom • Drag to pan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
}
