import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool isUploading = false;

  static const String cloudName = 'dbqrxk5ya';
  static const String uploadPreset = 'city-app';

  // --- Success Notification ---
  void _showCleanNotification(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _changeProfilePic() async {
    if (user == null) return;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
    );

    if (image == null) return;
    setState(() => isUploading = true);

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      if (response.statusCode != 200) throw Exception('Upload failed');

      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      final imageUrl = jsonData['secure_url'];

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'preferences': {'profilePic': imageUrl},
      }, SetOptions(merge: true));

      if (mounted)
        _showCleanNotification("Profile picture updated successfully!", false);
    } catch (e) {
      if (mounted)
        _showCleanNotification("Upload failed: Check connection", true);
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null)
      return const Scaffold(body: Center(child: Text("Login Required")));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black54),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['username'] ?? data['name'] ?? 'Explorer';
          final email = data['email'] ?? user!.email ?? '';
          final profilePic = data['preferences']?['profilePic'];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // 1. Sleek Header Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.grey[50],
                              backgroundImage: profilePic != null
                                  ? NetworkImage(profilePic)
                                  : null,
                              child: profilePic == null
                                  ? Icon(
                                      Icons.person_outline,
                                      size: 65,
                                      color: Colors.grey[300],
                                    )
                                  : null,
                            ),
                          ),
                          if (isUploading)
                            const SizedBox(
                              height: 130,
                              width: 130,
                              child: CircularProgressIndicator(
                                color: Colors.blueAccent,
                                strokeWidth: 3,
                              ),
                            ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: isUploading ? null : _changeProfilePic,
                              child: CircleAvatar(
                                backgroundColor: Colors.black,
                                radius: 20,
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Divider(thickness: 1.5, color: Color(0xFFF5F5F5)),
                ),

                // 2. Favorites Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 25, 25, 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Favorites",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent.withOpacity(0.8),
                        size: 22,
                      ),
                    ],
                  ),
                ),

                // 3. Optimized Favorites List
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('favorites')
                      .snapshots(),
                  builder: (context, favSnapshot) {
                    if (!favSnapshot.hasData) return const SizedBox();
                    final favs = favSnapshot.data!.docs;

                    if (favs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "No favorites yet.",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: favs.length,
                      itemBuilder: (context, index) {
                        final fav = favs[index].data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade100,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                fav['image'] ?? '',
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              fav['name'] ?? 'Place',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              fav['city'] ?? 'City',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              onPressed: () => _removeFavorite(favs[index].id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeFavorite(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(docId)
        .delete();
  }
}
