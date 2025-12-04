import 'api_service.dart';

class KYCService {
  final ApiService _apiService = ApiService();

  // Submit KYC documents
  Future<Map<String, dynamic>> submitKYC({
    required String idType,
    required String idNumber,
    required String idImagePath,
    required String selfieImagePath,
    String? proofOfAddressPath,
  }) async {
    try {
      // First upload ID image
      final idImageResponse = await _apiService.uploadFile(
        '/kyc/upload-document',
        idImagePath,
        'document',
        additionalFields: {
          'documentType': 'id_document',
        },
        requiresAuth: true,
      );

      // Upload selfie image
      final selfieResponse = await _apiService.uploadFile(
        '/kyc/upload-document',
        selfieImagePath,
        'document',
        additionalFields: {
          'documentType': 'selfie',
        },
        requiresAuth: true,
      );

      // Upload proof of address if provided
      String? proofOfAddressUrl;
      if (proofOfAddressPath != null) {
        final proofResponse = await _apiService.uploadFile(
          '/kyc/upload-document',
          proofOfAddressPath,
          'document',
          additionalFields: {
            'documentType': 'proof_of_address',
          },
          requiresAuth: true,
        );
        proofOfAddressUrl = proofResponse['url'];
      }

      // Submit KYC with document URLs
      final body = <String, dynamic>{
        'idType': idType,
        'idNumber': idNumber,
        'idImageUrl': idImageResponse['url'],
        'selfieImageUrl': selfieResponse['url'],
      };
      if (proofOfAddressUrl != null) {
        body['proofOfAddressUrl'] = proofOfAddressUrl;
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
    required String idType,
    required String idNumber,
    required String idImagePath,
    required String selfieImagePath,
    String? proofOfAddressPath,
  }) async {
    try {
      // First upload ID image
      final idImageResponse = await _apiService.uploadFile(
        '/kyc/upload-document',
        idImagePath,
        'document',
        additionalFields: {
          'documentType': 'id_document',
        },
        requiresAuth: true,
      );

      // Upload selfie image
      final selfieResponse = await _apiService.uploadFile(
        '/kyc/upload-document',
        selfieImagePath,
        'document',
        additionalFields: {
          'documentType': 'selfie',
        },
        requiresAuth: true,
      );

      // Upload proof of address if provided
      String? proofOfAddressUrl;
      if (proofOfAddressPath != null) {
        final proofResponse = await _apiService.uploadFile(
          '/kyc/upload-document',
          proofOfAddressPath,
          'document',
          additionalFields: {
            'documentType': 'proof_of_address',
          },
          requiresAuth: true,
        );
        proofOfAddressUrl = proofResponse['url'];
      }

      // Resubmit KYC with document URLs
      final body = <String, dynamic>{
        'idType': idType,
        'idNumber': idNumber,
        'idImageUrl': idImageResponse['url'],
        'selfieImageUrl': selfieResponse['url'],
      };
      if (proofOfAddressUrl != null) {
        body['proofOfAddressUrl'] = proofOfAddressUrl;
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
