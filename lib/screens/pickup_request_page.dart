import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PickupRequestPage extends StatefulWidget {
  const PickupRequestPage({super.key});

  @override
  State<PickupRequestPage> createState() => _PickupRequestPageState();
}

class _PickupRequestPageState extends State<PickupRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedWasteType;
  String? _selectedTimeSlot;
  bool _isLoading = false;

  final List<String> _wasteTypes = [
    'Plastic',
    'Organic',
    'Paper',
    'Metal',
    'E-waste',
    'Others',
  ];

  final List<String> _timeSlots = [
    '8:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 2:00 PM',
    '2:00 PM - 4:00 PM',
    '4:00 PM - 6:00 PM',
    '6:00 PM - 8:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserAddress();
  }

  Future<void> _fetchUserAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        String addr = doc.data()!.containsKey('homeAddress')
            ? doc.get('homeAddress')
            : "${doc.get('house') ?? ''}, ${doc.get('road') ?? ''}, ${doc.get('block') ?? ''}";

        setState(() {
          _addressController.text = addr;
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() ||
        _selectedWasteType == null ||
        _selectedTimeSlot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save request in Firestore (all riders can see)
      await FirebaseFirestore.instance.collection('pickup_requests').add({
        'userId': user.uid,
        'userName': user.displayName ?? "Citizen",
        'wasteType': _selectedWasteType,
        'quantity': _quantityController.text,
        'address': _addressController.text,
        'timeSlot': _selectedTimeSlot,
        'status': 'pending',
        'riderId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup Request Submitted!'),
          backgroundColor: Color(0xFF138D75),
        ),
      );

      Navigator.pop(context, true); // Return true to refresh home
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF138D75);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        title: const Text(
          "Request Pickup",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Schedule a Pickup",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter details for the rider to collect your waste.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              const Text(
                "Waste Type",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedWasteType,
                decoration: _inputDecoration(
                  "Select waste type",
                  Icons.category,
                ),
                items: _wasteTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _selectedWasteType = val),
                validator: (val) => val == null ? 'Please select a type' : null,
              ),
              const SizedBox(height: 20),

              const Text(
                "Quantity / Notes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                decoration: _inputDecoration(
                  "Ex: 2 Bags, approx 5kg",
                  Icons.scale,
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Please enter quantity' : null,
              ),
              const SizedBox(height: 20),

              const Text(
                "Pickup Address",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration(
                  "Enter pickup address",
                  Icons.location_on,
                ),
                maxLines: 2,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 20),

              const Text(
                "Preferred Time Slot",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedTimeSlot,
                decoration: _inputDecoration(
                  "Select time slot",
                  Icons.access_time,
                ),
                items: _timeSlots.map((slot) {
                  return DropdownMenuItem(value: slot, child: Text(slot));
                }).toList(),
                onChanged: (val) => setState(() => _selectedTimeSlot = val),
                validator: (val) =>
                    val == null ? 'Please select a time slot' : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit Request",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
