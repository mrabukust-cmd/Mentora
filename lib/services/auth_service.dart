import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //---------------------------------- REGISTER ----------------------------------
  Future<User?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Send email verification
      // await result.user?.sendEmailVerification();

      // // Optional: Sign out after registration to force verification
      // await _auth.signOut();

      return result.user;
    } on FirebaseAuthException catch (e) {
      // Handle common Firebase Auth errors
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already in use.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'weak-password':
          message = 'The password is too weak.';
          break;
        default:
          message = 'Registration failed. ${e.message}';
      }
      throw message;
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  //---------------------------------- LOGIN ----------------------------------
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User user = result.user!;

      //-------------------------------Check email verification--------------------------------
      if (!user.emailVerified) {
        // Optional: resend verification email
        await user.sendEmailVerification();

        // Sign out to block login until verification
       // await _auth.signOut();
        //throw 'Email not verified. Verification email sent. Please verify your email before logging in.';
      }

      return user;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'User not found. Please register first.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Login failed. ${e.message}';
      }
      throw message;
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  //---------------------------------- LOGOUT ----------------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  //---------------------------------- CURRENT USER ----------------------------------
  User? get currentUser => _auth.currentUser;
}
