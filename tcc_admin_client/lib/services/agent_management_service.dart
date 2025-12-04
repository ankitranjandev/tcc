import '../models/api_response_model.dart';
import '../models/agent_model.dart';
import 'api_service.dart';

/// Agent Management Service
/// Handles all agent management-related API calls for admin
class AgentManagementService {
  final ApiService _apiService = ApiService();

  /// Get all agents with pagination, search, and filters
  Future<ApiResponse<PaginatedResponse<AgentModel>>> getAgents({
    int page = 1,
    int perPage = 25,
    String? search,
    String? status,
    String? verificationStatus,
    String? location,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': perPage,  // Backend uses 'limit' not 'per_page'
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'active_status': status,
      if (verificationStatus != null && verificationStatus.isNotEmpty)
        'verification_status': verificationStatus,
      if (location != null && location.isNotEmpty) 'location': location,
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort_order': sortOrder,
    };

    final response = await _apiService.get<Map<String, dynamic>>(
      '/admin/agents',
      queryParameters: queryParameters,
    );

    // Transform the response to PaginatedResponse
    if (response.success && response.data != null && response.meta != null) {
      try {
        final responseData = response.data!;
        final agents = (responseData['agents'] as List<dynamic>)
            .map((e) => AgentModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final pagination = response.meta!['pagination'] as Map<String, dynamic>?;

        if (pagination != null) {
          final paginatedResponse = PaginatedResponse<AgentModel>(
            data: agents,
            total: pagination['total'] as int,
            page: pagination['page'] as int,
            perPage: pagination['limit'] as int,
            totalPages: pagination['totalPages'] as int,
          );

          return ApiResponse.success(
            data: paginatedResponse,
            message: response.message,
          );
        }
      } catch (e) {
        return ApiResponse.error(
          message: 'Failed to parse agents response: ${e.toString()}',
        );
      }
    }

    // If response failed or data is null
    return ApiResponse.error(
      message: response.error?.message ?? 'Failed to load agents',
    );
  }

  /// Get agent by ID
  Future<ApiResponse<AgentModel>> getAgentById(String agentId) async {
    return await _apiService.get(
      '/admin/agents/$agentId',
      fromJson: (data) => AgentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Search agents by query
  Future<ApiResponse<List<AgentModel>>> searchAgents({
    required String query,
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      '/admin/agents',
      queryParameters: {
        'search': query,
        'per_page': limit,
      },
      fromJson: (data) {
        final paginatedData = data as Map<String, dynamic>;
        final agents = (paginatedData['data'] as List<dynamic>)
            .map((e) => AgentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return agents;
      },
    );

    return response;
  }

  /// Update agent status (activate, deactivate, suspend)
  Future<ApiResponse<AgentModel>> updateAgentStatus({
    required String agentId,
    required String status,
  }) async {
    return await _apiService.put(
      '/admin/agents/$agentId/status',
      data: {
        'status': status,
      },
      fromJson: (data) => AgentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Update agent verification status
  Future<ApiResponse<AgentModel>> updateAgentVerification({
    required String agentId,
    required String verificationStatus,
    String? remarks,
  }) async {
    return await _apiService.put(
      '/admin/agents/$agentId/verification',
      data: {
        'verification_status': verificationStatus,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
      fromJson: (data) => AgentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Update agent commission rate
  Future<ApiResponse<AgentModel>> updateCommissionRate({
    required String agentId,
    required double commissionRate,
  }) async {
    return await _apiService.put(
      '/admin/agents/$agentId/commission',
      data: {
        'commission_rate': commissionRate,
      },
      fromJson: (data) => AgentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Get agent credit requests (pending approvals)
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getAgentCreditRequests({
    int page = 1,
    int perPage = 25,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _apiService.get(
      '/admin/agent-credits',
      queryParameters: queryParameters,
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Review agent credit request (approve/reject)
  Future<ApiResponse<Map<String, dynamic>>> reviewAgentCredit({
    required String creditId,
    required String action, // 'approve' or 'reject'
    String? remarks,
  }) async {
    return await _apiService.post(
      '/admin/agent-credits/review',
      data: {
        'credit_id': creditId,
        'action': action,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get agent statistics
  Future<ApiResponse<Map<String, dynamic>>> getAgentStats() async {
    return await _apiService.get(
      '/admin/agents/stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get agent performance metrics
  Future<ApiResponse<Map<String, dynamic>>> getAgentPerformance(String agentId) async {
    return await _apiService.get(
      '/admin/agents/$agentId/performance',
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get agent transactions
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getAgentTransactions({
    required String agentId,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _apiService.get(
      '/admin/agents/$agentId/transactions',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Get agent commission history
  Future<ApiResponse<PaginatedResponse<Map<String, dynamic>>>> getAgentCommissions({
    required String agentId,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _apiService.get(
      '/admin/agents/$agentId/commissions',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
      fromJson: (data) => PaginatedResponse.fromJson(
        data as Map<String, dynamic>,
        (json) => json,
      ),
    );

    return response;
  }

  /// Export agents data
  Future<ApiResponse<String>> exportAgents({
    String format = 'csv',
    String? status,
    String? verificationStatus,
  }) async {
    final queryParameters = <String, dynamic>{
      'format': format,
      if (status != null && status.isNotEmpty) 'status': status,
      if (verificationStatus != null && verificationStatus.isNotEmpty)
        'verification_status': verificationStatus,
    };

    return await _apiService.get(
      '/admin/agents/export',
      queryParameters: queryParameters,
      fromJson: (data) => data['url'] as String,
    );
  }

  /// Create new agent (admin only)
  Future<ApiResponse<AgentModel>> createAgent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String countryCode,
    required String businessName,
    required String businessRegistrationNumber,
    required String location,
    String? address,
    required double commissionRate,
  }) async {
    return await _apiService.post(
      '/admin/agents',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'phone': phone,
        'country_code': countryCode,
        'business_name': businessName,
        'business_registration_number': businessRegistrationNumber,
        'location': location,
        if (address != null && address.isNotEmpty) 'address': address,
        'commission_rate': commissionRate,
      },
      fromJson: (data) => AgentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Update agent details
  Future<ApiResponse<AgentModel>> updateAgent({
    required String agentId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? countryCode,
    String? businessName,
    String? businessRegistrationNumber,
    String? location,
    String? address,
    double? commissionRate,
  }) async {
    return await _apiService.put(
      '/admin/agents/$agentId',
      data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (countryCode != null) 'country_code': countryCode,
        if (businessName != null) 'business_name': businessName,
        if (businessRegistrationNumber != null)
          'business_registration_number': businessRegistrationNumber,
        if (location != null) 'location': location,
        if (address != null) 'address': address,
        if (commissionRate != null) 'commission_rate': commissionRate,
      },
      fromJson: (data) => AgentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Delete agent
  Future<ApiResponse<void>> deleteAgent(String agentId) async {
    return await _apiService.delete(
      '/admin/agents/$agentId',
    );
  }
}
