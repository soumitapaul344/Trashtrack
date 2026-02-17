import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Log user activity
  Future<void> logActivity({
    required String activityType, // 'login', 'logout', 'waste_reported', etc.
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('activities').add({
        'userId': user.uid,
        'activityType': activityType,
        'description': description,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging activity: $e');
    }
  }

  // Get user activities
  Future<List<Map<String, dynamic>>> getUserActivities(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching activities: $e');
      return [];
    }
  }

  // Get all activities (admin)
  Future<List<Map<String, dynamic>>> getAllActivities() async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching all activities: $e');
      return [];
    }
  }
}
