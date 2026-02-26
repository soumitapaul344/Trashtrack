import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashtrack/screens/citizen/pickup_request_page.dart';
import 'package:trashtrack/screens/citizen/request_list_page.dart';
import 'package:trashtrack/screens/homes/profile_page.dart';
import 'package:trashtrack/screens/citizen/citizen_home_widgets.dart';

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
    final user = FirebaseAuth.instance.currentUser;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        "TrashTrack - Citizen",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      actions: [
        if (user != null)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pickup_requests')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              int pendingCount = 0;
              if (snapshot.hasData) {
                pendingCount = snapshot.data!.docs
                    .where((doc) => doc['status'] == 'pending')
                    .length;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestListPage(
                              title: "Pending Requests",
                              userId: user.uid,
                              statusFilter: 'pending',
                            ),
                          ),
                        );
                      },
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            pendingCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
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
          GreetingWidget(user: user, primaryGreen: primaryGreen),

          const SizedBox(height: 20),

          // Status Summary Section
          StatusSummaryWidget(user: user, primaryGreen: primaryGreen),

          const SizedBox(height: 30),

          // Waste Pickup Request Section (Large Button)
          RequestPickupButton(primaryGreen: primaryGreen),

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
          PastRequestsListWidget(user: user, primaryGreen: primaryGreen),
        ],
      ),
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
          setState(() => _currentIndex = index);
          if (index == 1) {
            // Navigate to existing ProfilePage
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ).then((_) {
              setState(() => _currentIndex = 0);
            });
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
