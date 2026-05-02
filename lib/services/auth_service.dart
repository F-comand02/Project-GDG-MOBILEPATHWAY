import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Logika Daftar (Register)
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await result.user!.sendEmailVerification();
      return result.user;
    } catch (e) {
      print('Register error: $e');  // Debug
      rethrow;
    }
  }

  // Logika Masuk (Login)
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print('Login error: $e');  // Debug
      rethrow;
    }
  }

  // Logika Keluar (Logout)
  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Logika Keluar (Logout)
  Future logout() async {
    return await _auth.signOut();
  }
}
