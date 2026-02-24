part of 'rider_home.dart';

extension RiderTrackingSection on _RiderHomeState {
  Widget _buildTracking() {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pickup_requests')
                  .where('riderId', isEqualTo: user?.uid)
                  .where('status', isEqualTo: 'accepted')
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'No active pickup to track',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                final request =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
                final citizenId = request['userId'] as String?;

                if (citizenId == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('Citizen info not available'),
                    ),
                  );
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('citizens')
                      .doc(citizenId)
                      .snapshots(),
                  builder: (context, citSnapshot) {
                    if (citSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!citSnapshot.hasData || !citSnapshot.data!.exists) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('Citizen location not available yet'),
                        ),
                      );
                    }

                    final data =
                        citSnapshot.data!.data() as Map<String, dynamic>;
                    final lat = (data['latitude'] as num?)?.toDouble();
                    final lng = (data['longitude'] as num?)?.toDouble();

                    if (lat == null || lng == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('Waiting for citizen location...'),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Citizen Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(lat, lng),
                              zoom: 16,
                            ),
                            onMapCreated: (controller) {},
                            markers: {
                              Marker(
                                markerId: const MarkerId('citizen'),
                                position: LatLng(lat, lng),
                                infoWindow: const InfoWindow(
                                  title: 'Citizen Location',
                                ),
                              ),
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
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
                                'Latitude: ${lat.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Longitude: ${lng.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
