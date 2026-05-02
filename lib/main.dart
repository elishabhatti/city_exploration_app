import 'dart:io';
import 'package:city_exploration_app/dashboard/admin_dashboard.dart';
import 'package:city_exploration_app/screens/home_screen.dart';
import 'package:city_exploration_app/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- Poppins ke liye zaroori import

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Platform.isLinux) {
      debugPrint("Warning: Firebase Linux configuration missing.");
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
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
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // Aapka minimalist clean look
        // --- GLOBAL POPPINS CONFIGURATION ---
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: Colors.black, // Default text color black set kiya
              displayColor: Colors.black,
            ),

        // Color scheme setup
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          surface: Colors.white,
        ),

        // Buttons ke liye bhi Poppins font weight optimize kar di
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        if (snapshot.hasData) {
          final String uid = snapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
                );
              }

              if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                var userData =
                    roleSnapshot.data!.data() as Map<String, dynamic>;
                String role = userData['role'] ?? 'user';

                if (role == 'admin') {
                  return const AdminDashboard();
                } else {
                  return const HomeScreen();
                }
              }
              return const LoginScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
