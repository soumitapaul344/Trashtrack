import 'package:flutter/material.dart';
import 'package:trashtrack/services/auth_service.dart';

class RiderSignupPage extends StatefulWidget {
  const RiderSignupPage({super.key});

  @override
  State<RiderSignupPage> createState() => _RiderSignupPageState();
}

class _RiderSignupPageState extends State<RiderSignupPage> {
  bool _isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final contactController = TextEditingController();
  String selectedVehicleType = 'bike';
  final vehicleNumberController = TextEditingController();
  final nidController = TextEditingController();
  final drivingLicenseController = TextEditingController();

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
        contactController.text.isEmpty ||
        selectedVehicleType.isEmpty ||
        vehicleNumberController.text.isEmpty ||
        nidController.text.isEmpty ||
        drivingLicenseController.text.isEmpty) {
      showSnackBar("Please fill all mandatory fields for Rider");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await auth.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        house: 'N/A',
        road: null,
        block: 'N/A',
        contact: contactController.text.trim(),
        role: "rider",
        nid: nidController.text.trim(),
        vehicleType: selectedVehicleType.trim(),
        vehicleNumber: vehicleNumberController.text.trim(),
        drivingLicense: drivingLicenseController.text.trim(),
      );

      if (!mounted) return;
      showSnackBar(
        "Registration successful! Pending admin approval. Check your email for verification.",
        isError: false,
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnackBar(e.toString());
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
              child: Icon(Icons.recycling, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 14),
            const Text(
              "Register as Rider",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Join as a waste collection rider",
              style: TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            _signupField("Full Name", nameController, Icons.person_outlined),
            const SizedBox(height: 15),
            // Vehicle Type dropdown with bike icon
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonFormField<String>(
                value: selectedVehicleType,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.directions_bike),
                ),
                items: const [
                  DropdownMenuItem(value: 'bike', child: Text('Bike')),
                  DropdownMenuItem(value: 'van', child: Text('Van')),
                  DropdownMenuItem(value: 'truck', child: Text('Truck')),
                ],
                onChanged: (val) =>
                    setState(() => selectedVehicleType = val ?? 'bike'),
              ),
            ),
            const SizedBox(height: 15),
            _signupField(
              "Vehicle Number",
              vehicleNumberController,
              Icons.confirmation_number,
            ),
            const SizedBox(height: 15),
            _signupField("National ID (NID)", nidController, Icons.badge),
            const SizedBox(height: 15),
            _signupField(
              "Driving License Number",
              drivingLicenseController,
              Icons.card_membership,
            ),
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
            const SizedBox(height: 5),
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
