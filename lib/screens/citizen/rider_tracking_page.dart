import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// NOTE: Add your Google Maps API key in AndroidManifest.xml.
class RiderTrackingPage extends StatelessWidget {
  const RiderTrackingPage({super.key, required this.riderId});

  final String riderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Rider Tracking')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('riders')
            .doc(riderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Rider location not available.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();

          if (lat == null || lng == null) {
            return const Center(child: Text('Rider location not available.'));
          }

          final riderPosition = LatLng(lat, lng);

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: riderPosition,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('rider'),
                position: riderPosition,
                infoWindow: const InfoWindow(title: 'Rider'),
              ),
            },
          );
        },
      ),
    );
  }
}
