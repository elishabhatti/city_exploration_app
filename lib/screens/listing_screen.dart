import 'package:city_exploration_app/screens/place_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListingsScreen extends StatelessWidget {
  final String cityId;
  final String cityName;
  final String category;

  const ListingsScreen({
    super.key,
    required this.cityId,
    required this.cityName,
    required this.category,
  });

  // Query: Search places where cityId AND category match
  Stream<QuerySnapshot> getPlacesStream() {
    return FirebaseFirestore.instance
        .collection('places')
        .where('cityId', isEqualTo: cityId)
        .where('category', isEqualTo: category)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$category in $cityName")),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPlacesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("No $category found in $cityName yet."),
                ],
              ),
            );
          }

          final places = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: places.length,
            itemBuilder: (context, index) {
              var place = places[index].data() as Map<String, dynamic>;
              // final placeId = places[index].id; // Future use for details

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      place['image'] ?? '',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                  title: Text(
                    place['name'] ?? 'Unnamed Place',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        place['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(" ${place['rating'] ?? 'N/A'}"),
                          const SizedBox(width: 15),
                          const Icon(Icons.access_time, size: 16),
                          Text(" ${place['timings'] ?? 'N/A'}"),
                        ],
                      ),
                    ],
                  ),
                  // ListingsScreen mein ListTile ke andar
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceDetailScreen(
                          placeId:
                              places[index].id, // Documgood yar now ient ID reviews ke liye
                          placeData: place, // Poora data display ke liye
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
