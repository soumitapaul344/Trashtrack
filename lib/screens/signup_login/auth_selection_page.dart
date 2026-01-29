import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_selection_page.dart';
import 'admin_login_page.dart';
import 'verify_email_page.dart';
import 'package:trashtrack/screens/homes/citizen_home.dart';
import 'package:trashtrack/screens/homes/rider_home.dart';
import 'package:trashtrack/screens/homes/cleaner_home.dart';
import 'package:trashtrack/screens/homes/admin_home.dart';
import 'package:trashtrack/services/auth_service.dart';

class AuthSelectionPage extends StatefulWidget {
  const AuthSelectionPage({super.key});

  @override
  State<AuthSelectionPage> createState() => _AuthSelectionPageState();
}

class _AuthSelectionPageState extends State<AuthSelectionPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final auth = AuthService();

  void showMsg(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showMsg("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in with email and password
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception("Login failed");

      // Check email verification
      await user.reload();
      if (!user.emailVerified) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
        );
        showMsg("Please verify your email first");
        return;
      }

      // Get role from Firestore
      final role = await auth.getRole();
      if (role == null) {
        showMsg("User record not found in database.");
        return;
      }

      // Navigate to correct home page
      Widget nextHome;

      if (role == "citizen") {
        nextHome = const CitizenHomePage();
      } else if (role == "rider") {
        nextHome = const RiderHome();
      } else if (role == "cleaner") {
        nextHome = const CleanerHome();
      } else if (role == "admin") {
        nextHome = const AdminHome();
      } else {
        showMsg("User role not recognized.");
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextHome),
      );

      showMsg("Login Successful!", isError: false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showMsg("No user found.");
      } else if (e.code == 'wrong-password') {
        showMsg("Wrong password.");
      } else if (e.code == 'pending-approval') {
        showMsg("Your account is pending admin approval. Please check back later.");
      } else {
        showMsg(e.message ?? "Login error");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
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
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Eco-friendly waste management.",
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 50),

              // Email field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: "Email Address",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(18),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Password field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(18),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Log In Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF138D75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Log In",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupSelectionPage(),
                      ),
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Color(0xFF138D75),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Admin Panel Link
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                ),
                child: const Text(
                  "Admin Panel",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
