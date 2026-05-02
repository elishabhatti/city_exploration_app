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

  // Categories with more professional icons
  final List<Map<String, dynamic>> categories = const [
    {
      "name": "Attractions",
      "icon": Icons.explore_outlined,
      "color": Colors.blue,
    },
    {
      "name": "Restaurants",
      "icon": Icons.restaurant_menu_rounded,
      "color": Colors.orange,
    },
    {"name": "Hotels", "icon": Icons.bed_outlined, "color": Colors.indigo},
    {
      "name": "Events",
      "icon": Icons.confirmation_number_outlined,
      "color": Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean professional background
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
          cityName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header text
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 10, 25, 20),
            child: Text(
              "What are you\nlooking for?",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                height: 1.1,
              ),
            ),
          ),

          // Modern Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.85, // Adjust card height
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final Color themeColor = category['color'];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingsScreen(
                          cityId: cityId,
                          cityName: cityName,
                          category: category['name'],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      // Your signature minimalist border style
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with subtle circular background
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category['icon'],
                            size: 32,
                            color: themeColor,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          category['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Explore places",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
