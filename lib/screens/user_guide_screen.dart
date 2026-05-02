import 'package:flutter/material.dart';

class UserGuideScreen extends StatefulWidget {
  // StatefulWidget banaya taake step change ho sakay
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  int _index = 0; // Current active step ko track karne ke liye variable

  final List<IconData> stepIcons = [
    Icons.location_city,
    Icons.filter_alt_outlined,
    Icons.description_outlined,
    Icons.directions,
    Icons.rate_review_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("App User Guide"), centerTitle: true),
      body: Stepper(
        physics: const ClampingScrollPhysics(),
        // Buttons hide hain, lekin click karne par step change hoga
        controlsBuilder: (context, details) => const SizedBox.shrink(),

        currentStep: _index, // State variable use kiya
        // Is function se user kisi bhi step par click karke usay "See More" kar sakta hai
        onStepTapped: (int newIndex) {
          setState(() {
            _index = newIndex;
          });
        },

        stepIconBuilder: (index, state) =>
            Icon(stepIcons[index], color: Colors.white, size: 16),

        steps: [
          Step(
            title: const Text(
              "Choose Your City",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Pick a city from the home list to start exploring local attractions.",
            ),
            isActive: _index >= 0, // Current step highlight karne ke liye
          ),
          Step(
            title: const Text(
              "Filter Categories",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Switch between Hotels, Restaurants, and Events to find what you need.",
            ),
            isActive: _index >= 1,
          ),
          Step(
            title: const Text(
              "Explore Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Read descriptions, check timings, and look at photos of the places.",
            ),
            isActive: _index >= 2,
          ),
          Step(
            title: const Text(
              "Get Directions",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Use the directions button to open Google Maps for easy navigation.",
            ),
            isActive: _index >= 3,
          ),
          Step(
            title: const Text(
              "Rate & Review",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Share your experience with others by leaving a rating and review.",
            ),
            isActive: _index >= 4,
          ),
        ],
      ),
    );
  }
}
