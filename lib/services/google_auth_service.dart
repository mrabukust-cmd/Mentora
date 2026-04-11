// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class GoogleAuthService {
//   final FirebaseAuth auth = FirebaseAuth.instance;
//   final GoogleSignIn googleSignIn = GoogleSignIn();

//   // Sign in with Google
//   Future<User?> signInWithGoogle() async {
//     try {
//       // Start Google Sign In
//       final GoogleSignInAccount? account = await googleSignIn.signIn();
      
//       if (account == null) {
//         print('Sign in cancelled');
//         return null;
//       }

//       // Get authentication
//       final GoogleSignInAuthentication auth = await account.authentication;
      
//       // Create credential
//       final OAuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: auth.accessToken,
//         idToken: auth.idToken,
//       );

//       // Sign in to Firebase
//       final UserCredential result = await this.auth.signInWithCredential(credential);
//       final User? user = result.user;

//       // Create user profile if new
//       if (result.additionalUserInfo?.isNewUser == true && user != null) {
//         await createUserProfile(user);
//       }

//       print('Sign in success: ${user?.email}');
//       return user;
      
//     } catch (e) {
//       print('Sign in error: $e');
//       return null;
//     }
//   }

//   // Create user profile in Firestore
//   Future<void> createUserProfile(User user) async {
//     try {
//       String displayName = user.displayName ?? 'User';
//       List<String> nameParts = displayName.split(' ');
      
//       String firstName = nameParts.length > 0 ? nameParts[0] : 'User';
//       String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

//       await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
//         'uid': user.uid,
//         'email': user.email ?? '',
//         'firstName': firstName,
//         'lastName': lastName,
//         'photoURL': user.photoURL ?? '',
//         'provider': 'google',
//         'skillsOffered': [],
//         'skillsWanted': [],
//         'rating': 0.0,
//         'totalRatings': 0,
//         'completedSessions': 0,
//         'activeRequests': 0,
//         'city': '',
//         'state': '',
//         'country': '',
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       print('Profile created for: ${user.email}');
//     } catch (e) {
//       print('Profile creation error: $e');
//     }
//   }

//   // Sign out
//   Future<void> signOut() async {
//     try {
//       await googleSignIn.signOut();
//       await auth.signOut();
//       print('Sign out success');
//     } catch (e) {
//       print('Sign out error: $e');
//     }
//   }

//   // Get current user
//   User? getCurrentUser() {
//     return auth.currentUser;
//   }

//   // Check if signed in
//   bool isSignedIn() {
//     return auth.currentUser != null;
//   }

//   // Auth state stream
//   Stream<User?> authStateChanges() {
//     return auth.authStateChanges();
//   }
// }