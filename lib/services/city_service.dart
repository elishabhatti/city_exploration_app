import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_model.dart';

class CityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CityModel>> getCities() async {
    final snapshot = await _firestore.collection('cities').get();

    return snapshot.docs.map((doc) {
      return CityModel.fromFirestore(doc.data(), doc.id);
    }).toList();
  }
}