import 'package:city_exploration_app/screens/listing_screen.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final String cityId;
  final String cityName;

  const CategoryScreen({
    super.key,
    required this.cityId,
    required this.cityName,
  });

  final List<Map<String, dynamic>> categories = const [
    {"name": "Attractions", "icon": Icons.landscape},
    {"name": "Restaurants", "icon": Icons.restaurant},
    {"name": "Hotels", "icon": Icons.hotel},
    {"name": "Events", "icon": Icons.event},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Explore $cityName")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListingsScreen(
                    cityId: cityId,
                    cityName: cityName,
                    category: categories[index]['name'],
                  ),
                ),
              );
            },
            child: Card(
              color: Colors.blueAccent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    categories[index]['icon'],
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    categories[index]['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
