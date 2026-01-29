import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// ignore_for_file: use_build_context_synchronously

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String selectedRole = "citizen";
  final List<String> roles = ["Citizen", "Rider", "Cleaner"];
  bool _isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final houseController = TextEditingController();
  final roadController = TextEditingController();
  final blockController = TextEditingController();
  final contactController = TextEditingController();

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
        houseController.text.isEmpty ||
        blockController.text.isEmpty ||
        contactController.text.isEmpty) {
      showSnackBar("Please fill all mandatory fields");
      return;
    }

    if (selectedRole != "citizen") {
      showSnackBar(
        "Rider and Cleaner accounts can only be created by the Administrator.",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await auth.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        house: houseController.text.trim(),
        road: roadController.text.trim(),
        block: blockController.text.trim(),
        contact: contactController.text.trim(),
        role: "citizen",
      );

      showSnackBar(
        "Verification link sent to your email. Please verify before login.",
        isError: false,
      );

      Navigator.pop(context); // 🔥 back to login page
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Account",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            signupField("Full Name", nameController, Icons.person_outlined),
            const SizedBox(height: 15),
            signupField("Email", emailController, Icons.email_outlined),
            const SizedBox(height: 15),
            signupField(
              "Password",
              passwordController,
              Icons.lock_outline,
              isPass: true,
            ),

            const SizedBox(height: 25),
            signupField("House No.", houseController, Icons.home_outlined),
            const SizedBox(height: 15),
            signupField("Road (Optional)", roadController, Icons.add_road_outlined),
            const SizedBox(height: 15),
            signupField("Block / Sector", blockController, Icons.grid_view),
            const SizedBox(height: 15),
            signupField("Contact Number", contactController, Icons.phone),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget signupField(
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
