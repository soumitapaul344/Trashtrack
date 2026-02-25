import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trashtrack/screens/homes/profile_page.dart';

part 'rider_home_home.dart';
part 'rider_home_history.dart';
part 'rider_ernings.dart';
part 'rider_home_nav.dart';

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

  int _currentIndex = 0;
  int _historyTabIndex = 0;

  // Helpers to safely update state from extension methods
  void _changeIndex(int index) {
    setState(() => _currentIndex = index);
  }

  void _changeHistoryTab(int index) {
    setState(() => _historyTabIndex = index);
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
        return const ProfilePage();
      default:
        return _buildHome();
    }
  }
}
