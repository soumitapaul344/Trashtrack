import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trashtrack/services/auth_service.dart';

import 'package:trashtrack/screens/homes/citizen_home.dart';
import 'package:trashtrack/screens/homes/rider_home.dart';
import 'package:trashtrack/screens/homes/cleaner_home.dart';
import 'package:trashtrack/screens/homes/admin_home.dart';
import 'signup_page.dart';
import 'verify_email_page.dart';

class LoginPage extends StatefulWidget {
  final String? prefillEmail;
  final String? prefillPassword;

  const LoginPage({
    super.key,
    this.prefillEmail,
    this.prefillPassword,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  final auth = AuthService();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.prefillEmail ?? '');
    passwordController = TextEditingController(text: widget.prefillPassword ?? '');
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  bool _obscurePassword = true;

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
      // 1️⃣ Sign in
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception("Login failed");

      // 2️⃣ Check email verification
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

      // 3️⃣ Get role from Firestore
      final role = await auth.getRole();
      if (role == null) {
        showMsg("User record not found in database.");
        return;
      }

      // 4️⃣ Navigate to correct home page
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
      } else if (e.code == 'email-not-verified') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
        );
        showMsg("Please verify your email first");
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
              customField("Email Address", emailController, Icons.email_outlined),
              const SizedBox(height: 15),
              customField(
                "Password",
                passwordController,
                Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),
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
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget customField(
    String hint,
    TextEditingController c,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: c,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}
