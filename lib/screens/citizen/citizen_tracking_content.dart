import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CitizenTrackingContent {
  static Widget buildTracking(BuildContext context, Color primaryGreen) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pickup_requests')
            .where('userId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'accepted')
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 60,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No active pickup\nRider location will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final request =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final riderId = request['riderId'] as String?;

          if (riderId == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('Rider info not available'),
              ),
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('riders')
                .doc(riderId)
                .snapshots(),
            builder: (context, riderSnapshot) {
              if (riderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!riderSnapshot.hasData || !riderSnapshot.data!.exists) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('Rider location not available yet'),
                  ),
                );
              }

              final data = riderSnapshot.data!.data() as Map<String, dynamic>;
              final lat = (data['latitude'] as num?)?.toDouble();
              final lng = (data['longitude'] as num?)?.toDouble();

              if (lat == null || lng == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('Waiting for rider location...'),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Rider Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          markerId: const MarkerId('rider'),
                          position: LatLng(lat, lng),
                          infoWindow: const InfoWindow(title: 'Your Rider'),
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
    );
  }
}
