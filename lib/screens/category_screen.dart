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

  final List<String> categories = const [
    'Attractions',
    'Restaurants',
    'Hotels',
    'Events',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cityName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListingsScreen(
                      cityId: cityId,
                      cityName: cityName,
                      category: category,
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                child: Center(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}