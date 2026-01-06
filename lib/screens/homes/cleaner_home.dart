import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CleanerHome extends StatelessWidget {
  const CleanerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cleaner Dashboard"),
        backgroundColor: const Color(0xFF138D75),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(
                context,
                '/login',
              ); // Adjust based on your routes
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 80, color: Color(0xFF138D75)),
            const SizedBox(height: 20),
            const Text(
              "Welcome to the Cleaner Portal",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Here you can see assigned waste collection tasks."),
            ),
          ],
        ),
      ),
    );
  }
}
