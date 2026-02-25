part of 'rider_home.dart';

extension RiderHomeSection on _RiderHomeState {
  // ================= HOME PAGE =================
  Widget _buildHome() {
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

                // Count earnings if completed today — use completedAt if available
                if (status == 'completed') {
                  DateTime? completedDateTime;
                  if (data['completedAt'] != null) {
                    try {
                      completedDateTime = (data['completedAt'] as Timestamp)
                          .toDate();
                    } catch (e) {
                      completedDateTime = null;
                    }
                  }

                  final usedDate = completedDateTime ?? createdDate;
                  final usedDay = DateTime(
                    usedDate.year,
                    usedDate.month,
                    usedDate.day,
                  );

                  if (usedDay == today) {
                    earnings += 50;
                  }
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
              child: _summaryCard("Earnings", "৳$earnings", Colors.orange),
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
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

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
    String weight = req['quantity'] ?? "0";
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
                  (() {
                    final code = docId.length >= 6
                        ? docId.substring(0, 6).toUpperCase()
                        : docId.toUpperCase();
                    return 'REQ-$code';
                  })(),
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
            // Show Call, Picked Up, and Mark as Done buttons
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(req['userId'] as String?)
                  .get(),
              builder: (context, snap) {
                String phone = '';
                if (snap.hasData && snap.data!.exists) {
                  final d = snap.data!.data() as Map<String, dynamic>?;
                  phone = d?['phone'] ?? '';
                }

                return Row(
                  children: [
                    // Call button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: phone.isEmpty
                            ? null
                            : () async {
                                final uri = Uri.parse('tel:$phone');
                                try {
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cannot place call'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Unable to call'),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.call),
                        label: Text(phone.isEmpty ? 'No Phone' : phone),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Picked Up button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            (req['riderId'] == userId &&
                                !(req['pickedUp'] as bool? ?? false))
                            ? () async {
                                await FirebaseFirestore.instance
                                    .collection('pickup_requests')
                                    .doc(docId)
                                    .update({
                                      'pickedUp': true,
                                      'pickedUpAt':
                                          FieldValue.serverTimestamp(),
                                    });
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Marked as picked up'),
                                    ),
                                  );
                              }
                            : null,
                        icon: const Icon(Icons.inventory),
                        label: Text(
                          (req['pickedUp'] as bool? ?? false)
                              ? 'Picked'
                              : 'Picked Up',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mark as Done button
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            (req['riderId'] == userId &&
                                (req['citizenConfirmed'] as bool? ?? false))
                            ? () => _markAsDone(docId)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          (req['citizenConfirmed'] as bool? ?? false)
                              ? 'Mark as Done'
                              : 'Awaiting Confirm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
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

    // Fetch pickup doc to get citizen id and phone, then update
    final docRef = FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId);
    final docSnap = await docRef.get();
    String? citizenId;
    if (docSnap.exists) {
      final data = docSnap.data() as Map<String, dynamic>?;
      citizenId = data?['userId'] as String?;
    }

    String citizenPhone = '';
    if (citizenId != null && citizenId.isNotEmpty) {
      final citizenDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(citizenId)
          .get();
      if (citizenDoc.exists) {
        final d = citizenDoc.data() as Map<String, dynamic>?;
        citizenPhone = d?['phone'] ?? '';
      }
    }

    await docRef.update({
      'status': 'accepted',
      'riderId': user.uid,
      'citizenPhone': citizenPhone,
      'acceptedAt': FieldValue.serverTimestamp(),
      'citizenConfirmed': false,
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pickup request accepted!")));
    }
  }

  Future<void> _markAsDone(String docId) async {
    // Ensure citizen has confirmed before allowing completion
    final docRef = FirebaseFirestore.instance
        .collection('pickup_requests')
        .doc(docId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    final citizenConfirmed = data['citizenConfirmed'] as bool? ?? false;
    if (!citizenConfirmed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Citizen must confirm before marking as done."),
          ),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    await docRef.update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'riderId': user?.uid,
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Marked as completed!")));
    }
  }
}
