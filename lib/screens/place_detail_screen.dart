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

  // URL Launcher (Map aur Website ke liye)
  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.placeData['name']),
        actions: [
          // Favorite Button
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, 
                 color: isFavorite ? Colors.red : null),
            onPressed: () {
              setState(() => isFavorite = !isFavorite);
              // Yahan aap Favorites collection mein save karne ka logic daal sakte hain
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE
            Image.network(
              widget.placeData['image'],
              height: 250, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => 
                  const Center(child: Icon(Icons.broken_image, size: 100)),
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
                        child: Text(widget.placeData['name'], 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          Text(" ${widget.placeData['rating'] ?? 'N/A'}", 
                          style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3. DESCRIPTION
                  Text(widget.placeData['description'] ?? 'No description',
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),

                  const Divider(height: 40),

                  // 4. INFORMATION (Timings & Contact)
                  const Text("Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.blue),
                    title: Text("Timings: ${widget.placeData['timings'] ?? 'N/A'}"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.green),
                    title: Text("Contact: ${widget.placeData['contact'] ?? 'N/A'}"),
                  ),

                  const SizedBox(height: 10),

                  // 5. ACTION BUTTONS (Map & Website)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openLink(widget.placeData['mapUrl'] ?? ''),
                          icon: const Icon(Icons.map),
                          label: const Text("Location"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openLink(widget.placeData['website'] ?? ''),
                          icon: const Icon(Icons.language),
                          label: const Text("Website"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 40),

                  // 6. REVIEWS SECTION
                  const Text("Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Review Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reviewController,
                          decoration: const InputDecoration(hintText: "Add a review..."),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () async {
                          if (_reviewController.text.isNotEmpty) {
                            await FirebaseFirestore.instance.collection('reviews').add({
                              'placeId': widget.placeId,
                              'userName': FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'User',
                              'comment': _reviewController.text,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            _reviewController.clear();
                          }
                        },
                      ),
                    ],
                  ),

                  // Reviews List
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('placeId', isEqualTo: widget.placeId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      var docs = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var r = docs[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(r['userName'] ?? 'Anonymous'),
                            subtitle: Text(r['comment'] ?? ''),
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
}