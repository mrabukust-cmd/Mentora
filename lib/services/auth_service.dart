import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register
  Future<User?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      //-------------------------------send email verification----------------------------------
      await result.user?.sendEmailVerification();

      // ------------------------------Log out user after registration--------------------------
      await _auth.signOut();
      return result.user;
    } catch (e) {
      throw e.toString();
    }
  }

  // -------------------------------------Login---------------------------------------------
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User user = result.user!;
      //--------------------------------------check Email verification--------------------------
      if (!user.emailVerified) {
        await user
            .sendEmailVerification(); //optional: resend verification email
        await _auth.signOut(); //block login if email not verified
        throw "Email not verified. Verification email sent. Please verify your email before logging in.";
      }
      return user;
    } catch (e) {
      throw e.toString();
    }
  }

  //--------------------------------------Logout----------------------------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }
}
