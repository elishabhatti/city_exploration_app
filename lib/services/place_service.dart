import 'package:city_exploration_app/models/place_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kisi specific shehar ke places lane ke liye
  Future<List<PlaceModel>> getPlacesByCity(String cityId) async {
    final snapshot = await _firestore
        .collection('places')
        .where('cityId', isEqualTo: cityId)
        .get();

    return snapshot.docs.map((doc) {
      return PlaceModel.fromFirestore(doc.data(), doc.id);
    }).toList();
  }
}
