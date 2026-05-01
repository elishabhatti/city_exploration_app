import 'dart:io';
import 'package:city_exploration_app/dashboard/admin_dashboard.dart';
import 'package:city_exploration_app/screens/home_screen.dart';
import 'package:city_exploration_app/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Agar Linux hai aur config nahi hai, toh app crash hone se bachegi
    if (Platform.isLinux) {
      print(
        "Warning: Firebase is not fully configured for Linux in firebase_options.dart",
      );
      // Agar aapne Linux config add nahi ki, toh initializeApp() bina options ke try karein
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
    // Fallback initialization
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'City Guide',
      theme: ThemeData(
        useMaterial3: true, // Modern UI ke liye
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, // City app ke liye blue behtar lagta hai
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Check if Connection is Waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Agar User Logged In hai
        if (snapshot.hasData) {
          final String uid = snapshot.data!.uid;

          // Role check karne ke liye Firestore call
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                var userData =
                    roleSnapshot.data!.data() as Map<String, dynamic>;
                String role = userData['role'] ?? 'user';

                // Admin check logic
                if (role == 'admin') {
                  return const AdminDashboard(); // Admin screen par bhejo
                } else {
                  return const HomeScreen(); // Normal user par bhejo
                }
              }

              // Fallback agar Firestore data na mile (Security check)
              return const LoginScreen();
            },
          );
        }

        // 3. Agar User Login nahi hai
        return const LoginScreen();
      },
    );
  }
}
