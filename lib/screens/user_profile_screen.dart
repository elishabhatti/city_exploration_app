import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    // 1. Gallery se image select karein
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Size kam rakhne ke liye
    );

    if (image == null) return;

    setState(() => isUploading = true);

    try {
      // 2. Firebase Storage mein upload karein
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_pics')
          .child('${user!.uid}.jpg');

      await ref.putFile(File(image.path));

      // 3. Image ka link (URL) hasil karein
      String downloadUrl = await ref.getDownloadURL();

      // 4. Firestore mein link save karein
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'profilePic': downloadUrl});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile Picture Updated!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isUploading = false);
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

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
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: profilePic != null
                                ? NetworkImage(profilePic)
                                : null,
                            child: profilePic == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
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
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                onPressed: _changeProfilePic,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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

                // Favorites Section Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
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

                // Favorites List
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
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!favSnapshot.hasData ||
                        favSnapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text("No favorites added yet!"),
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
                              ),
                            ),
                            title: Text(
                              fav['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () async {
                              var placeDoc = await FirebaseFirestore.instance
                                  .collection('places')
                                  .doc(fav.id)
                                  .get();
                              if (placeDoc.exists) {
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
