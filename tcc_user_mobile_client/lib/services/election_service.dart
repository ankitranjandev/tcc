import 'api_service.dart';
import '../models/election_model.dart';

class ElectionService {
  final ApiService _apiService = ApiService();

  // Get active elections
  Future<List<Election>> getActiveElections() async {
    try {
      final response = await _apiService.get(
        '/elections/active',
        requiresAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        final elections = (response['data'] as List)
            .map((e) => Election.fromJson(e))
            .toList();
        return elections;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch active elections');
      }
    } catch (e) {
      throw Exception('Error fetching active elections: $e');
    }
  }

  // Get closed elections (user participated in)
  Future<List<Election>> getClosedElections() async {
    try {
      final response = await _apiService.get(
        '/elections/closed',
        requiresAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        final elections = (response['data'] as List)
            .map((e) => Election.fromJson(e))
            .toList();
        return elections;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch closed elections');
      }
    } catch (e) {
      throw Exception('Error fetching closed elections: $e');
    }
  }

  // Get election details
  Future<Election> getElectionDetails(int electionId) async {
    try {
      final response = await _apiService.get(
        '/elections/$electionId',
        requiresAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        return Election.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch election details');
      }
    } catch (e) {
      throw Exception('Error fetching election details: $e');
    }
  }

  // Cast vote
  Future<void> castVote(CastVoteRequest request) async {
    try {
      final response = await _apiService.post(
        '/elections/vote',
        body: request.toJson(),
        requiresAuth: true,
      );

      if (response['success'] != true) {
        String errorMessage = response['message'] ?? 'Failed to cast vote';

        // Handle specific error messages
        if (errorMessage.contains('already voted')) {
          throw Exception('You have already voted in this election');
        } else if (errorMessage.contains('not active')) {
          throw Exception('This election is not active');
        } else if (errorMessage.contains('ended')) {
          throw Exception('This election has ended');
        } else if (errorMessage.contains('Insufficient balance')) {
          throw Exception('Insufficient balance to cast vote');
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw if already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error casting vote: $e');
    }
  }
}
