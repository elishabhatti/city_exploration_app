import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser({
    required String uid,
    required String username,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'username': username,
      'email': email,
      'createdAt': DateTime.now(),
    });
  }
}