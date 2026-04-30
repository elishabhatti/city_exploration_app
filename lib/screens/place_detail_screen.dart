import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String placeId;
  final Map<String, dynamic> placeData;

  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    required this.placeData,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool isFavorite = false;
  final TextEditingController _reviewController = TextEditingController();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Favorite Service Instance
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  // --- OLD LOGIC: Favorite Status Check ---
  void _checkFavoriteStatus() async {
    if (userId == null) return;
    bool exists = await _favoriteService.isFavorite(userId!, widget.placeId);
    if (mounted) {
      setState(() => isFavorite = exists);
    }
  }

  // --- OLD LOGIC: Toggle Favorite ---
  Future<void> _toggleFavorite() async {
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login first!")));
      return;
    }
    await _favoriteService.toggleFavorite(
      userId!,
      widget.placeId,
      widget.placeData,
    );
    setState(() => isFavorite = !isFavorite);
  }

  // --- NEW LOGIC: Get Directions (Google Maps Intent) ---
  Future<void> _openDirections() async {
    final String placeName = widget.placeData['name'];
    // Direct Navigation URL
    final String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(placeName)}&travelmode=driving";

    final Uri uri = Uri.parse(googleMapsUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Maps';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error opening Maps: $e")));
    }
  }

  // --- OLD LOGIC: URL Launcher for Web/Call ---
  Future<void> _launchExternal(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open link")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.placeData['name']),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE SECTION
            Image.network(
              widget.placeData['image'],
              height: 280,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 280,
                color: Colors.grey,
                child: const Icon(Icons.broken_image, size: 80),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. NAME & RATING
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.placeData['name'],
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            Text(
                              " ${widget.placeData['rating'] ?? '0.0'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. DESCRIPTION
                  Text(
                    widget.placeData['description'] ??
                        'No description available.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),

                  const Divider(height: 40),

                  // 4. ACTION BUTTONS (Updated with Directions)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionIcon(
                        Icons.directions,
                        "Directions",
                        Colors.blue,
                        () => _openDirections(), // Naya Function Call
                      ),
                      _actionIcon(
                        Icons.language,
                        "Website",
                        Colors.orange,
                        () =>
                            _launchExternal(widget.placeData['website'] ?? ''),
                      ),
                      _actionIcon(
                        Icons.call,
                        "Call",
                        Colors.green,
                        () => _launchExternal(
                          "tel:${widget.placeData['contact']}",
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 40),

                  // 5. QUICK INFO
                  const Text(
                    "Quick Info",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _infoTile(
                    Icons.access_time,
                    "Timings",
                    widget.placeData['timings'],
                  ),
                  _infoTile(
                    Icons.phone_iphone,
                    "Contact",
                    widget.placeData['contact'],
                  ),

                  const Divider(height: 40),

                  // 6. REVIEWS SECTION (Old Logic intact)
                  const Text(
                    "Reviews",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reviewController,
                          decoration: InputDecoration(
                            hintText: "Add a review...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () async {
                          if (_reviewController.text.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('reviews')
                                .add({
                                  'placeId': widget.placeId,
                                  'userName':
                                      FirebaseAuth.instance.currentUser?.email
                                          ?.split('@')[0] ??
                                      'User',
                                  'comment': _reviewController.text,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                            _reviewController.clear();
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Reviews List (Old Logic intact)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('placeId', isEqualTo: widget.placeId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty)
                        return const Text("No reviews yet. Be the first!");

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var r = docs[index].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person, size: 20),
                              ),
                              title: Text(
                                r['userName'] ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(r['comment'] ?? ''),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _infoTile(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _actionIcon(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 25,
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// --- FAVORITE SERVICE ---
class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> toggleFavorite(
    String userId,
    String placeId,
    Map<String, dynamic> placeData,
  ) async {
    final favRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(placeId);
    final doc = await favRef.get();

    if (doc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({
        'name': placeData['name'],
        'image': placeData['image'],
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> isFavorite(String userId, String placeId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(placeId)
        .get();
    return doc.exists;
  }
}
