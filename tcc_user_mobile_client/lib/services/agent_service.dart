import 'api_service.dart';

class AgentService {
  final ApiService _apiService = ApiService();

  // Get nearby agents
  Future<Map<String, dynamic>> getNearbyAgents({
    required double latitude,
    required double longitude,
    double? radius, // in kilometers
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      };
      if (radius != null) queryParams['radius'] = radius.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiService.get(
        '/agent/nearby',
        queryParams: queryParams,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get agent details by ID
  Future<Map<String, dynamic>> getAgentDetails({
    required String agentId,
  }) async {
    try {
      final response = await _apiService.get(
        '/agent/$agentId',
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Submit agent review
  Future<Map<String, dynamic>> submitAgentReview({
    required String agentId,
    required int rating, // 1-5
    String? comment,
  }) async {
    try {
      final body = <String, dynamic>{
        'agentId': agentId,
        'rating': rating,
      };
      if (comment != null) body['comment'] = comment;

      final response = await _apiService.post(
        '/agent/review',
        body: body,
        requiresAuth: true,
      );
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
