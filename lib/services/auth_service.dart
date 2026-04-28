import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User> register({
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;

    if (user == null) {
      throw Exception("User registration failed");
    }

    return user;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      throw Exception("Email is required");
    }

    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Reset failed");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
