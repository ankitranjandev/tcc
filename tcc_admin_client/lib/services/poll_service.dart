import '../models/api_response_model.dart';
import '../models/poll_model.dart';
import 'api_service.dart';

/// Poll Service
/// Handles all poll/voting-related API calls for admin
class PollService {
  final ApiService _apiService = ApiService();

  /// Get all active polls
  /// Public endpoint - shows all active polls
  Future<ApiResponse<List<PollModel>>> getActivePolls() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/polls/active',
      );

      if (response.success && response.data != null) {
        final polls = (response.data!['polls'] as List<dynamic>)
            .map((e) => PollModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return ApiResponse.success(
          data: polls,
          message: response.message,
        );
      }

      return ApiResponse.error(
        message: response.error?.message ?? 'Failed to load active polls',
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to load active polls: ${e.toString()}',
      );
    }
  }

  /// Get all polls (including drafts and ended) - Admin only
  /// Uses the active polls endpoint but you can extend this to get all polls
  Future<ApiResponse<List<PollModel>>> getAllPolls({
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        if (status != null && status != 'All') 'status': status,
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        '/polls/active',
        queryParameters: queryParameters,
      );

      if (response.success && response.data != null) {
        final polls = (response.data!['polls'] as List<dynamic>)
            .map((e) => PollModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return ApiResponse.success(
          data: polls,
          message: response.message,
        );
      }

      return ApiResponse.error(
        message: response.error?.message ?? 'Failed to load polls',
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to load polls: ${e.toString()}',
      );
    }
  }

  /// Get poll details by ID
  Future<ApiResponse<PollModel>> getPollById(String pollId) async {
    try {
      final response = await _apiService.get(
        '/polls/$pollId',
        fromJson: (data) => PollModel.fromJson(data['poll'] as Map<String, dynamic>),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to load poll details: ${e.toString()}',
      );
    }
  }

  /// Create a new poll (Admin only)
  /// Creates poll in DRAFT status
  Future<ApiResponse<PollModel>> createPoll({
    required String title,
    required String description,
    required double voteCharge,
    required List<String> options,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiService.post(
        '/polls/admin/create',
        data: {
          'title': title,
          'description': description,
          'vote_charge': voteCharge,
          'options': options,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
        fromJson: (data) => PollModel.fromJson(data['poll'] as Map<String, dynamic>),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to create poll: ${e.toString()}',
      );
    }
  }

  /// Publish a poll (change status from DRAFT to ACTIVE)
  /// Admin only
  Future<ApiResponse<PollModel>> publishPoll(String pollId) async {
    try {
      final response = await _apiService.put(
        '/polls/admin/$pollId/publish',
        fromJson: (data) => PollModel.fromJson(data['poll'] as Map<String, dynamic>),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to publish poll: ${e.toString()}',
      );
    }
  }

  /// Get poll revenue analytics
  /// Shows revenue breakdown per option
  /// Admin only
  Future<ApiResponse<PollRevenueModel>> getPollRevenue(String pollId) async {
    try {
      final response = await _apiService.get(
        '/polls/admin/$pollId/revenue',
        fromJson: (data) => PollRevenueModel.fromJson(data as Map<String, dynamic>),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to load poll revenue: ${e.toString()}',
      );
    }
  }

  /// Get poll statistics
  /// Calculate stats from polls data
  Future<ApiResponse<Map<String, dynamic>>> getPollStats() async {
    try {
      // Get all active polls
      final pollsResponse = await getActivePolls();

      if (!pollsResponse.success || pollsResponse.data == null) {
        return ApiResponse.error(
          message: 'Failed to calculate poll statistics',
        );
      }

      final polls = pollsResponse.data!;
      final totalPolls = polls.length;
      final activePolls = polls.where((p) => p.status == 'ACTIVE').length;
      final endedPolls = polls.where((p) => p.status == 'ENDED').length;
      final draftPolls = polls.where((p) => p.status == 'DRAFT').length;
      final totalVotes = polls.fold<int>(0, (sum, poll) => sum + poll.totalVotes);
      final totalRevenue = polls.fold<double>(0.0, (sum, poll) => sum + poll.totalRevenue);

      final stats = {
        'total_polls': totalPolls,
        'active_polls': activePolls,
        'ended_polls': endedPolls,
        'draft_polls': draftPolls,
        'total_votes': totalVotes,
        'total_revenue': totalRevenue,
        'average_votes_per_poll': totalPolls > 0 ? totalVotes / totalPolls : 0.0,
        'average_revenue_per_poll': totalPolls > 0 ? totalRevenue / totalPolls : 0.0,
      };

      return ApiResponse.success(data: stats);
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to calculate poll statistics: ${e.toString()}',
      );
    }
  }

  /// Search polls by query
  Future<ApiResponse<List<PollModel>>> searchPolls({
    required String query,
    String? status,
  }) async {
    try {
      final pollsResponse = await getAllPolls(status: status);

      if (!pollsResponse.success || pollsResponse.data == null) {
        return pollsResponse;
      }

      final polls = pollsResponse.data!;
      final filteredPolls = polls.where((poll) {
        final matchesQuery = poll.title.toLowerCase().contains(query.toLowerCase()) ||
            poll.description.toLowerCase().contains(query.toLowerCase());
        return matchesQuery;
      }).toList();

      return ApiResponse.success(data: filteredPolls);
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to search polls: ${e.toString()}',
      );
    }
  }

  /// Export polls data
  /// This can be implemented on backend or done client-side
  Future<ApiResponse<List<PollModel>>> exportPolls({
    String? status,
  }) async {
    return await getAllPolls(status: status);
  }
}
