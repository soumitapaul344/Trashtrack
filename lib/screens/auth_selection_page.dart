import 'package:flutter/material.dart';
import 'citizen_signup_page.dart';
import 'rider_signup_page.dart';
import 'cleaner_signup_page.dart';
import 'admin_login_page.dart';
import 'login_page.dart';

class AuthSelectionPage extends StatelessWidget {
  const AuthSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
          child: Column(
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.recycling,
                  size: 50,
                  color: Color(0xFF1AAE9F),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "TrashTrack",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Eco-friendly waste management.",
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 60),

              // Citizen Signup
              _signupButton(
                context,
                "👤 Register as Citizen",
                const Color(0xFF138D75),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CitizenSignupPage()),
                ),
              ),
              const SizedBox(height: 15),

              // Rider Signup
              _signupButton(
                context,
                "🏍️ Register as Rider",
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiderSignupPage()),
                ),
              ),
              const SizedBox(height: 15),

              // Cleaner Signup
              _signupButton(
                context,
                "🧹 Register as Cleaner",
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CleanerSignupPage()),
                ),
              ),
              const SizedBox(height: 15),

              // Login Button
              _signupButton(
                context,
                "🔑 Existing User Login",
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),

              // Admin Access Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "🛡️ Admin Access",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signupButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
