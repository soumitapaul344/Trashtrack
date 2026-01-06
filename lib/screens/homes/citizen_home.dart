import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CitizenHomePage extends StatefulWidget {
  const CitizenHomePage({super.key});

  @override
  State<CitizenHomePage> createState() => _CitizenHomePageState();
}

class _CitizenHomePageState extends State<CitizenHomePage> {
  int _currentIndex = 0;

  // Theme Constants
  final Color primaryGreen = const Color(
    0xFF138D75,
  ); // Matched to your Signup Button
  final Color scaffoldBg = const Color(0xFFF4F9F9); // Matched to your Signup Bg

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey.shade500,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard_rounded),
            label: "Rewards",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _homeContent();
      case 1:
        return const Center(child: Text("Requests Page"));
      case 2:
        return const Center(child: Text("Rewards Page"));
      case 3:
        return const Center(child: Text("Profile Page"));
      default:
        return _homeContent();
    }
  }

  // ================= HOME CONTENT =================
  Widget _homeContent() {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _header(user),
          const SizedBox(height: 35),
          _quickActions(),
          const SizedBox(height: 35),
          _recentActivity(),
        ],
      ),
    );
  }

  // ================= HEADER (LOGIC SYNCED WITH AUTH SERVICE) =================
  Widget _header(User? user) {
    return StreamBuilder<DocumentSnapshot>(
      // Logic: Listening to the 'users' collection created in your AuthService
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "Citizen"; // Fallback

        if (snapshot.hasData && snapshot.data!.exists) {
          // Sync: Using the 'name' key from your AuthService.signUp method
          name = snapshot.data!.get('name') ?? "Citizen";
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: primaryGreen,
              child: const Icon(Icons.person, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "HELLO,",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ================= ENHANCED QUICK ACTIONS =================
  Widget _quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.0,
          children: [
            _actionCard(
              Icons.local_shipping_rounded,
              "Request\nPickup",
              primaryGreen,
            ),
            _actionCard(
              Icons.warning_amber_rounded,
              "Report\nIssue",
              Colors.orange,
            ),
            _actionCard(Icons.map_rounded, "Track\nStatus", Colors.blue),
            _actionCard(
              Icons.support_agent_rounded,
              "Help\nCenter",
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centered
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 42), // Large Icon
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center, // Centered Text
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF34495E),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= RECENT ACTIVITY =================
  Widget _recentActivity() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Activity",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('activities')
              .where('userId', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "No recent activities",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryGreen.withOpacity(0.1),
                        child: Icon(
                          Icons.history,
                          color: primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "View details",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        doc['status'],
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
