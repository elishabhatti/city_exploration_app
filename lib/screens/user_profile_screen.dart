import 'dart:convert';
import 'dart:io';

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

      if (response.statusCode != 200) {
        throw Exception('Cloudinary upload failed');
      }

      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      final imageUrl = jsonData['secure_url'];

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'preferences': {'profilePic': imageUrl},
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
      }
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Login Required")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final name = data['username'] ?? data['name'] ?? 'Explorer';

          final profilePic = data['preferences']?['profilePic'];

          return Column(
            children: [
              const SizedBox(height: 20),

              Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: profilePic != null
                        ? NetworkImage(profilePic)
                        : null,
                    child: profilePic == null
                        ? const Icon(Icons.person, size: 70)
                        : null,
                  ),

                  if (isUploading)
                    const Positioned.fill(child: CircularProgressIndicator()),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: isUploading ? null : _changeProfilePic,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
