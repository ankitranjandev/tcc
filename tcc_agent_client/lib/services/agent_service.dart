import 'api_service.dart';

class AgentService {
  final ApiService _apiService = ApiService();

  // Get Agent Profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get(
        '/agent/profile',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Register as Agent
  Future<Map<String, dynamic>> registerAgent({
    double? locationLat,
    double? locationLng,
    String? locationAddress,
  }) async {
    try {
      final response = await _apiService.post(
        '/agent/register',
        body: {
          if (locationLat != null) 'location_lat': locationLat,
          if (locationLng != null) 'location_lng': locationLng,
          if (locationAddress != null) 'location_address': locationAddress,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Request Credit
  Future<Map<String, dynamic>> requestCredit({
    required String agentId,
    required double amount,
    required String receiptUrl,
    required String depositDate,
    required String depositTime,
    String? bankName,
  }) async {
    try {
      final response = await _apiService.post(
        '/agent/credit/request',
        body: {
          'agent_id': agentId,
          'amount': amount,
          'receipt_url': receiptUrl,
          'deposit_date': depositDate,
          'deposit_time': depositTime,
          if (bankName != null) 'bank_name': bankName,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get Credit Requests History
  Future<Map<String, dynamic>> getCreditRequests({
    required String agentId,
    String? status,
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'agent_id': agentId,
        if (status != null) 'status': status,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (page != null) 'page': page.toString(),
        if (limit != null) 'limit': limit.toString(),
      };

      final response = await _apiService.get(
        '/agent/credit/requests',
        queryParams: queryParams,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Deposit for User
  Future<Map<String, dynamic>> depositForUser({
    required String agentId,
    required String userPhone,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiService.post(
        '/agent/deposit',
        body: {
          'agent_id': agentId,
          'user_phone': userPhone,
          'amount': amount,
          'payment_method': paymentMethod,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Withdraw for User
  Future<Map<String, dynamic>> withdrawForUser({
    required String agentId,
    required String userPhone,
    required double amount,
  }) async {
    try {
      final response = await _apiService.post(
        '/agent/withdraw',
        body: {
          'agent_id': agentId,
          'user_phone': userPhone,
          'amount': amount,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get Nearby Agents
  Future<Map<String, dynamic>> getNearbyAgents({
    required double latitude,
    required double longitude,
    double? radius,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        if (radius != null) 'radius': radius.toString(),
      };

      final response = await _apiService.get(
        '/agent/nearby',
        queryParams: queryParams,
        requiresAuth: false,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats({
    required String agentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'agent_id': agentId,
      };

      final response = await _apiService.get(
        '/agent/dashboard',
        queryParams: queryParams,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update Location
  Future<Map<String, dynamic>> updateLocation({
    required String agentId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final response = await _apiService.put(
        '/agent/location',
        body: {
          'agent_id': agentId,
          'latitude': latitude,
          'longitude': longitude,
          if (address != null) 'address': address,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Submit Review
  Future<Map<String, dynamic>> submitReview({
    required String agentId,
    required String transactionId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _apiService.post(
        '/agent/review',
        body: {
          'agent_id': agentId,
          'transaction_id': transactionId,
          'rating': rating,
          if (comment != null) 'comment': comment,
        },
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
