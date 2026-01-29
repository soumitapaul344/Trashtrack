import 'package:flutter/material.dart';
import 'auth_selection_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAuth();
  }

  _navigateToAuth() async {
    await Future.delayed(const Duration(seconds: 3), () {});
    if (!mounted) return;
    // Always go to AuthSelectionPage, let auth pages handle routing
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthSelectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              Color(0xFFDFFFFA),
              Color(0xFFC9F7F0),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 80),

            /// Center Content
            Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x0D000000),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.recycling,
                      size: 42,
                      color: Color(0xFF1AAE9F),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'TrashTrack',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B2B2B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Smart Waste & Cleaning\nManagement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4A7F7A),
                    height: 1.4,
                  ),
                ),
              ],
            ),

            /// Bottom Loading
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: const Color(0xFFBDEFE7),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF1AAE9F),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'LOADING',
                  style: TextStyle(
                    letterSpacing: 3,
                    fontSize: 12,
                    color: Color(0xFF6BAFA8),
                  ),
                ),
                const SizedBox(height: 24),
            
              ],
            ),
          ],
        ),
      ),
    );
  }
}
