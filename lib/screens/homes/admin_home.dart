import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final contactController = TextEditingController();
  final blockController = TextEditingController();
  final roadController = TextEditingController();

  final auth = AuthService();

  String selectedStaffRole = "rider";
  bool _isLoading = false;

  // Show message function
  void showMsg(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Register staff function
  void registerStaff() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      showMsg("Please fill name and email");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await auth.createStaffAccount(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        house: addressController.text.trim(),
        road: roadController.text.trim(), // optional
        block: blockController.text.trim(), // optional
        contact: contactController.text.trim(), // optional
        role: selectedStaffRole,
      );

      showMsg("Account created for $selectedStaffRole!", isError: false);

      // Clear all fields after success
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      addressController.clear();
      roadController.clear();
      blockController.clear();
      contactController.clear();
    } catch (e) {
      showMsg(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color(0xFF138D75),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Register New Staff",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Role selection dropdown
            DropdownButtonFormField<String>(
              value: selectedStaffRole, // ignore: deprecated_member_use
              decoration: const InputDecoration(labelText: "Select Role"),
              items: ["rider", "cleaner"]
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(role.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedStaffRole = val!),
            ),
            const SizedBox(height: 15),

            // Input fields
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "House"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: roadController,
              decoration: const InputDecoration(labelText: "Road (optional)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: blockController,
              decoration: const InputDecoration(labelText: "Block (optional)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(
                labelText: "Contact (optional)",
              ),
            ),
            const SizedBox(height: 30),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : registerStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF138D75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      )
                    : const Text(
                        "Register Staff",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
