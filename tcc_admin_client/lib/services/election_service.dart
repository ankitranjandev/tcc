import '../models/election_model.dart';
import 'api_service.dart';

class ElectionService {
  final ApiService _apiService = ApiService();

  // Get all elections
  Future<List<Election>> getAllElections() async {
    final response = await _apiService.get<List<Election>>(
      '/admin/elections',
      fromJson: (data) {
        if (data is List) {
          return data.map((e) => Election.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to fetch elections');
    }
  }

  // Get election statistics
  Future<ElectionStats> getElectionStats(int electionId) async {
    final response = await _apiService.get<ElectionStats>(
      '/admin/elections/$electionId/stats',
      fromJson: (data) => ElectionStats.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to fetch election stats');
    }
  }

  // Create new election
  Future<Election> createElection(CreateElectionRequest request) async {
    final response = await _apiService.post<Election>(
      '/admin/elections',
      data: request.toJson(),
      fromJson: (data) => Election.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to create election');
    }
  }

  // Update election
  Future<Election> updateElection(int electionId, UpdateElectionRequest request) async {
    final response = await _apiService.put<Election>(
      '/admin/elections/$electionId',
      data: request.toJson(),
      fromJson: (data) => Election.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to update election');
    }
  }

  // End election
  Future<Election> endElection(int electionId) async {
    final response = await _apiService.post<Election>(
      '/admin/elections/$electionId/end',
      fromJson: (data) => Election.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to end election');
    }
  }

  // Pause election
  Future<Election> pauseElection(int electionId) async {
    final response = await _apiService.post<Election>(
      '/admin/elections/$electionId/pause',
      fromJson: (data) => Election.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to pause election');
    }
  }

  // Resume election
  Future<Election> resumeElection(int electionId) async {
    final response = await _apiService.post<Election>(
      '/admin/elections/$electionId/resume',
      fromJson: (data) => Election.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to resume election');
    }
  }

  // Delete election
  Future<void> deleteElection(int electionId) async {
    final response = await _apiService.delete<void>(
      '/admin/elections/$electionId',
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to delete election');
    }
  }
}
