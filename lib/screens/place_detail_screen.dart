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
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    if (userId == null) return;
    bool exists = await _favoriteService.isFavorite(userId!, widget.placeId);
    if (mounted) setState(() => isFavorite = exists);
  }

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

  Future<void> _openDirections() async {
    final String placeName = widget.placeData['name'];
    final String url =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(placeName)}";
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch Maps';
    }
  }

  Future<void> _launchExternal(String urlString) async {
    if (urlString.isEmpty) return;
    if (!await launchUrl(
      Uri.parse(urlString),
      mode: LaunchMode.externalApplication,
    )) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open link")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Sleek Sliver Header
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: _headerActionIcon(
              Icons.arrow_back_ios_new,
              () => Navigator.pop(context),
            ),
            actions: [
              _headerActionIcon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                _toggleFavorite,
                iconColor: isFavorite ? Colors.redAccent : Colors.black,
              ),
              const SizedBox(width: 15),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.placeId,
                child: Image.network(
                  widget.placeData['image'],
                  fit: BoxFit.cover,
                ),
              ),
              stretchModes: const [StretchMode.zoomBackground],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Title & Rating Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.placeData['name'],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${widget.placeData['rating'] ?? '4.0'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Description
                  Text(
                    widget.placeData['description'] ??
                        'No description available.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 25),
                    child: Divider(color: Color(0xFFF1F1F1), thickness: 2),
                  ),

                  // 4. Action Buttons (Modern Row)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _modernActionBtn(
                        Icons.directions_outlined,
                        "Directions",
                        Colors.blue,
                        _openDirections,
                      ),
                      _modernActionBtn(
                        Icons.public_outlined,
                        "Website",
                        Colors.orange,
                        () =>
                            _launchExternal(widget.placeData['website'] ?? ''),
                      ),
                      _modernActionBtn(
                        Icons.phone_outlined,
                        "Contact",
                        Colors.green,
                        () => _launchExternal(
                          "tel:${widget.placeData['contact']}",
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 25),
                    child: Divider(color: Color(0xFFF1F1F1), thickness: 2),
                  ),

                  // 5. Quick Info Cards
                  const Text(
                    "Highlights",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 15),
                  _infoCard(
                    Icons.access_time_rounded,
                    "Opening Hours",
                    widget.placeData['timings'],
                  ),
                  _infoCard(
                    Icons.location_on_outlined,
                    "Location Details",
                    "Verified Destination",
                  ),

                  const SizedBox(height: 40),

                  // 6. Review Section
                  const Text(
                    "Community Reviews",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 15),
                  _buildReviewInput(),
                  const SizedBox(height: 20),
                  _buildReviewList(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _headerActionIcon(
    IconData icon,
    VoidCallback onTap, {
    Color iconColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.9),
        child: IconButton(
          icon: Icon(icon, color: iconColor, size: 20),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _modernActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.blueGrey[400]),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value ?? 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewInput() {
    return TextField(
      controller: _reviewController,
      decoration: InputDecoration(
        hintText: "Share your experience...",
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: IconButton(
          icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
          onPressed: _submitReview,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade100, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('reviews').add({
      'placeId': widget.placeId,
      'userName':
          FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Explorer',
      'comment': _reviewController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _reviewController.clear();
    FocusScope.of(context).unfocus();
  }

  Widget _buildReviewList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('placeId', isEqualTo: widget.placeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        var docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return Text(
            "No reviews yet. Be the first!",
            style: TextStyle(color: Colors.grey[400]),
          );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var r = docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: Text(
                      r['userName'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['userName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          r['comment'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
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

// --- Service Class Re-used ---
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
