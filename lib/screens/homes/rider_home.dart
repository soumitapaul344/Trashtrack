import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  // Theme
  final Color primaryGreen = const Color(0xFF138D75);
  final Color scaffoldBg = const Color(0xFFF4F9F9);
  final Color cardColor = Colors.white;

  int _currentIndex = 0;

  // 🔴 IMPORTANT FIX
  int _dashboardTabIndex = 0;
  int _tasksTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ---------------- APP BAR ----------------
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: scaffoldBg,
      elevation: 0,
      title: const Text(
        "TrashTrack Rider",
        style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- BODY SWITCH ----------------
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildTasksView();
      case 2:
        return const ProfilePage();
      default:
        return _buildDashboard();
    }
  }

  // ================= DASHBOARD =================
  Widget _buildDashboard() {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String name = "Rider";
              if (snapshot.hasData && snapshot.data!.exists) {
                name = snapshot.data!.get('name') ?? "Rider";
              }
              return Text(
                "HELLO, ${name.toUpperCase()}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              _dashboardTabButton(0, "Pending"),
              const SizedBox(width: 10),
              _dashboardTabButton(1, "Completed"),
              const SizedBox(width: 10),
              _dashboardTabButton(2, "All"),
            ],
          ),

          const SizedBox(height: 16),
          _buildDashboardRequests(),
        ],
      ),
    );
  }

  Widget _dashboardTabButton(int index, String text) {
    final isSelected = _dashboardTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _dashboardTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryGreen),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardRequests() {
    final user = FirebaseAuth.instance.currentUser;
    Query query = FirebaseFirestore.instance.collection('pickup_requests');

    if (_dashboardTabIndex == 0) {
      query = query.where('status', isEqualTo: 'pending');
    } else if (_dashboardTabIndex == 1) {
      query = query
          .where('status', isEqualTo: 'completed')
          .where('riderId', isEqualTo: user?.uid);
    } else {
      query = query.where('riderId', isEqualTo: user?.uid);
    }

    return _requestList(query);
  }

  // ================= TASKS VIEW (FIXED) =================
  Widget _buildTasksView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "My Tasks",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _tasksTabButton(0, "Accepted"),
              const SizedBox(width: 10),
              _tasksTabButton(1, "Completed"),
            ],
          ),

          const SizedBox(height: 16),
          _buildMyTasks(),
        ],
      ),
    );
  }

  Widget _tasksTabButton(int index, String text) {
    final isSelected = _tasksTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tasksTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryGreen),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMyTasks() {
    final user = FirebaseAuth.instance.currentUser;

    Query query = FirebaseFirestore.instance
        .collection('pickup_requests')
        .where('riderId', isEqualTo: user?.uid);

    if (_tasksTabIndex == 0) {
      query = query.where('status', isEqualTo: 'accepted');
    } else {
      query = query.where('status', isEqualTo: 'completed');
    }

    return _requestList(query);
  }

  // ================= COMMON REQUEST LIST =================
  Widget _requestList(Query query) {
    query = query.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text("No tasks found")),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return _buildRequestCard(data);
          },
        );
      },
    );
  }

  // ================= CARD =================
  Widget _buildRequestCard(Map<String, dynamic> req) {
    final isAccepted = req['status'] == 'accepted';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              req['userName'] ?? "Unknown",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(req['address'] ?? ""),
            const SizedBox(height: 10),
            if (!isAccepted)
              ElevatedButton(
                onPressed: () => _acceptTask(req),
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                child: const Text("Accept"),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptTask(Map<String, dynamic> req) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(req['id'])
        .update({'status': 'accepted', 'riderId': user.uid});
  }

  // ================= BOTTOM NAV =================
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: primaryGreen,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: "Tasks"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
