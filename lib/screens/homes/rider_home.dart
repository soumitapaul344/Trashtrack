import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  // Theme Constants matching the app's theme
  final Color primaryGreen = const Color(0xFF138D75);
  final Color scaffoldBg = const Color(0xFFF4F9F9);
  final Color cardColor = Colors.white;

  int _currentIndex = 0;
  int _selectedTaskTab = 0;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 1. App Bar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: scaffoldBg,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.recycling, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            "TrashTrack Rider",
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
          onPressed: () {
            // New pickup request alert simulation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No new notifications")),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // Main Body Content
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildTasksView();
      case 2:
        return const Center(child: Text("Profile Page"));
      default:
        return _buildDashboardContent();
    }
  }

  // Dashboard Tab Content
  Widget _buildDashboardContent() {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Header
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "HELLO,",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Dashboard Stats (Dynamic)
          const Text(
            "Overview",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pickup_requests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, pendingSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pickup_requests')
                    .where('riderId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, myTasksSnapshot) {
                   int pendingCount = 0;
                   if (pendingSnapshot.hasData) {
                     pendingCount = pendingSnapshot.data!.docs.length;
                   }

                   int myTotal = 0;
                   int myCompleted = 0;
                   int myToday = 0;

                   if (myTasksSnapshot.hasData) {
                     final docs = myTasksSnapshot.data!.docs;
                     myTotal = docs.length;
                     myCompleted = docs.where((d) => d['status'] == 'completed').length;
                     
                     // simple check for today
                     final now = DateTime.now();
                     myToday = docs.where((d) {
                        final ts = d['createdAt'];
                        if (ts != null && ts is Timestamp) {
                          final date = ts.toDate();
                          return date.year == now.year && date.month == now.month && date.day == now.day;
                        }
                        return false;
                     }).length;
                   }
                   
                   // Total = Global Pending + My Tasks (Accepted/Completed)
                   // This gives a view of "Potential Work + My Work"
                   int total = pendingCount + myTotal;

                   return Column(
                     children: [
                        Row(
                          children: [
                            _buildStatCard(
                              "Total Pickups",
                              total.toString(),
                              Icons.local_shipping,
                              Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              "Today's Tasks",
                              myToday.toString(),
                              Icons.calendar_today,
                              Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatCard(
                              "Completed",
                              myCompleted.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              "Pending",
                              pendingCount.toString(),
                              Icons.pending_actions,
                              Colors.redAccent,
                            ),
                          ],
                        ),
                     ],
                   );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Task Tabs
          Row(
            children: [
              _buildTabButton(0, "Pending Tasks"),
              const SizedBox(width: 10),
              _buildTabButton(1, "Completed"),
              const SizedBox(width: 10),
              _buildTabButton(2, "All Pickups"),
            ],
          ),

          const SizedBox(height: 16),

          // Pickup Request List
          _buildFilteredRequestsList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String text) {
    bool isSelected = _selectedTaskTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTaskTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredRequestsList() {
    final user = FirebaseAuth.instance.currentUser;
    Query query = FirebaseFirestore.instance.collection('pickup_requests');

    if (_selectedTaskTab == 0) {
      // Pending Requests (Available to all)
      query = query.where('status', isEqualTo: 'pending');
    } else if (_selectedTaskTab == 1) {
      // Completed / Accepted by me
      // "accepted" corresponds to tasks the rider has taken.
      query = query
          .where('status', isEqualTo: 'accepted')
          .where('riderId', isEqualTo: user?.uid);
    } else {
      // All Pickups (History) - For demo, maybe show all my accepted/completed ones
      query = query.where('riderId', isEqualTo: user?.uid);
    }

    // sort by time
    query = query.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No tasks found",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
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
            final data = doc.data() as Map<String, dynamic>;
            // Inject doc ID for updates
            data['id'] = doc.id;
            return _buildRequestCard(data);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    bool isCompleted =
        req['status'] ==
        'accepted'; // Using 'accepted' as the completed/active state
    String distance = "N/A"; // Placeholder

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  req['userName'] ?? "Unknown User",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? "Accepted" : distance,
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  req['address'] ?? "No Address",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scaffoldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 16, color: primaryGreen),
                const SizedBox(width: 8),
                Text(
                  "${req['wasteType']} • ${req['quantity']}",
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!isCompleted)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _acceptTask(req);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Accept",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      "Details",
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.map, color: Colors.black54),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _acceptTask(Map<String, dynamic> req) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('pickup_requests')
          .doc(req['id'])
          .update({'status': 'accepted', 'riderId': user.uid});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Task Accepted: ${req['userName']}"),
            backgroundColor: primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error accepting task: $e")));
      }
    }
  }

  // Tasks View (Tab 2)
  Widget _buildTasksView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "My Tasks",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          _buildTabButton(
            0,
            "Pending",
          ), // Reusing tab logic for filter simulation
          const SizedBox(height: 16),
          _buildFilteredRequestsList(),
        ],
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: "Tasks",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
