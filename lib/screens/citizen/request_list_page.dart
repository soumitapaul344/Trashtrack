import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestListPage extends StatelessWidget {
  final String title;
  final String userId;
  final String? statusFilter; // 'pending', 'completed', 'accepted', or null for all

  const RequestListPage({
    super.key,
    required this.title,
    required this.userId,
    this.statusFilter,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('pickup_requests')
        .where('userId', isEqualTo: userId);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No ${statusFilter ?? ''} requests found",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // Sort by createdAt in Dart (descending)
          docs.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              // PASSING docs[index].id TO THE CARD
              return _buildRequestCard(data, docs[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data, String docId) {
    // Convert status to lowercase to avoid case-mismatch issues
    final rawStatus = data['status']?.toString().toLowerCase() ?? 'unknown';
    final wasteType = data['wasteType'] ?? 'Unknown';
    final quantity = data['quantity'] ?? 'N/A';
    final address = data['address'] ?? 'No address';

    // Use Firestore Timestamp directly
    String dateStr = 'Unknown Date';
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      final ts = data['createdAt'] as Timestamp;
      dateStr = ts.toDate().toString(); 
    }

    Color statusColor = Colors.grey;
    if (rawStatus == 'pending') statusColor = Colors.orange;
    if (rawStatus == 'accepted' || rawStatus == 'picked_up') statusColor = Colors.blue;
    if (rawStatus == 'completed') statusColor = Colors.green;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  wasteType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rawStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
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
                const Icon(Icons.scale, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(quantity, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),

            // --- ADDED WASTE PICKED UP BUTTON FOR CITIZEN ---
            if (rawStatus == 'accepted')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('pickup_requests')
                          .doc(docId)
                          .update({
                            'status': 'picked_up',
                            'citizenConfirmed': true,
                            'citizenConfirmedAt': FieldValue.serverTimestamp(),
                          });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "waste pickedup",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}