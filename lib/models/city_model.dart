class CityModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final String url;

  CityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.url,
  });

  factory CityModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CityModel(
      id: id,
      name: data['name'],
      description: data['description'],
      image: data['image'],
      url: data['url'],
    );
  }
}