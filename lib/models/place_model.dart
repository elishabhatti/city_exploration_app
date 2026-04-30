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
  });

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
    );
  }
}
