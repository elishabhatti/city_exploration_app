import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  bool _isUploading = false;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _updateProfilePic() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      // 1. Cloudinary Upload Logic
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/dbqrxk5ya/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'city-app'
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);
      final String newImageUrl = jsonResponse['secure_url'];

      // 2. Firestore Update
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'profilePic': newImageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Picture Updated!")),
        );
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String? profilePic = userData['profilePic'];
        String name = userData['name'] ?? 'Admin';
        String email = userData['email'] ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Image Stack
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: profilePic != null
                        ? NetworkImage(profilePic)
                        : null,
                    child: profilePic == null
                        ? const Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.blueAccent,
                          )
                        : null,
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                      onPressed: _isUploading ? null : _updateProfilePic,
                    ),
                  ),
                  if (_isUploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 25),
              // Admin Info Cards
              _infoTile("Full Name", name, Icons.badge),
              _infoTile("Email Address", email, Icons.email),
              _infoTile("Account Role", "Administrator", Icons.security),
              const SizedBox(height: 30),

              const Text(
                "System Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text("Push Notifications"),
                trailing: Switch(value: true, onChanged: (v) {}),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
