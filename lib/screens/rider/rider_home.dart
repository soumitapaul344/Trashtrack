import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trashtrack/screens/homes/profile_page.dart';
import 'package:trashtrack/screens/rider/services/rider_location_service.dart';
import 'package:trashtrack/screens/rider/rider_tracking_page.dart';

part 'rider_home_home.dart';
part 'rider_home_history.dart';
part 'rider_ernings.dart';
part 'rider_home_nav.dart';
part 'rider_home_tracking.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  // Theme
  final Color primaryGreen = const Color(0xFF138D75);
  final Color scaffoldBg = const Color(0xFFF4F9F9);
  final Color cardColor = Colors.white;

  final RiderLocationService _locationService = RiderLocationService();

  int _currentIndex = 0;
  int _historyTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _locationService.startLocationUpdates(riderId: user.uid);
    }
  }

  @override
  void dispose() {
    _locationService.stopLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ---------------- BODY SWITCH ----------------
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildHistory();
      case 2:
        return _buildEarnings();
      case 3:
        return _buildTracking();
      case 4:
        return const ProfilePage();
      default:
        return _buildHome();
    }
  }
}
