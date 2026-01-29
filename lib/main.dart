import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'firebase_options.dart';
import 'package:trashtrack/screens/splash_screen.dart';
import 'package:trashtrack/screens/signup_login/auth_selection_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAGON-8BOS6kcarEc5YZfCzL9McGNxVSS4',
      appId: '1:657599895308:android:e15824ce0ef8d270349b29',
      messagingSenderId: '657599895308',
      projectId: 'trashtrack-a438d',
      storageBucket: 'trashtrack-a438d.firebasestorage.app',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthSelectionPage(),
      },
    );
  }
}
