import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? _roleFromCollection(String collection) {
    final c = collection.toLowerCase();
    if (c == 'citizen' || c == 'citizens') return 'citizen';
    if (c == 'rider' || c == 'riders') return 'rider';
    if (c == 'cleaner' || c == 'cleaners') return 'cleaner';
    return null;
  }

  bool _boolFrom(dynamic v) {
    if (v is bool) return v;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == 'yes' || s == '1';
    }
    if (v is num) return v != 0;
    return false;
  }

  bool _deriveIsApproved(Map<String, dynamic> user) {
    if (user.containsKey('isApproved')) return _boolFrom(user['isApproved']);
    if (user.containsKey('approved')) return _boolFrom(user['approved']);

    final status = (user['status'] as String?)?.toLowerCase();
    if (status == 'pending' || status == 'rejected') return false;
    if (status == 'approved' || status == 'active' || status == 'verified') {
      return true;
    }

    final role = (user['role'] as String?)?.toLowerCase();
    if (role == 'citizen') return true;

    return false;
  }

  bool _deriveEmailVerified(Map<String, dynamic> user) {
    if (user.containsKey('emailVerified')) return _boolFrom(user['emailVerified']);
    if (user.containsKey('email_verified')) return _boolFrom(user['email_verified']);
    return false;
  }

  DateTime? _toDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchUsersFromCollection(String collection) async {
    final snapshot = await _db.collection(collection).get();
    final roleHint = _roleFromCollection(collection);

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['_collection'] = collection;
      data['_docId'] = doc.id;
      data['uid'] = data['uid'] ?? doc.id;
      if (roleHint != null) {
        final role = (data['role'] as String?)?.trim();
        if (role == null || role.isEmpty) {
          data['role'] = roleHint;
        }
      }
      data['isApproved'] = _deriveIsApproved(data);
      data['emailVerified'] = _deriveEmailVerified(data);
      return data;
    }).toList();
  }

  List<Map<String, dynamic>> _mergeUsers(List<List<Map<String, dynamic>>> lists) {
    final byUid = <String, Map<String, dynamic>>{};

    for (final list in lists) {
      for (final user in list) {
        final uid = (user['uid'] as String?)?.trim();
        if (uid == null || uid.isEmpty) {
          continue;
        }

        if (!byUid.containsKey(uid)) {
          byUid[uid] = user;
          continue;
        }

        final existing = byUid[uid]!;
        final existingFromUsers = (existing['_collection'] as String?) == 'users';
        final newFromUsers = (user['_collection'] as String?) == 'users';

        if (newFromUsers && !existingFromUsers) {
          byUid[uid] = user;
          continue;
        }

        if (!existingFromUsers && !newFromUsers) {
          // Prefer the record with more fields if both are legacy collections.
          if (user.length > existing.length) {
            byUid[uid] = user;
          }
        }
      }
    }

    final merged = byUid.values.toList();
    merged.sort((a, b) {
      final aDate = _toDateTime(a['createdAt']);
      final bDate = _toDateTime(b['createdAt']);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return merged;
  }

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
    String? nid,
    String? vehicleType,
    String? vehicleNumber,
    String? drivingLicense,
  }) async {
    // Create Firebase user
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    if (user == null) throw Exception("User creation failed");

    //  Send verification email
    await user.sendEmailVerification();

    //  Save all fields in Firestore
    bool isApproved = role == "citizen"; // Citizens auto-approved, staff needs admin approval
    
    // Format address fields
    String homeAddress = "$house, $road";
    
    final data = {
      "uid": user.uid,
      "name": name,
      "email": email,
      "house": house,
      "road": road ?? "N/A",
      "block": block,
      "contact": contact,
      "phone": contact, // Add phone field
      "homeAddress": homeAddress, // Add formatted address
      "areaZone": block, // Add area/zone
      "role": role,
      "isApproved": isApproved,
      "createdAt": FieldValue.serverTimestamp(),
    };

    if (role == 'rider') {
      data['vehicleType'] = vehicleType ?? '';
      data['vehicleNumber'] = vehicleNumber ?? '';
      data['nid'] = nid ?? '';
      data['drivingLicense'] = drivingLicense ?? '';
      data['status'] = 'pending';
    }

    if (role == 'cleaner') {
      data['nid'] = nid ?? '';
      data['status'] = 'pending';
    }

    await _db.collection("users").doc(user.uid).set(data);
  }

// Login returns current user

  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    //  Check if email is verified
    if (user != null && !user.emailVerified) {
      throw FirebaseAuthException(
        code: "email-not-verified",
        message: "Please verify your email before login",
      );
    }

    // Check if approved (for riders/cleaners)
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
  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user', message: 'No signed in user');
    await user.sendEmailVerification();
  }

  // Check current user's email verification status (reloads user)
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
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

  // Create staff account (Rider or Cleaner)

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

  // Get pending staff (riders & cleaners waiting for approval) 
  Future<List<Map<String, dynamic>>> getPendingStaff() async {
    final allUsers = await getAllUsers();
    return allUsers
        .where((user) {
          final role = (user['role'] as String?)?.toLowerCase();
          final isApproved = user['isApproved'] as bool? ?? false;
          return !isApproved && (role == 'rider' || role == 'cleaner');
        })
        .toList();
  }
  // Approve staff (by admin)
  Future<void> approveStaff(String uid, {String collection = 'users'}) async {
    await _db.collection(collection).doc(uid).update({
      'isApproved': true,
      'status': 'approved',
    });
  }
  // Reject/Delete staff (by admin) 
  Future<void> rejectStaff(String uid, {String collection = 'users'}) async {
    try {
      // Delete from Firestore
      await _db.collection(collection).doc(uid).delete();
    } catch (e) {
      throw Exception("Failed to reject staff: $e");
    }
  }

  // Get all users (for admin dashboard)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final collections = <String>[
      'users',
      'Citizen',
      'Cleaner',
      'Rider',
      'citizens',
      'riders',
      'cleaners',
    ];

    Future<List<Map<String, dynamic>>> safeFetch(String c) async {
      try {
        return await _fetchUsersFromCollection(c);
      } catch (_) {
        return [];
      }
    }

    final results = await Future.wait(
      collections.map((c) => safeFetch(c)),
    );

    return _mergeUsers(results);
  }
}
