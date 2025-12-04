// TEMPORARILY DISABLED - qr_code_scanner package has build issues
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Placeholder QR Service - Scanner disabled for APK build
class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  // Generate QR code widget (Generation still works)
  Widget generateQRWidget({
    required String data,
    double size = 200,
    Color backgroundColor = Colors.white,
    Color foregroundColor = Colors.black,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
    );
  }
}

/*
ORIGINAL CODE - Temporarily disabled for APK build

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

Original imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

enum QRDataType {
  userId,
  orderId,
  transactionId,
  paymentRequest,
  agentInfo,
  verification,
  unknown,
}

class QRData {
  final QRDataType type;
  final String data;
  final Map<String, dynamic>? metadata;

  QRData({
    required this.type,
    required this.data,
    this.metadata,
  });

  factory QRData.fromString(String qrString) {
    try {
      // Try to parse as JSON
      final Map<String, dynamic> json = jsonDecode(qrString);

      final typeString = json['type'] as String?;
      final type = _parseType(typeString);

      return QRData(
        type: type,
        data: json['data'] as String? ?? qrString,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      // Not JSON, treat as plain string
      return QRData(
        type: QRDataType.unknown,
        data: qrString,
      );
    }
  }

  static QRDataType _parseType(String? typeString) {
    switch (typeString) {
      case 'user_id':
        return QRDataType.userId;
      case 'order_id':
        return QRDataType.orderId;
      case 'transaction_id':
        return QRDataType.transactionId;
      case 'payment_request':
        return QRDataType.paymentRequest;
      case 'agent_info':
        return QRDataType.agentInfo;
      case 'verification':
        return QRDataType.verification;
      default:
        return QRDataType.unknown;
    }
  }

  String toJsonString() {
    return jsonEncode({
      'type': type.name,
      'data': data,
      if (metadata != null) 'metadata': metadata,
    });
  }
}

class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  // Generate QR code widget

  Widget generateQRWidget({
    required String data,
    double size = 200,
    Color backgroundColor = Colors.white,
    Color foregroundColor = Colors.black,
    Widget? embeddedImage,
    int? embeddedImageSize,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foregroundColor,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor,
      ),
      embeddedImage: embeddedImage != null
          ? AssetImage(embeddedImage.toString())
          : null,
      embeddedImageStyle: embeddedImageSize != null
          ? QrEmbeddedImageStyle(size: Size(embeddedImageSize.toDouble(), embeddedImageSize.toDouble()))
          : null,
    );
  }

  // Generate QR for user identification

  Widget generateUserQR({
    required String userId,
    required String userName,
    String? phoneNumber,
    double size = 200,
  }) {
    final qrData = QRData(
      type: QRDataType.userId,
      data: userId,
      metadata: {
        'name': userName,
        'phone': phoneNumber,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    return generateQRWidget(
      data: qrData.toJsonString(),
      size: size,
    );
  }

  // Generate QR for payment request

  Widget generatePaymentRequestQR({
    required String orderId,
    required double amount,
    String? description,
    double size = 200,
  }) {
    final qrData = QRData(
      type: QRDataType.paymentRequest,
      data: orderId,
      metadata: {
        'amount': amount,
        'currency': 'SLL',
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    return generateQRWidget(
      data: qrData.toJsonString(),
      size: size,
    );
  }

  // Generate QR for verification code

  Widget generateVerificationQR({
    required String verificationCode,
    String? orderId,
    double size = 200,
  }) {
    final qrData = QRData(
      type: QRDataType.verification,
      data: verificationCode,
      metadata: {
        'order_id': orderId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    return generateQRWidget(
      data: qrData.toJsonString(),
      size: size,
    );
  }

  // Generate QR for agent information

  Widget generateAgentInfoQR({
    required String agentId,
    required String agentName,
    String? location,
    double size = 200,
  }) {
    final qrData = QRData(
      type: QRDataType.agentInfo,
      data: agentId,
      metadata: {
        'name': agentName,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    return generateQRWidget(
      data: qrData.toJsonString(),
      size: size,
    );
  }

  // Show QR code in a dialog

  Future<void> showQRDialog({
    required BuildContext context,
    required String title,
    required Widget qrWidget,
    String? subtitle,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: qrWidget,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Scanner widget

  Widget buildQRScanner({
    required QRViewController? controller,
    required Function(QRViewController) onQRViewCreated,
    GlobalKey? qrKey,
    bool showOverlay = true,
    String? overlayText,
  }) {
    return Stack(
      children: [
        QRView(
          key: qrKey ?? GlobalKey(debugLabel: 'QR'),
          onQRViewCreated: onQRViewCreated,
          overlay: showOverlay
              ? QrScannerOverlayShape(
                  borderColor: Colors.orange,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 250,
                )
              : null,
        ),
        if (overlayText != null)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                overlayText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // Parse scanned QR code

  QRData parseQRCode(String qrString) {
    return QRData.fromString(qrString);
  }

  // Handle scanned result

  Future<void> handleScannedQR({
    required BuildContext context,
    required String qrString,
    required Function(QRData) onSuccess,
    Function(String)? onError,
  }) async {
    try {
      final qrData = parseQRCode(qrString);

      // Vibrate on successful scan
      await HapticFeedback.mediumImpact();

      onSuccess(qrData);
    } catch (e) {
      debugPrint('Error handling scanned QR: $e');
      await HapticFeedback.heavyImpact();
      onError?.call('Invalid QR code');
    }
  }
}

// QR Scanner Screen (reusable)
class QRScannerScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Function(QRData) onScanned;
  final QRDataType? expectedType;

  const QRScannerScreen({
    super.key,
    this.title = 'Scan QR Code',
    this.subtitle,
    required this.onScanned,
    this.expectedType,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_isProcessing) return;

      _isProcessing = true;
      _handleScan(scanData.code ?? '');
    });
  }

  Future<void> _handleScan(String qrString) async {
    try {
      final qrData = QRService().parseQRCode(qrString);

      // Check if expected type matches
      if (widget.expectedType != null && qrData.type != widget.expectedType) {
        _showError('Invalid QR code type. Expected ${widget.expectedType?.name}');
        _isProcessing = false;
        return;
      }

      // Vibrate on success
      await HapticFeedback.mediumImpact();

      // Return result
      if (mounted) {
        Navigator.pop(context, qrData);
        widget.onScanned(qrData);
      }
    } catch (e) {
      _showError('Invalid QR code');
      _isProcessing = false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (widget.subtitle != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange[100],
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.subtitle!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: QRService().buildQRScanner(
              controller: controller,
              onQRViewCreated: _onQRViewCreated,
              qrKey: qrKey,
              overlayText: 'Position QR code within the frame',
            ),
          ),
        ],
      ),
    );
  }
}

*/ // End QR scanner code - temporarily disabled for APK build
