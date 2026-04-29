import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PlaceDetailScreen extends StatelessWidget {
  final String placeId;
  final Map<String, dynamic> placeData;

  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    required this.placeData,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController reviewController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text(placeData['name'])),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Section
            Image.network(
              placeData['image'],
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image, size: 100)),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Name and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        placeData['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          Text(" ${placeData['rating']}"),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    placeData['description'],
                    style: const TextStyle(fontSize: 16),
                  ),

                  const Divider(height: 40),

                  // 3. Information Section
                  const Text(
                    "Information",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text("Timings: ${placeData['timings']}"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text("Visit Website"),
                  ),

                  const Divider(height: 40),

                  // 4. Reviews Section
                  const Text(
                    "Reviews",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  // Review Input Field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: reviewController,
                          decoration: const InputDecoration(
                            hintText: "Write a review...",
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () async {
                          if (reviewController.text.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection(
                                  'reviews',
                                ) // Database collection name
                                .add({
                                  'placeId': placeId,
                                  'userId':
                                      FirebaseAuth.instance.currentUser!.uid,
                                  'userName': FirebaseAuth
                                      .instance
                                      .currentUser!
                                      .email!
                                      .split('@')[0],
                                  'comment': reviewController.text,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                            reviewController.clear();
                          }
                        },
                      ),
                    ],
                  ),

                  // Reviews List (Simple Filter - No Sorting needed)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('placeId', isEqualTo: placeId)
                        // .orderBy hataya hai takay index error na aye
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final reviews = snapshot.data!.docs;

                      if (reviews.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("No reviews yet. Be the first!"),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          var r = reviews[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.account_circle, size: 40),
                            title: Text(r['userName'] ?? 'User'),
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
