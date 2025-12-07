import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_progress.dart';

class ProgressService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user progress to Firestore
  Future<void> saveProgress(UserProgress progress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('user_progress').doc(user.uid).set(progress.toJson());
    } catch (e) {
      throw Exception('Failed to save progress: $e');
    }
  }

  // Load user progress from Firestore
  Future<UserProgress?> loadProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final doc = await _firestore.collection('user_progress').doc(user.uid).get();
      if (doc.exists) {
        return UserProgress.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to load progress: $e');
    }
  }

  // Delete user progress from Firestore
  Future<void> deleteProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('user_progress').doc(user.uid).delete();
    } catch (e) {
      throw Exception('Failed to delete progress: $e');
    }
  }
}
