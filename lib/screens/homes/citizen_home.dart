import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashtrack/screens/pickup_request_page.dart';
import 'package:trashtrack/screens/homes/request_list_page.dart';
import 'package:trashtrack/screens/homes/profile_page.dart';

class CitizenHomePage extends StatefulWidget {
  const CitizenHomePage({super.key});

  @override
  State<CitizenHomePage> createState() => _CitizenHomePageState();
}

class _CitizenHomePageState extends State<CitizenHomePage> {
  int _currentIndex = 0;

  // Theme Constants (matching Rider & App Theme)
  final Color primaryGreen = const Color(0xFF138D75);
  final Color scaffoldBg = const Color(0xFFF4F9F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildHomeAppBar(),
      body: _buildHomeContent(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // AppBar for Home
  AppBar _buildHomeAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        "TrashTrack - Citizen",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () {
              // Navigate to existing ProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: CircleAvatar(
              backgroundColor: primaryGreen.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: primaryGreen),
            ),
          ),
        ),
      ],
    );
  }

  // ================= HOME TAB CONTENT =================
  Widget _buildHomeContent() {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Greeting
          _buildGreeting(user),

          const SizedBox(height: 20),

          // Status Summary Section
          _buildStatusSummary(),

          const SizedBox(height: 30),

          // Waste Pickup Request Section (Large Button)
          _buildRequestButton(),

          const SizedBox(height: 30),

          // Past Requests List Title
          const Text(
            "Past Pickup Requests",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),

          // Past Requests List
          _buildPastRequestsList(),
        ],
      ),
    );
  }

  // Greeting Widget
  Widget _buildGreeting(User? user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "User";
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!.get('name') ?? "User";
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hello,",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: primaryGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  // Quick Stats Summary (Dynamic)
  Widget _buildStatusSummary() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int pending = 0;
        int done = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;
          pending = docs.where((doc) => doc['status'] == 'pending').length;
          // 'done' usually means completed.
          done = docs.where((doc) => doc['status'] == 'completed').length;
        }

        return Row(
          children: [
            _statsCard(
              "Total",
              total.toString(),
              Colors.blue,
              () => _navigateToRequestList(
                context,
                "All Requests",
                user.uid,
                null,
              ),
            ),
            const SizedBox(width: 12),
            _statsCard(
              "Pending",
              pending.toString(),
              Colors.orange,
              () => _navigateToRequestList(
                context,
                "Pending Requests",
                user.uid,
                'pending',
              ),
            ),
            const SizedBox(width: 12),
            _statsCard(
              "Done",
              done.toString(),
              Colors.green,
              () => _navigateToRequestList(
                context,
                "Completed Requests",
                user.uid,
                'completed',
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToRequestList(
    BuildContext context,
    String title,
    String uid,
    String? status,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RequestListPage(title: title, userId: uid, statusFilter: status),
      ),
    );
  }

  Widget _statsCard(
    String title,
    String count,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.analytics_outlined, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Waste Pickup Request Button
  Widget _buildRequestButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          shadowColor: primaryGreen.withValues(alpha: 0.4),
        ),
        onPressed: () {
          // Navigate to Pickup Request Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PickupRequestPage()),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_shopping_cart, color: Colors.white, size: 26),
            SizedBox(width: 10),
            Text(
              "Request Pickup",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Past Requests ListView (Real-time)
  Widget _buildPastRequestsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "No pickup requests yet.",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final req = doc.data() as Map<String, dynamic>;
            bool isCompleted =
                req['status'] == 'completed' || req['status'] == 'accepted';

            // Format timestamp if available
            String dateStr = "Recently";
            if (req['createdAt'] != null && req['createdAt'] is Timestamp) {
              final date = (req['createdAt'] as Timestamp).toDate();
              dateStr = "${date.day}/${date.month}/${date.year}";
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.recycling, color: primaryGreen),
                ),
                title: Text(
                  req['wasteType'] ?? "Unknown Type",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      req['address'] ?? "",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (req['status'] ?? "Pending").toString().toUpperCase(),
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            // Navigate to existing ProfilePage
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
