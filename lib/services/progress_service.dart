import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_progress.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save user progress to Firestore
  Future<void> saveProgress(UserProgress progress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('user_progress').doc(user.uid).set({
        'email': progress.email,
        'currentLevel': progress.currentLevel,
        'completedImageIds': progress.completedImageIds,
        'savedStates': progress.savedStates.map((k, v) => MapEntry(k.toString(), v.toJson())),
        'bestTimes': progress.bestTimes.map((k, v) => MapEntry(k.toString(), v)),
        'achievements': progress.achievements,
        'updated_at': FieldValue.serverTimestamp(),
      });
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
        final data = doc.data()!;
        return UserProgress.fromJson(data);
      } else {
        // Return default progress if no document exists
        return UserProgress(
          email: user.email ?? '',
          currentLevel: 1,
          completedImageIds: [],
          savedStates: {},
          bestTimes: {},
          achievements: {},
        );
      }
    } catch (e) {
      throw Exception('Failed to load progress: $e');
    }
  }

  // Delete user progress (optional utility method)
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
