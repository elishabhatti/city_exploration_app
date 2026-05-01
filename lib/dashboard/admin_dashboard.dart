import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "City Guide Admin",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: "Places", icon: Icon(Icons.location_on)),
            Tab(text: "Users", icon: Icon(Icons.group)),
            Tab(text: "Reviews", icon: Icon(Icons.comment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ManagePlacesTab(),
          ManageUsersTab(),
          ManageReviewsTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return _tabController.index == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openPlaceSheet(
                    context,
                  ), // Null pass kiya matlab ADD mode
                  label: const Text("Add New Place"),
                  icon: const Icon(Icons.add),
                  backgroundColor: Colors.blueAccent,
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  // Common function for Add and Edit
  void _openPlaceSheet(BuildContext context, {DocumentSnapshot? doc}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => AddPlaceFormSheet(doc: doc),
    );
  }
}

// --- ADD / EDIT PLACE FORM ---
class AddPlaceFormSheet extends StatefulWidget {
  final DocumentSnapshot? doc; // Agar doc null nahi hai, toh Edit mode hai
  const AddPlaceFormSheet({super.key, this.doc});

  @override
  State<AddPlaceFormSheet> createState() => _AddPlaceFormSheetState();
}

class _AddPlaceFormSheetState extends State<AddPlaceFormSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _ratingController = TextEditingController();
  final _timingController = TextEditingController();
  final _contactController = TextEditingController();
  final _mapUrlController = TextEditingController();
  final _webController = TextEditingController();
  final _cityNameController = TextEditingController();
  final _categoryController = TextEditingController();

  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Agar Edit mode hai, toh purana data load karo
    if (widget.doc != null) {
      var data = widget.doc!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _descController.text = data['description'] ?? '';
      _ratingController.text = data['rating'] ?? '';
      _timingController.text = data['timings'] ?? '';
      _contactController.text = data['contact'] ?? '';
      _mapUrlController.text = data['mapUrl'] ?? '';
      _webController.text = data['website'] ?? '';
      _cityNameController.text = data['cityName'] ?? '';
      _categoryController.text = data['category'] ?? '';
      _existingImageUrl = data['image'];
    }
  }

  Future<void> _submitData() async {
    if (_nameController.text.isEmpty || _cityNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and City are required!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String finalImageUrl = _existingImageUrl ?? '';

      // 1. Agar nayi image select ki hai toh upload karo
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
        final jsonResponse = jsonDecode(responseData);
        finalImageUrl = jsonResponse['secure_url'];
      }

      String formattedCityId = _cityNameController.text.trim().toLowerCase();
      Map<String, dynamic> placeData = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'image': finalImageUrl,
        'category': _categoryController.text.trim(),
        'rating': _ratingController.text.trim(),
        'timings': _timingController.text.trim(),
        'contact': _contactController.text.trim(),
        'mapUrl': _mapUrlController.text.trim(),
        'website': _webController.text.trim(),
        'cityId': formattedCityId,
        'cityName': _cityNameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.doc == null) {
        // ADD NEW
        placeData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('places').add(placeData);
      } else {
        // UPDATE EXISTING
        await widget.doc!.reference.update(placeData);
      }

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Text(
              widget.doc == null ? "ADD PLACE" : "EDIT PLACE",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final img = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 50,
                );
                if (img != null)
                  setState(() => _selectedImage = File(img.path));
              },
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : (_existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 50,
                              color: Colors.blueAccent,
                            )),
              ),
            ),
            const SizedBox(height: 20),
            _adminField(_nameController, "Place Name", Icons.title),
            _adminField(_cityNameController, "City Name", Icons.location_city),
            _adminField(_categoryController, "Category", Icons.category),
            _adminField(
              _ratingController,
              "Rating",
              Icons.star,
              input: TextInputType.number,
            ),
            _adminField(_timingController, "Hours", Icons.schedule),
            _adminField(
              _contactController,
              "Phone",
              Icons.phone,
              input: TextInputType.phone,
            ),
            _adminField(
              _descController,
              "Description",
              Icons.info_outline,
              lines: 3,
            ),
            _adminField(_mapUrlController, "Map Link", Icons.map_outlined),
            _adminField(_webController, "Website Link", Icons.public),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.doc == null ? "UPLOAD PLACE" : "UPDATE PLACE",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _adminField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int lines = 1,
    TextInputType input = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: lines,
        keyboardType: input,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// --- MANAGE PLACES TAB (With Edit Button) ---
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
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['image'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.image),
                  ),
                ),
                title: Text(
                  data['name'] ?? 'Place',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("${data['cityName']} • ${data['category']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) =>
                            AddPlaceFormSheet(doc: doc), // EDIT Mode
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
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
        title: const Text("Delete?"),
        content: const Text("Are you sure you want to remove this place?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              doc.reference.delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// --- USERS & REVIEWS TABS (Same as before) ---
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
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(data['username'] ?? 'User'),
              subtitle: Text(data['email'] ?? ''),
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['role'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blueAccent,
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
          return const Center(child: Text("No reviews found."));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(
                  "\"${data['comment']}\"",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                subtitle: Text("Rating: ${data['stars']} ⭐"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
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
