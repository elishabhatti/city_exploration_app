class CityModel {
  final String id;
  final String name;
  final String description;
  final String image;

  CityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
  });

  factory CityModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CityModel(
      id: id,
      name: data['name'],
      description: data['description'],
      image: data['image'],
    );
  }
}