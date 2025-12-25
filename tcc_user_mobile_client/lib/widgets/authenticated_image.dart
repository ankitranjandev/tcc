import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

/// A widget that loads and displays images that require authentication.
/// This fetches the image with the Authorization header and displays it.
class AuthenticatedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AuthenticatedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _stackTrace = null;
    });

    try {
      developer.log('🖼️ AuthenticatedImage: Loading image from ${widget.imageUrl}', name: 'AuthenticatedImage');

      final apiService = ApiService();
      final token = apiService.token;

      final headers = <String, String>{
        'Accept': 'image/*',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        developer.log('🖼️ AuthenticatedImage: Added auth header', name: 'AuthenticatedImage');
      } else {
        developer.log('🖼️ AuthenticatedImage: No auth token available', name: 'AuthenticatedImage');
      }

      final response = await http.get(
        Uri.parse(widget.imageUrl),
        headers: headers,
      );

      developer.log('🖼️ AuthenticatedImage: Response status: ${response.statusCode}', name: 'AuthenticatedImage');

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
          });
          developer.log('🖼️ AuthenticatedImage: Image loaded successfully (${response.bodyBytes.length} bytes)', name: 'AuthenticatedImage');
        }
      } else {
        throw Exception('Failed to load image: HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log('🖼️ AuthenticatedImage: Error loading image: $e', name: 'AuthenticatedImage');
      if (mounted) {
        setState(() {
          _error = e;
          _stackTrace = stackTrace;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      if (widget.loadingBuilder != null) {
        return widget.loadingBuilder!(context, const SizedBox(), null);
      }
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!, _stackTrace);
      }
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    }

    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
    );
  }
}
