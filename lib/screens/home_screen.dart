import 'package:city_exploration_app/screens/category_screen.dart';
import 'package:city_exploration_app/screens/faqs_screen.dart';
import 'package:city_exploration_app/screens/login_screen.dart';
import 'package:city_exploration_app/screens/user_profile_screen.dart';
import 'package:city_exploration_app/screens/user_guide_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Safe User Data Fetching (Fixes the Null Check Error)
  Future<Map<String, dynamic>?> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null; // Safety check

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  Stream<QuerySnapshot> getCitiesStream() {
    return FirebaseFirestore.instance.collection('cities').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white for that clean look
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Custom Premium Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 15, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder(
                    future: getUserData(),
                    builder: (context, snapshot) {
                      String name = snapshot.data?['name'] ?? "Explorer";
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, $name 👋",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            "Discover Cities",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Row(
                    children: [
                      _headerIcon(
                        Icons.help_outline,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FAQScreen()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _headerIcon(
                        Icons.person_outline,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Quick Action Buttons (User Guide) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserGuideScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map_outlined, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "New here? See how to use the app",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.blueAccent,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Text(
                "Popular Locations",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // --- Cities List ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getCitiesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No cities found. Stay tuned!"),
                    );
                  }

                  final cityDocs = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    physics: const BouncingScrollPhysics(),
                    itemCount: cityDocs.length,
                    itemBuilder: (context, index) {
                      var city = cityDocs[index].data() as Map<String, dynamic>;
                      String cityId = cityDocs[index].id;

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryScreen(
                              cityId: cityId,
                              cityName: city['name'],
                            ),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade100,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // City Image
                              Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(18),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(city['image'] ?? ''),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // City Details
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        city['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        city['description'] ?? '',
                                        maxLines: 2,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                          height: 1.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Floating Logout for a clean look
      floatingActionButton: FloatingActionButton.small(
        onPressed: () async {
          await AuthService().logout();
          if (context.mounted) {
            // <--- Safety check for context
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) =>
                  false, // Is se saari purani screens (back stack) clear ho jayengi
            );
          }
        },
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        elevation: 0,
        shape: CircleBorder(
          side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
        ),
        child: const Icon(Icons.logout, color: Colors.redAccent),
      ),
    );
  }

  // Helper widget for clean header icons
  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black, size: 22),
        onPressed: onTap,
      ),
    );
  }
}
