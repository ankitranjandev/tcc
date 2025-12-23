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

  // Get active elections
  Future<List<Election>> getActiveElections() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/elections/active'),
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
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch active elections');
        }
      } else {
        throw Exception('Failed to fetch active elections: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching active elections: $e');
    }
  }

  // Get closed elections (user participated in)
  Future<List<Election>> getClosedElections() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/elections/closed'),
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
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch closed elections');
        }
      } else {
        throw Exception('Failed to fetch closed elections: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching closed elections: $e');
    }
  }

  // Get election details
  Future<Election> getElectionDetails(int electionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/elections/$electionId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return Election.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch election details');
        }
      } else {
        throw Exception('Failed to fetch election details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching election details: $e');
    }
  }

  // Cast vote
  Future<void> castVote(CastVoteRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/elections/vote'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] != true) {
          throw Exception(jsonResponse['message'] ?? 'Failed to cast vote');
        }
      } else {
        final errorResponse = json.decode(response.body);
        String errorMessage = errorResponse['message'] ?? 'Failed to cast vote';

        // Handle specific error messages
        if (response.statusCode == 400) {
          if (errorMessage.contains('already voted')) {
            throw Exception('You have already voted in this election');
          } else if (errorMessage.contains('not active')) {
            throw Exception('This election is not active');
          } else if (errorMessage.contains('ended')) {
            throw Exception('This election has ended');
          } else if (errorMessage.contains('Insufficient balance')) {
            throw Exception('Insufficient balance to cast vote');
          }
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
