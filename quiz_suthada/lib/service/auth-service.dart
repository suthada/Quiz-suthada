import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  Future<String?> registration({
    required String email,
    required String password,
    required String confirm,
  }) async {
    if (password != confirm) {
      return 'Passwords do not match';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signin({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
