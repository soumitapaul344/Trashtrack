part of 'rider_home.dart';

extension RiderHistorySection on _RiderHomeState {
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
        _historyTabIndex = index;
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
    String weight = req['quantity'] ?? "0";
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
}
