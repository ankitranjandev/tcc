import 'api_service.dart';

class KYCService {
  final ApiService _apiService = ApiService();

  // Submit KYC documents
  Future<Map<String, dynamic>> submitKYC({
    required String documentType,
    required String documentNumber,
    required String frontImagePath,
    String? backImagePath,
    String? selfiePath,
  }) async {
    try {
      // Upload front image
      final frontImageResponse = await _apiService.uploadFile(
        '/uploads',
        frontImagePath,
        'file',
        additionalFields: {
          'file_type': 'KYC_DOCUMENT',
        },
        requiresAuth: true,
      );

      // Upload back image if provided
      String? backImageUrl;
      if (backImagePath != null) {
        final backImageResponse = await _apiService.uploadFile(
          '/uploads',
          backImagePath,
          'file',
          additionalFields: {
            'file_type': 'KYC_DOCUMENT',
          },
          requiresAuth: true,
        );
        backImageUrl = backImageResponse['data']['url'];
      }

      // Upload selfie if provided
      String? selfieUrl;
      if (selfiePath != null) {
        final selfieResponse = await _apiService.uploadFile(
          '/uploads',
          selfiePath,
          'file',
          additionalFields: {
            'file_type': 'SELFIE',
          },
          requiresAuth: true,
        );
        selfieUrl = selfieResponse['data']['url'];
      }

      // Submit KYC with document URLs
      final body = <String, dynamic>{
        'document_type': documentType,
        'document_number': documentNumber,
        'front_image_url': frontImageResponse['data']['url'],
      };
      if (backImageUrl != null) {
        body['back_image_url'] = backImageUrl;
      }
      if (selfieUrl != null) {
        body['selfie_url'] = selfieUrl;
      }

      final response = await _apiService.post(
        '/kyc/submit',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get KYC status
  Future<Map<String, dynamic>> getKYCStatus() async {
    try {
      final response = await _apiService.get(
        '/kyc/status',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Resubmit KYC (after rejection)
  Future<Map<String, dynamic>> resubmitKYC({
    required String documentType,
    required String documentNumber,
    required String frontImagePath,
    String? backImagePath,
    String? selfiePath,
  }) async {
    try {
      // Upload front image
      final frontImageResponse = await _apiService.uploadFile(
        '/uploads',
        frontImagePath,
        'file',
        additionalFields: {
          'file_type': 'KYC_DOCUMENT',
        },
        requiresAuth: true,
      );

      // Upload back image if provided
      String? backImageUrl;
      if (backImagePath != null) {
        final backImageResponse = await _apiService.uploadFile(
          '/uploads',
          backImagePath,
          'file',
          additionalFields: {
            'file_type': 'KYC_DOCUMENT',
          },
          requiresAuth: true,
        );
        backImageUrl = backImageResponse['data']['url'];
      }

      // Upload selfie if provided
      String? selfieUrl;
      if (selfiePath != null) {
        final selfieResponse = await _apiService.uploadFile(
          '/uploads',
          selfiePath,
          'file',
          additionalFields: {
            'file_type': 'SELFIE',
          },
          requiresAuth: true,
        );
        selfieUrl = selfieResponse['data']['url'];
      }

      // Resubmit KYC with document URLs
      final body = <String, dynamic>{
        'document_type': documentType,
        'document_number': documentNumber,
        'front_image_url': frontImageResponse['data']['url'],
      };
      if (backImageUrl != null) {
        body['back_image_url'] = backImageUrl;
      }
      if (selfieUrl != null) {
        body['selfie_url'] = selfieUrl;
      }

      final response = await _apiService.post(
        '/kyc/resubmit',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
