import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// --- Admin Dashboard Main ---
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Admin Command Center",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Places", icon: Icon(Icons.map_rounded)),
            Tab(text: "Users", icon: Icon(Icons.supervised_user_circle)),
            Tab(text: "Reviews", icon: Icon(Icons.reviews_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ManagePlacesTab(),
          const ManageUsersTab(),
          const ManageReviewsTab(),
        ],
      ),
      // FAB sirf tab 0 (Places) par dikhega logic ke liye hum controller check karte hain
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return _tabController.index == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openAddPlaceSheet(context),
                  label: const Text("Add New Place"),
                  icon: const Icon(Icons.add_location_alt_rounded),
                  backgroundColor: Colors.blueAccent,
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  void _openAddPlaceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const AddPlaceFormSheet(),
    );
  }
}

// --- Tab 1: Manage Places (Card Design) ---
class ManagePlacesTab extends StatelessWidget {
  const ManagePlacesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('places').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    data['image'] ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  data['name'] ?? 'Place',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("${data['category']} • ⭐ ${data['rating']}"),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDelete(context, doc.reference),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Place?"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// --- Tab 2: Manage Users (Simple & Clean) ---
class ManageUsersTab extends StatelessWidget {
  const ManageUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (c, i) => const Divider(),
          itemBuilder: (context, index) {
            var data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                backgroundImage: data['preferences']?['profilePic'] != null
                    ? NetworkImage(data['preferences']['profilePic'])
                    : null,
                child: data['preferences']?['profilePic'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(
                data['username'] ?? 'Anonymous',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(data['email'] ?? 'No Email'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['role'] ?? 'User',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Tab 3: Manage Reviews (Moderation Mode) ---
class ManageReviewsTab extends StatelessWidget {
  const ManageReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('reviews').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Card(
              color: Colors.amber.shade50,
              elevation: 0,
              child: ListTile(
                title: Text(
                  "\"${data['comment']}\"",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                subtitle: Text("Rating: ${data['stars']} ⭐"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.orange),
                  onPressed: () => doc.reference.delete(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Cloudinary Add Place Form (The Logic You Needed) ---
class AddPlaceFormSheet extends StatefulWidget {
  const AddPlaceFormSheet({super.key});

  @override
  State<AddPlaceFormSheet> createState() => _AddPlaceFormSheetState();
}

class _AddPlaceFormSheetState extends State<AddPlaceFormSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _ratingController = TextEditingController(text: "4.5");
  final _categoryController = TextEditingController(); // e.g. Attractions
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<void> _submitData() async {
    if (_selectedImage == null || _nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // 1. Upload to Cloudinary
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/dbqrxk5ya/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'city-app'
        ..files.add(
          await http.MultipartFile.fromPath('file', _selectedImage!.path),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final imageUrl = jsonDecode(responseData)['secure_url'];

      // 2. Save to Firestore using your Model structure
      await FirebaseFirestore.instance.collection('places').add({
        'name': _nameController.text,
        'description': _descController.text,
        'image': imageUrl,
        'rating': _ratingController.text,
        'category': _categoryController.text,
        'cityId': 'YOUR_CITY_ID', // Isay dynamic bhi kar sakte hain
        'timings': '9:00 AM - 6:00 PM',
        'contact': '+92 000 0000',
        'mapUrl': '',
        'website': '',
      });

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add New City Spot",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickAndUpload,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Icon(
                        Icons.add_a_photo,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Place Name"),
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: "Category (e.g. Restaurants)",
              ),
            ),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Save Place"),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
