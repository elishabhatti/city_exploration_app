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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Control Center",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
            fontSize: 24,
            letterSpacing: -1,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15, top: 8, bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          tabs: const [
            Tab(text: "PLACES", icon: Icon(Icons.map_outlined, size: 20)),
            Tab(text: "USERS", icon: Icon(Icons.group_outlined, size: 20)),
            Tab(
              text: "REVIEWS",
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 20),
            ),
            Tab(
              text: "PROFILE",
              icon: Icon(Icons.account_circle_outlined, size: 20),
            ),
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
        builder: (context, child) {
          return _tabController.index == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openPlaceSheet(context),
                  elevation: 0,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  label: const Text(
                    "NEW ENTRY",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  void _openPlaceSheet(BuildContext context, {DocumentSnapshot? doc}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => AddPlaceFormSheet(doc: doc),
    );
  }
}

// --- TAB 1: MANAGE PLACES ---
class ManagePlacesTab extends StatelessWidget {
  const ManagePlacesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('places').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data['image'] ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[50],
                      width: 60,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                title: Text(
                  data['name'] ?? 'Untitled',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  "${data['cityName']} • ${data['category']}",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => AddPlaceFormSheet(doc: doc),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _confirmDelete(context, doc),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Entry?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This information will be permanently removed from the database.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              doc.reference.delete();
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// --- ADD/EDIT FORM SHEET ---
class AddPlaceFormSheet extends StatefulWidget {
  final DocumentSnapshot? doc;
  const AddPlaceFormSheet({super.key, this.doc});

  @override
  State<AddPlaceFormSheet> createState() => _AddPlaceFormSheetState();
}

class _AddPlaceFormSheetState extends State<AddPlaceFormSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _ratingController = TextEditingController();
  final _timingController = TextEditingController();
  final _cityNameController = TextEditingController();
  final _categoryController = TextEditingController();

  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.doc != null) {
      var data = widget.doc!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _descController.text = data['description'] ?? '';
      _ratingController.text = data['rating'] ?? '';
      _timingController.text = data['timings'] ?? '';
      _cityNameController.text = data['cityName'] ?? '';
      _categoryController.text = data['category'] ?? '';
      _existingImageUrl = data['image'];
    }
  }

  Future<void> _submitData() async {
    if (_nameController.text.isEmpty || _cityNameController.text.isEmpty)
      return;
    setState(() => _isLoading = true);
    try {
      String finalImageUrl = _existingImageUrl ?? '';
      if (_selectedImage != null) {
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
        finalImageUrl = jsonDecode(responseData)['secure_url'];
      }

      Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'image': finalImageUrl,
        'category': _categoryController.text.trim(),
        'rating': _ratingController.text.trim(),
        'timings': _timingController.text.trim(),
        'cityName': _cityNameController.text.trim(),
        'cityId': _cityNameController.text.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.doc == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('places').add(data);
      } else {
        await widget.doc!.reference.update(data);
      }
      Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 25,
        right: 25,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.doc == null ? "ADD NEW PLACE" : "EDIT PLACE",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: () async {
                final img = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 50,
                );
                if (img != null)
                  setState(() => _selectedImage = File(img.path));
              },
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100, width: 2),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : (_existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.add_a_photo_outlined,
                              color: Colors.grey[300],
                              size: 40,
                            )),
              ),
            ),
            const SizedBox(height: 25),
            _field(_nameController, "Place Name", Icons.title),
            _field(_cityNameController, "City Name", Icons.location_city),
            _field(_categoryController, "Category", Icons.category_outlined),
            _field(_descController, "Description", Icons.notes, lines: 3),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 60),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "SAVE DATA",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: Colors.black),
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade100, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// --- TAB 2: MANAGE USERS ---
class ManageUsersTab extends StatelessWidget {
  const ManageUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade100),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[100],
                  child: const Icon(Icons.person_outline, color: Colors.black),
                ),
                title: Text(
                  data['name'] ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(data['email'] ?? ''),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['role']?.toUpperCase() ?? 'USER',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- TAB 3: MANAGE REVIEWS ---
class ManageReviewsTab extends StatelessWidget {
  const ManageReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('reviews').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty)
          return const Center(child: Text("No reviews yet."));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade100),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(
                  "\"${data['comment']}\"",
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  "${data['stars']} ⭐",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.redAccent,
                  ),
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

// --- TAB 4: ADMIN PROFILE ---
class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  bool _isUploading = false;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _updateProfilePic() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/dbqrxk5ya/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'city-app'
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final String newImageUrl = jsonDecode(responseData)['secure_url'];

      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'profilePic': newImageUrl,
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[50],
                      backgroundImage: userData['profilePic'] != null
                          ? NetworkImage(userData['profilePic'])
                          : null,
                      child: userData['profilePic'] == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.black,
                            )
                          : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isUploading ? null : _updateProfilePic,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black,
                      child: _isUploading
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _profileCard(
                "Name",
                userData['name'] ?? 'Admin',
                Icons.badge_outlined,
              ),
              _profileCard(
                "Email",
                userData['email'] ?? '',
                Icons.alternate_email,
              ),
              _profileCard(
                "Status",
                "System Administrator",
                Icons.verified_user_outlined,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileCard(String title, String val, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                val,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
