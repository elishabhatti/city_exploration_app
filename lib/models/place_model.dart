class PlaceModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final String rating;
  final String timings;
  final String contact;
  final String mapUrl;
  final String website;
  final String category; // Added
  final String cityName; // Added
  final String cityId; // Added

  PlaceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.rating,
    required this.timings,
    required this.contact,
    required this.mapUrl,
    required this.website,
    required this.category,
    required this.cityName,
    required this.cityId,
  });

  // Data Read karne ke liye
  factory PlaceModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PlaceModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      image: data['image'] ?? '',
      rating: data['rating']?.toString() ?? '0.0',
      timings: data['timings'] ?? 'Not available',
      contact: data['contact'] ?? 'Not available',
      mapUrl: data['mapUrl'] ?? '',
      website: data['website'] ?? '',
      category: data['category'] ?? 'General',
      cityName: data['cityName'] ?? '',
      cityId: data['cityId'] ?? '',
    );
  }

  // Data Firestore mein bhejne ke liye (Add/Update)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'rating': rating,
      'timings': timings,
      'contact': contact,
      'mapUrl': mapUrl,
      'website': website,
      'category': category,
      'cityName': cityName,
      'cityId': cityId,
    };
  }
}
