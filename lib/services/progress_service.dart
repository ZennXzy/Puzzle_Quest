import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_progress.dart';

class ProgressService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = 'http://localhost:8000'; // Adjust this to your backend URL

  // Save user progress via backend endpoint
  Future<void> saveProgress(UserProgress progress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('$baseUrl/backend/save_progress.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.uid,
          'progress': progress.toJson(),
          'id_token': idToken,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save progress: ${response.body}');
      }

      final result = jsonDecode(response.body);
      if (!result['success']) {
        throw Exception('Failed to save progress: ${result['error']}');
      }
    } catch (e) {
      throw Exception('Failed to save progress: $e');
    }
  }

  // Load user progress via backend endpoint
  Future<UserProgress?> loadProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final idToken = await user.getIdToken();

      final response = await http.get(
        Uri.parse('$baseUrl/backend/load_progress.php?user_id=${user.uid}&id_token=$idToken'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load progress: ${response.body}');
      }

      final result = jsonDecode(response.body);
      if (!result['success']) {
        throw Exception('Failed to load progress: ${result['error']}');
      }

      return UserProgress.fromJson(result['progress']);
    } catch (e) {
      throw Exception('Failed to load progress: $e');
    }
  }

  // Delete user progress (optional utility method)
  Future<void> deleteProgress() async {
    // Note: This method is not implemented in the backend yet
    // You may need to add a delete_progress.php endpoint if needed
    throw Exception('Delete progress not implemented');
  }
}
