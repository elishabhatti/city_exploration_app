import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For Google Maps & Website

class PlaceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> placeData;
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeData, required this.placeId});

  // Function to open Google Maps
  Future<void> _openMap(String location) async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$location";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(placeData['image'], fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(placeData['name'], style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber),
                      Text(" ${placeData['rating'] ?? 'N/A'}"),
                    ],
                  ),
                  const Divider(),
                  _infoRow(Icons.access_time, "Timings", placeData['timings']),
                  _infoRow(Icons.phone, "Contact", placeData['contact']),
                  _infoRow(Icons.language, "Website", placeData['website']),
                  const SizedBox(height: 20),
                  Text("About", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(placeData['description']),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => _openMap(placeData['name']),
                    icon: Icon(Icons.directions),
                    label: Text("Get Directions"),
                    style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 10),
          Text("$title: ${value ?? 'Not available'}"),
        ],
      ),
    );
  }
}