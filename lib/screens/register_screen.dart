import 'package:city_exploration_app/dashboard/admin_register_screen.dart';
import 'package:city_exploration_app/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> register() async {
    // 1. Basic validation (Recommended)
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    try {
      final user = await AuthService().register(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'user',
        'profilePic': null,
        'preferences': {},
      });

      // 2. Redirect to Home Screen
      if (mounted) {
        // Check if widget is still in tree
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ), // Replace with your Home class name
          (route) => false, // This removes all previous routes from the stack
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Register Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Stack(
        // Stack use kiya hidden dot ke liye
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: register,
                  child: const Text("Register"),
                ),
              ],
            ),
          ),

          // Hidden Dot for Admin Registration
          Positioned(
            bottom: 50,
            right: 50,
            child: GestureDetector(
              onDoubleTap: () {
                // Double tap se secret open hoga
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminRegisterScreen(),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                color: Colors.transparent, // Nazar nahi aayega par wahan hoga
              ),
            ),
          ),
        ],
      ),
    );
  }
}
