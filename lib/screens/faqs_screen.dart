import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List of FAQs (Aap isay Firestore se bhi la sakte hain baad mein)
    final List<Map<String, String>> faqs = [
      {
        "question": "How do I explore a city?",
        "answer":
            "Simply select a city from the home screen. You will see different categories like Attractions, Hotels, and Restaurants to explore.",
      },
      {
        "question": "Can I add reviews to places?",
        "answer":
            "Yes! Click on any place to see its details, and there you will find a review section where you can share your experience and give star ratings.",
      },
      {
        "question": "How do I get directions?",
        "answer":
            "On the place detail page, click the 'Get Directions' button. It will open Google Maps and show you the exact route from your location.",
      },
      {
        "question": "How can I change my profile picture?",
        "answer":
            "Go to your profile by clicking the person icon on the home screen, then tap on your current profile picture to upload a new one.",
      },
      {
        "question": "Are the events updated regularly?",
        "answer":
            "Our admin team updates events and listings daily to ensure you have the most accurate information for your journey.",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Frequently Asked Questions",
          style: TextStyle(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
              ), // Minimalist border
            ),
            child: ExpansionTile(
              shape: const Border(), // Expansion divider hatane ke liye
              leading: Icon(Icons.quiz_outlined, color: Colors.blueAccent[700]),
              title: Text(
                faqs[index]['question']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Text(
                    faqs[index]['answer']!,
                    style: TextStyle(color: Colors.grey[700], height: 1.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
