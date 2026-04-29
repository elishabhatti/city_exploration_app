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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getPlaces() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('places')
            .where('cityId',
                isEqualTo: cityId)
            .where('category',
                isEqualTo: category)
            .get();

    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$cityName - $category'),
      ),
      body: FutureBuilder(
        future: getPlaces(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final places = snapshot.data!;

          if (places.isEmpty) {
            return const Center(
              child: Text(
                "No places found.",
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place =
                  places[index].data();

              return Card(
                margin:
                    const EdgeInsets.only(
                        bottom: 16),
                child: ListTile(
                  leading: Image.network(
                    place['image'],
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    place['name'],
                  ),
                  subtitle: Text(
                    place['description'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}