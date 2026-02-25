part of 'rider_home.dart';

extension RiderHistorySection on _RiderHomeState {
  String _validPhone(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final regex = RegExp(r'^\+?\d{10,15}$');
    return regex.hasMatch(cleaned) ? cleaned : '';
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
      onTap: () => _changeHistoryTab(index),
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickup_requests')
          .where('riderId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // FILTER LOGIC
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String status = data['status']?.toString().toLowerCase() ?? 'pending';
          
          if (_historyTabIndex == 0) {
            // "Accepted" tab should show both accepted and picked_up
            return status == 'accepted' || status == 'picked_up';
          } else {
            // "Completed" tab
            return status == 'completed';
          }
        }).toList();

        String emptyMsg = _historyTabIndex == 1
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
    String weight = req['quantity'] ?? "0";
    final validPhone = _validPhone(req['phone']?.toString());
    String status = req['status']?.toString().toLowerCase() ?? 'accepted';

    // Condition to enable/disable button
    bool isPickedUp = status == 'picked_up';

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
                      (() {
                        final code = docId.length >= 6
                            ? docId.substring(0, 6).toUpperCase()
                            : docId.toUpperCase();
                        return 'REQ-$code';
                      })(),
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
                  "৳50",
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
          if (validPhone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('tel:$validPhone');
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cannot place call')),
                        );
                      }
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to call')),
                      );
                    }
                  },
                  icon: const Icon(Icons.call),
                  label: Text(validPhone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),

          // BUTTON LOGIC: Changes text and color based on Citizen confirmation
          if (status != 'completed')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isPickedUp ? () => _markAsDone(docId) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPickedUp ? Colors.blue : Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isPickedUp ? "Mark as Done" : "Waiting for Citizen Confirmation",
                    style: TextStyle(
                      fontSize: 12,
                      color: isPickedUp ? Colors.white : Colors.grey.shade600,
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
}