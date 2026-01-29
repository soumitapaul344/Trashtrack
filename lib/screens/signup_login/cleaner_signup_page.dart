import 'package:flutter/material.dart';
import 'package:trashtrack/services/auth_service.dart';

class CleanerSignupPage extends StatefulWidget {
  const CleanerSignupPage({super.key});

  @override
  State<CleanerSignupPage> createState() => _CleanerSignupPageState();
}

class _CleanerSignupPageState extends State<CleanerSignupPage> {
  bool _isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final workAreaController = TextEditingController();
  final contactController = TextEditingController();
  final nidController = TextEditingController();

  final auth = AuthService();

  void showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        workAreaController.text.isEmpty ||
        nidController.text.isEmpty) {
      showSnackBar("Please fill all mandatory fields for Cleaner");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await auth.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        house: workAreaController.text.trim(),
        road: null,
        block: workAreaController.text.trim(),
        contact: contactController.text.trim(),
        role: "cleaner",
        nid: nidController.text.trim(),
      );

      showSnackBar(
        "Registration successful! Pending admin approval. Check your email for verification.",
        isError: false,
      );

      Navigator.pop(context);
    } catch (e) {
      showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.green,
              child: Icon(Icons.cleaning_services, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 14),
            const Text(
              "Register as Cleaner",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Join as a verified waste cleaner",
              style: TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            _signupField("Full Name", nameController, Icons.person_outlined),
            const SizedBox(height: 15),
            _signupField("Work Area/Zone", workAreaController, Icons.location_on_outlined),
            const SizedBox(height: 15),
            _signupField("National ID (NID)", nidController, Icons.badge),
            const SizedBox(height: 15),
            _signupField("Email", emailController, Icons.email_outlined),
            const SizedBox(height: 15),
            _signupField(
              "Password",
              passwordController,
              Icons.lock_outline,
              isPass: true,
            ),
            const SizedBox(height: 15),
            _signupField("Contact Number", contactController, Icons.phone),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Register",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _signupField(
    String hint,
    TextEditingController c,
    IconData icon, {
    bool isPass = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: c,
        obscureText: isPass,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}
