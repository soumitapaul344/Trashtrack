import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Full-screen map page to track rider's live location
/// Shows real-time rider position from Firestore collection: riders
class CitizenTrackingPage extends StatefulWidget {
  final String riderId;

  const CitizenTrackingPage({super.key, required this.riderId});

  @override
  State<CitizenTrackingPage> createState() => _CitizenTrackingPageState();
}

class _CitizenTrackingPageState extends State<CitizenTrackingPage> {
  late GoogleMapController mapController;
  final Color primaryGreen = const Color(0xFF138D75);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Rider'),
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildMapWithTracking(),
    );
  }

  /// StreamBuilder to listen for real-time rider location updates
  Widget _buildMapWithTracking() {
    return StreamBuilder<DocumentSnapshot>(
      // Listen to riders/{riderId} document in Firestore
      stream: FirebaseFirestore.instance
          .collection('riders')
          .doc(widget.riderId)
          .snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryGreen),
                const SizedBox(height: 16),
                const Text('Connecting to rider...'),
              ],
            ),
          );
        }

        // Error handling
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text('Error loading rider location'),
              ],
            ),
          );
        }

        // No data or document doesn't exist
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_disabled,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text('Rider location not available yet'),
                const SizedBox(height: 8),
                const Text(
                  'Waiting for rider to share location...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Extract latitude and longitude from Firestore document
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        final lastUpdated = data['lastUpdated'] as Timestamp?;

        // Validate coordinates
        if (lat == null || lng == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.my_location_outlined,
                  size: 64,
                  color: Colors.yellow.shade700,
                ),
                const SizedBox(height: 16),
                const Text('Getting rider location...'),
              ],
            ),
          );
        }

        // Render map with rider marker
        return Stack(
          children: [
            // Google Map showing rider's location
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(lat, lng),
                zoom: 16,
              ),
              onMapCreated: (controller) {
                mapController = controller;
              },
              markers: {
                // Rider location marker
                Marker(
                  markerId: const MarkerId('rider_location'),
                  position: LatLng(lat, lng),
                  infoWindow: const InfoWindow(
                    title: 'Your Rider',
                    snippet: 'Current location',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              },
            ),
            // Location info card at bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Rider Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Latitude
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Latitude:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        Text(
                          lat.toStringAsFixed(6),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Longitude
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Longitude:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        Text(
                          lng.toStringAsFixed(6),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    if (lastUpdated != null) ...[
                      const SizedBox(height: 8),
                      // Last updated time
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Updated:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(lastUpdated.toDate()),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Format timestamp to readable time
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
