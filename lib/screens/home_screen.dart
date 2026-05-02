import 'package:city_exploration_app/screens/category_screen.dart';
import 'package:city_exploration_app/screens/faqs_screen.dart';
import 'package:city_exploration_app/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // User ka data lane ke liye
  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data();
  }

  // Database se Cities lane ke liye (Ye tumhara "Table" fetch kar raha hai)
  Stream<QuerySnapshot> getCitiesStream() {
    return FirebaseFirestore.instance.collection('cities').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select City"),
        actions: [
          // --- FAQ Link Yahan Add Kiya Hai ---
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: "FAQs",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FAQScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            onPressed: () async => await AuthService().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome Section
          FutureBuilder(
            future: getUserData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 50);
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Hello, ${snapshot.data!['name']}! Where are you going?",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),

          // Cities List (The Table Data)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getCitiesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No cities added in Firestore yet."),
                  );
                }

                final cityDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: cityDocs.length,
                  itemBuilder: (context, index) {
                    var city = cityDocs[index].data() as Map<String, dynamic>;
                    String cityId = cityDocs[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(city['image'] ?? ''),
                        ),
                        title: Text(city['name'] ?? 'Unknown'),
                        subtitle: Text(city['description'] ?? ''),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Next Screen: Categories
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryScreen(
                                cityId: cityId,
                                cityName: city['name'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
