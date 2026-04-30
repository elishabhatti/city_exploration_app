import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_model.dart';

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
