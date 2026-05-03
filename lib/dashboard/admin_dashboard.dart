import 'dart:convert';
import 'dart:io';

import 'package:city_exploration_app/screens/login_screen.dart';
import 'package:city_exploration_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openPlaceSheet(BuildContext context, {DocumentSnapshot? doc}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => AddPlaceFormSheet(doc: doc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Control Center",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "PLACES"),
            Tab(text: "USERS"),
            Tab(text: "REVIEWS"),
            Tab(text: "PROFILE"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ManagePlacesTab(),
          ManageUsersTab(),
          ManageReviewsTab(),
          AdminProfileTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) {
          return _tabController.index == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openPlaceSheet(context),
                  backgroundColor: Colors.black,
                  label: const Text(
                    "NEW ENTRY",
                    style: TextStyle(color: Colors.white),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}

class ManagePlacesTab extends StatelessWidget {
  const ManagePlacesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('places').snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (_, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return ListTile(
              leading: Image.network(
                data['image'] ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported),
              ),
              title: Text(data['name'] ?? 'Untitled'),
              subtitle: Text("${data['cityName']} • ${data['category']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => AddPlaceFormSheet(doc: doc),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.blue),
                  ),
                  IconButton(
                    onPressed: () => doc.reference.delete(),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AddPlaceFormSheet extends StatefulWidget {
  final DocumentSnapshot? doc;

  const AddPlaceFormSheet({super.key, this.doc});

  @override
  State<AddPlaceFormSheet> createState() => _AddPlaceFormSheetState();
}

class _AddPlaceFormSheetState extends State<AddPlaceFormSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();

  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.doc != null) {
      final data = widget.doc!.data() as Map<String, dynamic>;

      _nameController.text = data['name'] ?? '';
      _descController.text = data['description'] ?? '';
      _cityController.text = data['cityName'] ?? '';
      _existingImageUrl = data['image'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (_nameController.text.isEmpty || _cityController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = _existingImageUrl ?? '';

      if (_selectedImage != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/dbqrxk5ya/image/upload'),
        );

        request.fields['upload_preset'] = 'city-app';

        request.files.add(
          await http.MultipartFile.fromPath('file', _selectedImage!.path),
        );

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        final decoded = jsonDecode(responseBody);

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception(decoded.toString());
        }

        imageUrl = decoded['secure_url'];
      }

      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'cityName': _cityController.text.trim(),
        'cityId': _cityController.text.trim().toLowerCase(),
        'image': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.doc == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('places').add(data);
      } else {
        await widget.doc!.reference.update(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      debugPrint("SUBMIT ERROR: $e");
      debugPrintStack(stackTrace: stack);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (img != null) {
      setState(() => _selectedImage = File(img.path));
    }
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[200],
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : _existingImageUrl != null
                    ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo),
              ),
            ),
            const SizedBox(height: 20),
            _field(_nameController, "Place Name"),
            _field(_cityController, "City Name"),
            _field(_descController, "Description"),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitData,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageUsersTab extends StatelessWidget {
  const ManageUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Users Tab"));
  }
}

class ManageReviewsTab extends StatelessWidget {
  const ManageReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Reviews Tab"));
  }
}

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("No user logged in"));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.data!.exists) {
          return const Center(child: Text("User document not found"));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        return Center(
          child: Text(
            userData['name'] ?? 'Admin',
            style: const TextStyle(fontSize: 20),
          ),
        );
      },
    );
  }
}
