import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ---------------------------
  // Signup citizen account
  // ---------------------------
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String house,
    String? road,
    required String block,
    required String contact,
    required String role,
  }) async {
    // 1️⃣ Create Firebase user
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    if (user == null) throw Exception("User creation failed");

    // 2️⃣ Send verification email
    await user.sendEmailVerification();

    // 3️⃣ Save all fields in Firestore
    bool isApproved = role == "citizen"; // Citizens auto-approved, staff needs admin approval
    await _db.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "name": name,
      "email": email,
      "house": house,
      "road": road ?? "N/A",
      "block": block,
      "contact": contact,
      "role": role,
      "isApproved": isApproved,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------
  // Login returns current user
  // ---------------------------
  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    // ✅ Check if email is verified
    if (user != null && !user.emailVerified) {
      throw FirebaseAuthException(
        code: "email-not-verified",
        message: "Please verify your email before login",
      );
    }

    // ✅ Check if approved (for riders/cleaners)
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final isApproved = doc.get('isApproved') as bool? ?? false;
        final role = doc.get('role') as String? ?? '';
        if (!isApproved && (role == 'rider' || role == 'cleaner')) {
          throw FirebaseAuthException(
            code: "pending-approval",
            message: "Your account is pending admin approval",
          );
        }
      }
    }

    return user;
  }

  // ---------------------------
  // Logout
  // ---------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ---------------------------
  // Resend verification email
  // ---------------------------
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user', message: 'No signed in user');
    await user.sendEmailVerification();
  }

  // ---------------------------
  // Check current user's email verification status (reloads user)
  // ---------------------------
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ---------------------------
  // Get role of current user
  // ---------------------------
  Future<String?> getRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    return data?['role'] as String?;
  }

  // ---------------------------
  // Create staff account (Rider or Cleaner)
  // ---------------------------
  Future<void> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required String house,
    String? road,
    required String block,
    required String contact,
    required String role,
  }) async {
    final res = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) throw Exception("Staff creation failed");

    // Send verification email to the newly created staff
    await user.sendEmailVerification();

    await _db.collection('users').doc(user.uid).set({
      "uid": user.uid,
      "name": name,
      "email": email,
      "house": house,
      "road": road ?? "N/A",
      "block": block,
      "contact": contact,
      "role": role,
      "isApproved": false, // Starts unapproved, admin must approve
      "createdAt": FieldValue.serverTimestamp(),
      "status": "active",
    });
  }

  // ---------------------------
  // Get pending staff (riders & cleaners waiting for approval)
  // ---------------------------
  Future<List<Map<String, dynamic>>> getPendingStaff() async {
    final snapshot = await _db
        .collection('users')
        .where('isApproved', isEqualTo: false)
        .where('role', whereIn: ['rider', 'cleaner'])
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ---------------------------
  // Approve staff (by admin)
  // ---------------------------
  Future<void> approveStaff(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isApproved': true,
    });
  }

  // ---------------------------
  // Reject/Delete staff (by admin)
  // ---------------------------
  Future<void> rejectStaff(String uid) async {
    try {
      // Delete from Firestore
      await _db.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception("Failed to reject staff: $e");
    }
  }

  // ---------------------------
  // Get all users (for admin dashboard)
  // ---------------------------
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
