import 'package:city_exploration_app/screens/place_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ListingsScreen extends StatefulWidget {
  final String cityId;
  final String cityName;
  final String category;

  const ListingsScreen({
    super.key,
    required this.cityId,
    required this.cityName,
    required this.category,
  });

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  String searchQuery = "";
  final userId = FirebaseAuth.instance.currentUser?.uid;

  // --- Favorite Toggle Function ---
  Future<void> _toggleFavorite(
    String placeId,
    Map<String, dynamic> placeData,
  ) async {
    if (userId == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(placeId);

    final doc = await favRef.get();

    if (doc.exists) {
      // Agar pehle se favorite hai toh remove kar do
      await favRef.delete();
    } else {
      // Agar nahi hai toh add kar do
      await favRef.set({
        'name': placeData['name'],
        'image': placeData['image'],
        'city': widget.cityName,
        'rating': placeData['rating'],
        'category': widget.category,
        'addedAt': DateTime.now(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("${widget.category} in ${widget.cityName}"),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search ${widget.category}...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // --- Results Section ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('places')
                  .where('cityId', isEqualTo: widget.cityId)
                  .where('category', isEqualTo: widget.category)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No data found for this category."),
                  );
                }

                // Client-side filtering
                final filteredPlaces = snapshot.data!.docs.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                if (filteredPlaces.isEmpty) {
                  return const Center(child: Text("No matches found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredPlaces.length,
                  itemBuilder: (context, index) {
                    var place =
                        filteredPlaces[index].data() as Map<String, dynamic>;
                    String placeId = filteredPlaces[index].id;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaceDetailScreen(
                              placeId: placeId,
                              placeData: place,
                            ),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              // Image Section
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  place['image'] ?? '',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Content Section
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place['name'] ?? 'Unnamed',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        Text(
                                          " ${place['rating'] ?? '4.0'}",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        Text(
                                          " ${place['timings'] ?? '10am - 8pm'}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      place['description'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Favorite Toggle Button
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('favorites')
                                    .doc(placeId)
                                    .snapshots(),
                                builder: (context, favSnapshot) {
                                  bool isFavorite =
                                      favSnapshot.hasData &&
                                      favSnapshot.data!.exists;
                                  return IconButton(
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onPressed: () =>
                                        _toggleFavorite(placeId, place),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
