import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/election_model.dart';
import '../utils/auth_storage.dart';

class ElectionService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all elections
  Future<List<Election>> getAllElections() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/elections'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final elections = (jsonResponse['data'] as List)
              .map((e) => Election.fromJson(e))
              .toList();
          return elections;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch elections');
        }
      } else {
        throw Exception('Failed to fetch elections: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching elections: $e');
    }
  }

  // Get election statistics
  Future<ElectionStats> getElectionStats(int electionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/elections/$electionId/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return ElectionStats.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch election stats');
        }
      } else {
        throw Exception('Failed to fetch election stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching election stats: $e');
    }
  }

  // Create new election
  Future<Election> createElection(CreateElectionRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/elections'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return Election.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to create election');
        }
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? 'Failed to create election');
      }
    } catch (e) {
      throw Exception('Error creating election: $e');
    }
  }

  // Update election
  Future<Election> updateElection(int electionId, UpdateElectionRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/elections/$electionId'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return Election.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to update election');
        }
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? 'Failed to update election');
      }
    } catch (e) {
      throw Exception('Error updating election: $e');
    }
  }

  // End election
  Future<Election> endElection(int electionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/elections/$electionId/end'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return Election.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to end election');
        }
      } else {
        throw Exception('Failed to end election: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error ending election: $e');
    }
  }

  // Pause election
  Future<Election> pauseElection(int electionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/elections/$electionId/pause'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return Election.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to pause election');
        }
      } else {
        throw Exception('Failed to pause election: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error pausing election: $e');
    }
  }

  // Resume election
  Future<Election> resumeElection(int electionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/elections/$electionId/resume'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return Election.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to resume election');
        }
      } else {
        throw Exception('Failed to resume election: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error resuming election: $e');
    }
  }

  // Delete election
  Future<void> deleteElection(int electionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/elections/$electionId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] != true) {
          throw Exception(jsonResponse['message'] ?? 'Failed to delete election');
        }
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? 'Failed to delete election');
      }
    } catch (e) {
      throw Exception('Error deleting election: $e');
    }
  }
}
