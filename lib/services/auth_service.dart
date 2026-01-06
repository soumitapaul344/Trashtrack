import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Signup citizen account with full fields
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
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Store all fields in Firestore
    await _db.collection("users").doc(userCredential.user!.uid).set({
      "uid": userCredential.user!.uid,
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

  // Login returns current user
  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get role of current user
  Future<String?> getRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    return data?['role'] as String?;
  }

  // Optional: create staff account (Rider or Cleaner)
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

    await _db.collection('users').doc(res.user!.uid).set({
      "uid": res.user!.uid,
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
