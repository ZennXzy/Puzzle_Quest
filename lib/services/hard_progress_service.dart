import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hard_user_progress.dart';

class HardProgressService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save hard mode user progress to Firestore
  Future<void> saveProgress(HardUserProgress progress) async {
    final jsonData = progress.toJson();
    try {
      final user = _auth.currentUser;
      print('[HardProgressService] saveProgress called');
      print('[HardProgressService] Current Firebase user: ${user?.uid}');
      print('[HardProgressService] Current Firebase user email: ${user?.email}');
      
      if (user == null) {
        print('[HardProgressService] User is NULL - cannot save to Firebase');
        return;
      }

      print('[HardProgressService] Saving hard mode progress for user: ${user.uid}');
      print('[HardProgressService] Progress data: currentLevel=${progress.currentLevel}, completedCount=${progress.completedImageIds.length}');
      
      print('[HardProgressService] JSON to save: $jsonData');
      
      await _firestore
          .collection('hard_user_progress')
          .doc(user.uid)
          .set(jsonData);
      
      print('[HardProgressService] Successfully wrote to Firestore');
    } catch (e) {
      print('[HardProgressService] Exception during save: $e');
      print('[HardProgressService] Stack trace: ${StackTrace.current}');

      // On permission errors or other failures, write a pending local copy
      try {
        final prefs = await SharedPreferences.getInstance();
        final fallbackKey = 'hard_user_progress_pending_${_auth.currentUser?.uid ?? 'guest'}';
        await prefs.setString(fallbackKey, jsonEncode(jsonData));
        print('[HardProgressService] Saved pending progress to local prefs with key: $fallbackKey');
      } catch (e2) {
        print('[HardProgressService] Failed to save pending progress locally: $e2');
      }

      // don't rethrow to avoid breaking UI flow; caller already logs errors
      return;
    }
  }

  // Load hard mode user progress from Firestore
  Future<HardUserProgress?> loadProgress() async {
    try {
      final user = _auth.currentUser;
      print('[HardProgressService] loadProgress called');
      print('[HardProgressService] Current Firebase user: ${user?.uid}');
      
      if (user == null) {
        print('[HardProgressService] User is NULL - cannot load from Firebase');
        return null;
      }

      // Attempt to flush any pending local progress first
      await _flushPendingForUser(user.uid);

      print('[HardProgressService] Loading hard mode progress for user: ${user.uid}');
      final doc = await _firestore
          .collection('hard_user_progress')
          .doc(user.uid)
          .get();
      
      print('[HardProgressService] Document exists: ${doc.exists}');
      
      if (doc.exists) {
        print('[HardProgressService] Hard mode progress found in Firebase');
        print('[HardProgressService] Document data: ${doc.data()}');
        return HardUserProgress.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        print('[HardProgressService] No hard mode progress found in Firebase');
        return null;
      }
    } catch (e) {
      print('[HardProgressService] Exception during load: $e');
      print('[HardProgressService] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Delete hard mode user progress from Firestore
  Future<void> deleteProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('[HardProgressService] User not authenticated, cannot delete');
        return;
      }

      print('[HardProgressService] Deleting hard mode progress for user: ${user.uid}');
      await _firestore.collection('hard_user_progress').doc(user.uid).delete();
      print('[HardProgressService] Successfully deleted hard mode progress');
    } catch (e) {
      print('[HardProgressService] Error deleting hard mode progress: $e');
      rethrow;
    }
  }

  // Attempt to flush pending saved progress stored in SharedPreferences
  Future<void> _flushPendingForUser(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fallbackKey = 'hard_user_progress_pending_$uid';
      final pending = prefs.getString(fallbackKey);
      if (pending == null) return;

      print('[HardProgressService] Found pending progress for user $uid, attempting flush');
      final Map<String, dynamic> jsonData = jsonDecode(pending) as Map<String, dynamic>;
      await _firestore.collection('hard_user_progress').doc(uid).set(jsonData);
      await prefs.remove(fallbackKey);
      print('[HardProgressService] Successfully flushed pending progress for user $uid');
    } catch (e) {
      print('[HardProgressService] Failed to flush pending progress: $e');
    }
  }
}
