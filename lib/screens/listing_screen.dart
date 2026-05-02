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
      await favRef.delete();
    } else {
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
      backgroundColor: Colors.white, // Pure white for that polished look
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- Premium Search Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search in ${widget.cityName}...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.black,
                  size: 22,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade100,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 1.5,
                  ),
                ),
              ),
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
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState("No places found.");
                }

                final filteredPlaces = snapshot.data!.docs.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                if (filteredPlaces.isEmpty) {
                  return _buildEmptyState("No matches for '$searchQuery'");
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredPlaces.length,
                  itemBuilder: (context, index) {
                    var place =
                        filteredPlaces[index].data() as Map<String, dynamic>;
                    String placeId = filteredPlaces[index].id;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaceDetailScreen(
                            placeId: placeId,
                            placeData: place,
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade100,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Aesthetic Image with Badge
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    place['image'] ?? '',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          "${place['rating'] ?? '4.0'}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 15),

                            // Info Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place['name'] ?? 'Unnamed',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        place['timings'] ?? '10am - 8pm',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    place['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Heart Toggle
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection('favorites')
                                  .doc(placeId)
                                  .snapshots(),
                              builder: (context, favSnapshot) {
                                bool isFav =
                                    favSnapshot.hasData &&
                                    favSnapshot.data!.exists;
                                return IconButton(
                                  onPressed: () =>
                                      _toggleFavorite(placeId, place),
                                  icon: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_outline_rounded,
                                    color: isFav
                                        ? Colors.redAccent
                                        : Colors.grey[300],
                                    size: 26,
                                  ),
                                );
                              },
                            ),
                          ],
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
