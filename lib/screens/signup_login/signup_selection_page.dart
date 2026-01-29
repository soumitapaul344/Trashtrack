import 'package:flutter/material.dart';
import 'citizen_signup_page.dart';
import 'rider_signup_page.dart';
import 'cleaner_signup_page.dart';

class SignupSelectionPage extends StatelessWidget {
  const SignupSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.recycling,
                  size: 42,
                  color: Color(0xFF1AAE9F),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "TrashTrack",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Eco-friendly waste management.",
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 50),
              const Text(
                "Sign up as",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

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

              // Rider Signup (same green color)
              _signupButton(
                context,
                "🏍️ Register as Rider",
                const Color(0xFF138D75),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiderSignupPage()),
                ),
              ),
              const SizedBox(height: 15),

              // Cleaner Signup (same green color)
              _signupButton(
                context,
                "🧹 Register as Cleaner",
                const Color(0xFF138D75),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CleanerSignupPage()),
                ),
              ),
              const SizedBox(height: 30),

              // Back to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Log In",
                      style: TextStyle(
                        color: Color(0xFF138D75),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
