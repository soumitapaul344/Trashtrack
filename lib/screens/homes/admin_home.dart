import 'package:flutter/material.dart';
import 'package:trashtrack/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with SingleTickerProviderStateMixin {
  final auth = AuthService();
  late TabController _tabController;

  void showMsg(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> approveUser(String uid) async {
    try {
      await auth.approveStaff(uid);
      showMsg("User approved successfully!", isError: false);
      setState(() {}); // Refresh
    } catch (e) {
      showMsg(e.toString());
    }
  }

  Future<void> rejectUser(String uid) async {
    try {
      await auth.rejectStaff(uid);
      showMsg("User rejected successfully!", isError: false);
      setState(() {}); // Refresh
    } catch (e) {
      showMsg(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color(0xFF138D75),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "📋 Pending Approvals"),
            Tab(text: "👥 All Users"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _pendingApprovalsTab(),
          _allUsersTab(),
        ],
      ),
    );
  }

  Widget _pendingApprovalsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: auth.getPendingStaff(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final pending = snapshot.data ?? [];

        if (pending.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("No pending approvals"),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final user = pending[index];
            final uid = user['uid'] as String;
            final name = user['name'] as String? ?? 'Unknown';
            final email = user['email'] as String? ?? '';
            final role = user['role'] as String? ?? '';
            final verified = user['emailVerified'] as bool? ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: role == 'rider' ? Colors.orange : Colors.purple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          verified ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: verified ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          verified ? "Email Verified" : "Email Verification Pending",
                          style: TextStyle(
                            fontSize: 12,
                            color: verified ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => approveUser(uid),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text("✓ Approve"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => rejectUser(uid),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text("✕ Reject"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _allUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: auth.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final name = user['name'] as String? ?? 'Unknown';
            final email = user['email'] as String? ?? '';
            final role = user['role'] as String? ?? '';
            final approved = user['isApproved'] as bool? ?? false;
            final verified = user['emailVerified'] as bool? ?? false;

            Color roleColor;
            if (role == 'citizen') {
              roleColor = const Color(0xFF138D75);
            } else if (role == 'rider') {
              roleColor = const Color(0xFF138D75);
            } else if (role == 'cleaner') {
              roleColor = const Color(0xFF138D75);
            } else {
              roleColor = Colors.red;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(name),
                subtitle: Text(email),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          verified ? Icons.check : Icons.close,
                          size: 14,
                          color: verified ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          approved ? Icons.check : Icons.close,
                          size: 14,
                          color: approved ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}