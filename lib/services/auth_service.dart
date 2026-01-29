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
    await _db.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "name": name,
      "email": email,
      "house": house,
      "road": road ?? "N/A",
      "block": block,
      "contact": contact,
      "role": role,
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

    await _db.collection('users').doc(user.uid).set({
      "uid": user.uid,
      "name": name,
      "email": email,
      "house": house,
      "road": road ?? "N/A",
      "block": block,
      "contact": contact,
      "role": role,
      "createdAt": FieldValue.serverTimestamp(),
      "status": "active",
    });
  }
}
