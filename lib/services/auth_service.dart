import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Logika Daftar (Register)
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (_) {
      return null;
    }
  }

  // Logika Masuk (Login)
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (_) {
      return null;
    }
  }

  // Logika Keluar (Logout)
  Future logout() async {
    return await _auth.signOut();
  }
}