import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'homes/citizen_home.dart';

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

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // New Address Specific Controllers
  final houseController = TextEditingController();
  final roadController = TextEditingController(); // Optional
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
    // Validation: Check if mandatory fields are empty
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
      // Logic: Passing individual address fields to AuthService
      await auth.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        house: houseController.text.trim(),
        road: roadController.text.trim(), // Optional field
        block: blockController.text.trim(),
        contact: contactController.text.trim(),
        role: "citizen",
      );

      showSnackBar("Account Created!", isError: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CitizenHomePage()),
      );
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

            // Role Selection UI
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: roles.map((r) {
                  bool isSelected = selectedRole == r.toLowerCase();
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => selectedRole = r.toLowerCase()),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE0F2F1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            r,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF138D75)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 25),

            // Basic Info
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
            const Text(
              "Address Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 15),

            // New Specific Address Fields
            signupField(
              "House No. / Name",
              houseController,
              Icons.home_outlined,
            ),
            const SizedBox(height: 15),
            signupField(
              "Road No. (Optional)",
              roadController,
              Icons.add_road_outlined,
            ),
            const SizedBox(height: 15),
            signupField(
              "Block / Sector",
              blockController,
              Icons.grid_view_rounded,
            ),
            const SizedBox(height: 15),
            signupField(
              "Contact Number",
              contactController,
              Icons.phone_android_outlined,
            ),

            const SizedBox(height: 35),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF138D75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Register",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
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
          prefixIcon: Icon(icon, color: const Color(0xFF138D75)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}
