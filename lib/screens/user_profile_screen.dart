import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'place_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool isUploading = false;

  // Function: Pick and Upload Image
  Future<void> _changeProfilePic() async {
    final ImagePicker picker = ImagePicker();

    try {
      // 1. Gallery se image select karein
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Image size compress karne ke liye
      );

      // Agar user ne cancel kar diya
      if (image == null) return;

      setState(() => isUploading = true);

      // 2. Firebase Storage Reference
      // Path: profile_pics/USER_ID.jpg
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_pics')
          .child('${user!.uid}.jpg');

      // 3. Upload File
      await ref.putFile(File(image.path));

      // 4. Download URL hasil karein
      String downloadUrl = await ref.getDownloadURL();

      // 5. Firestore update karein
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'profilePic': downloadUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Picture Updated Successfully!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile"), elevation: 0),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return const Center(child: Text("User data not found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String? profilePic = userData['profilePic'];

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Profile Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                (profilePic != null && profilePic.isNotEmpty)
                                ? NetworkImage(profilePic)
                                : null,
                            child: (profilePic == null || profilePic.isEmpty)
                                ? const Icon(
                                    Icons.person,
                                    size: 65,
                                    color: Colors.blue,
                                  )
                                : null,
                          ),
                          if (isUploading)
                            const Positioned.fill(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                onPressed: isUploading
                                    ? null
                                    : _changeProfilePic,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        userData['name']?.toUpperCase() ?? "USER",
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? "",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Favorites Section Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        "My Favorites",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Favorites List Stream
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('favorites')
                      .orderBy('addedAt', descending: true)
                      .snapshots(),
                  builder: (context, favSnapshot) {
                    if (favSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(); // Smooth loading
                    }
                    if (!favSnapshot.hasData ||
                        favSnapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text("No favorite places yet."),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: favSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var fav = favSnapshot.data!.docs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                fav['image'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                            title: Text(
                              fav['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                            onTap: () async {
                              // Fetch full place data to pass to detail screen
                              var placeDoc = await FirebaseFirestore.instance
                                  .collection('places')
                                  .doc(fav.id)
                                  .get();
                              if (placeDoc.exists && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaceDetailScreen(
                                      placeId: fav.id,
                                      placeData:
                                          placeDoc.data()
                                              as Map<String, dynamic>,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
