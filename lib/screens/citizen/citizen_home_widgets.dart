import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashtrack/screens/citizen/pickup_request_page.dart';
import 'package:trashtrack/screens/citizen/request_list_page.dart';

/// Greeting widget that displays user's name from Firestore
class GreetingWidget extends StatelessWidget {
  final User? user;
  final Color primaryGreen;

  const GreetingWidget({
    super.key,
    required this.user,
    required this.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Status summary widget showing total, pending, and completed requests
class StatusSummaryWidget extends StatelessWidget {
  final User? user;
  final Color primaryGreen;

  const StatusSummaryWidget({
    super.key,
    required this.user,
    required this.primaryGreen,
  });

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

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('userId', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int pending = 0;
        int done = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;
          pending = docs.where((doc) => doc['status'] == 'pending').length;
          done = docs.where((doc) => doc['status'] == 'completed').length;
        }

        return Row(
          children: [
            StatsCard(
              title: "Total",
              count: total.toString(),
              color: Colors.blue,
              onTap: () => _navigateToRequestList(
                context,
                "All Requests",
                user!.uid,
                null,
              ),
            ),
            const SizedBox(width: 12),
            StatsCard(
              title: "Pending",
              count: pending.toString(),
              color: Colors.orange,
              onTap: () => _navigateToRequestList(
                context,
                "Pending Requests",
                user!.uid,
                'pending',
              ),
            ),
            const SizedBox(width: 12),
            StatsCard(
              title: "Done",
              count: done.toString(),
              color: Colors.green,
              onTap: () => _navigateToRequestList(
                context,
                "Completed Requests",
                user!.uid,
                'completed',
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Individual stats card widget
class StatsCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final VoidCallback onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Request pickup button widget
class RequestPickupButton extends StatelessWidget {
  final Color primaryGreen;

  const RequestPickupButton({super.key, required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
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
}

/// Past requests list widget showing all user's pickup requests
class PastRequestsListWidget extends StatelessWidget {
  final User? user;
  final Color primaryGreen;

  const PastRequestsListWidget({
    super.key,
    required this.user,
    required this.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('userId', isEqualTo: user!.uid)
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

        // Sort documents by createdAt in Dart (descending)
        final docs = snapshot.data!.docs;
        docs.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final req = doc.data() as Map<String, dynamic>;
            bool isCompleted = req['status'] == 'completed';

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
}
