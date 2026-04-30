import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Toggle Favorite
  Future<void> toggleFavorite(
    String userId,
    String placeId,
    Map<String, dynamic> placeData,
  ) async {
    final favRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(placeId);

    final doc = await favRef.get();

    if (doc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({
        'name': placeData['name'],
        'image': placeData['image'],
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Check if is Favorite
  Future<bool> isFavorite(String userId, String placeId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(placeId)
        .get();
    return doc.exists;
  }
}
