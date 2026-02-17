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
  int _historyTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ---------------- BODY SWITCH ----------------
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildHistory();
      case 2:
        return _buildEarnings();
      case 3:
        return const ProfilePage();
      default:
        return _buildHome();
    }
  }

  // ================= HOME PAGE =================
  Widget _buildHome() {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODAY'S SUMMARY
                const Text(
                  "TODAY'S SUMMARY",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryCards(),
                const SizedBox(height: 24),

                // PICKUP REQUESTS HEADER - Dynamic count
                _buildPickupRequestsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "User";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['name'] ?? "User";
        }

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF138D75),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome,",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 8),
                        SizedBox(width: 6),
                        Text(
                          "Online",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('riderId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int pickups = 0;
        int earnings = 0;

        if (snapshot.hasData) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';

            // Parse date if available
            if (data['createdAt'] != null) {
              try {
                final createdDate = (data['createdAt'] as Timestamp).toDate();
                final createdDay = DateTime(
                  createdDate.year,
                  createdDate.month,
                  createdDate.day,
                );

                // Count pickups if accepted or completed today
                if (createdDay == today &&
                    (status == 'accepted' || status == 'completed')) {
                  pickups++;
                }

                // Count earnings if completed today
                if (createdDay == today && status == 'completed') {
                  earnings += 50;
                }
              } catch (e) {
                // Skip if date parsing fails
              }
            }
          }
        }

        return Row(
          children: [
            Expanded(
              child: _summaryCard("Pickups", pickups.toString(), Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard("Earnings", "₹$earnings", Colors.orange),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupRequestsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .snapshots(),
      builder: (context, snapshot) {
        int pendingCount = 0;

        if (snapshot.hasData) {
          // Count only pending requests
          pendingCount = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            return status == 'pending';
          }).length;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pickup Requests ($pendingCount)",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 12),
            _buildPickupRequests(),
          ],
        );
      },
    );
  }

  Widget _buildPickupRequests() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter only pending requests
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'pending';
          return status == 'pending';
        }).toList();

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text("No pending requests")),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildPickupCard(data, doc.id, user?.uid ?? "");
          },
        );
      },
    );
  }

  Widget _buildPickupCard(
    Map<String, dynamic> req,
    String docId,
    String userId,
  ) {
    String wasteType = req['wasteType'] ?? "Unknown";
    String address = req['address'] ?? "";
    String weight = req['weight'] ?? "0";
    String timeSlot = req['timeSlot'] ?? "00:00";
    String endTime = req['endTime'] ?? "00:00";
    String status = req['status'] ?? "pending";

    // Determine color based on waste type
    Color typeColor = _getWasteTypeColor(wasteType);
    Color tagColor = _getWasteTypeTagColor(wasteType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "REQ-2456",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  wasteType,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.scale, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    "Weight: $weight kg",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    "Time: $timeSlot - $endTime",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (status == 'pending')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptTask(docId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Accept",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else if (status == 'accepted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _markAsDone(docId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Mark as Done",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getWasteTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'plastic':
        return Colors.blue.shade600;
      case 'organic':
        return Colors.green.shade600;
      case 'metal':
        return Colors.grey.shade600;
      case 'paper':
        return Colors.brown.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getWasteTypeTagColor(String type) {
    switch (type.toLowerCase()) {
      case 'plastic':
        return Colors.blue.shade50;
      case 'organic':
        return Colors.green.shade50;
      case 'metal':
        return Colors.grey.shade100;
      case 'paper':
        return Colors.brown.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Future<void> _acceptTask(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId)
        .update({'status': 'accepted', 'riderId': user.uid});

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pickup request accepted!")));
    }
  }

  Future<void> _markAsDone(String docId) async {
    await FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId)
        .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Marked as completed!")));
    }
  }

  // ================= PICKUP HISTORY =================
  Widget _buildHistory() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pickup History",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "View all your packages",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _historyTabButton(0, "Accepted"),
                    const SizedBox(width: 10),
                    _historyTabButton(1, "Completed"),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHistoryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyTabButton(int index, String text) {
    final isSelected = _historyTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _historyTabIndex = index;
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

  Widget _buildHistoryList() {
    final user = FirebaseAuth.instance.currentUser;
    String filterStatus = _historyTabIndex == 0 ? 'accepted' : 'completed';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('riderId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter by status
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'pending';
          return status == filterStatus;
        }).toList();

        String emptyMsg = filterStatus == 'completed'
            ? "No completed pickups"
            : "No accepted pickups";

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(30),
            child: Center(child: Text(emptyMsg)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildHistoryCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> req, String docId) {
    String wasteType = req['wasteType'] ?? "Unknown";
    String address = req['address'] ?? "";
    String weight = req['weight'] ?? "0";
    int earnings = req['earnings'] ?? 0;
    String status = req['status'] ?? 'accepted';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "REQ-2455",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wasteType,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              if (status == 'completed')
                const Text(
                  "₹50",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                "Today",
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              Icon(Icons.scale, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                "$weight kg",
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (status == 'accepted')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _markAsDone(docId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    "Mark as Done",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= EARNINGS =================
  Widget _buildEarnings() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Earnings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Track your daily performance",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEarningsCards(),
                const SizedBox(height: 20),
                _buildEarningsStats(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCards() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('riderId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int todayEarnings = 0;
        int weekEarnings = 0;
        int monthEarnings = 0;

        if (snapshot.hasData) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final weekAgo = today.subtract(const Duration(days: 7));
          final monthAgo = DateTime(now.year, now.month - 1, now.day);

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';

            // Only count completed pickups
            if (status != 'completed') continue;

            const int earning = 50; // Fixed 50 per pickup

            // Parse date if available
            if (data['completedAt'] != null) {
              final completedDate = (data['completedAt'] as Timestamp).toDate();
              final completedDay = DateTime(
                completedDate.year,
                completedDate.month,
                completedDate.day,
              );

              if (completedDay == today) {
                todayEarnings += earning;
              }
              if (completedDate.isAfter(weekAgo)) {
                weekEarnings += earning;
              }
              if (completedDate.isAfter(monthAgo)) {
                monthEarnings += earning;
              }
            }
          }
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "₹$todayEarnings",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "This package",
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "₹$weekEarnings",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "This Week",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "↑ 15% from last week",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "This Month",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹$monthEarnings",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEarningsStats() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('riderId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int totalPickups = 0;
        int totalEarnings = 0;

        if (snapshot.hasData) {
          // Count only completed pickups
          final completedDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            return status == 'completed';
          }).toList();

          totalPickups = completedDocs.length;
          totalEarnings = totalPickups * 50; // 50 per pickup
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Statistics",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$totalPickups",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Total Pickups",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "₹50",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Per Pickup",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= BOTTOM NAV =================
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey.shade400,
      type: BottomNavigationBarType.fixed,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: "History",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wallet_outlined),
          activeIcon: Icon(Icons.wallet),
          label: "Earnings",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    );
  }
}
