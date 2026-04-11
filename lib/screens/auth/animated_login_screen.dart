// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:mentora/main_screen.dart';
// import 'package:mentora/services/google_auth_service.dart';

// class AnimatedLoginScreen extends StatefulWidget {
//   const AnimatedLoginScreen({super.key});

//   @override
//   State<AnimatedLoginScreen> createState() => _AnimatedLoginScreenState();
// }

// class _AnimatedLoginScreenState extends State<AnimatedLoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final _googleAuthService = GoogleAuthService();
  
//   bool _isLoading = false;
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _signInWithGoogle() async {
//     setState(() => _isLoading = true);

//     try {
//       final userCredential = await _googleAuthService.signInWithGoogle();

//       if (userCredential == null) {
//         // User cancelled
//         setState(() => _isLoading = false);
//         return;
//       }

//       if (!mounted) return;

//       // Navigate to main screen
//       Navigator.pushReplacement(
//         context,
//         PageRouteBuilder(
//           pageBuilder: (_, __, ___) => const MainScreen(),
//           transitionDuration: const Duration(milliseconds: 600),
//           transitionsBuilder: (_, animation, __, child) {
//             return FadeTransition(
//               opacity: animation,
//               child: ScaleTransition(
//                 scale: Tween<double>(begin: 0.8, end: 1.0).animate(
//                   CurvedAnimation(parent: animation, curve: Curves.easeOut),
//                 ),
//                 child: child,
//               ),
//             );
//           },
//         ),
//       );
//     } catch (e) {
//       setState(() => _isLoading = false);
//       _showErrorSnackBar('Google Sign-In failed: ${e.toString()}');
//     }
//   }

//   Future<void> _signInWithEmail() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text,
//       );

//       if (!mounted) return;

//       Navigator.pushReplacement(
//         context,
//         PageRouteBuilder(
//           pageBuilder: (_, __, ___) => const MainScreen(),
//           transitionDuration: const Duration(milliseconds: 600),
//           transitionsBuilder: (_, animation, __, child) {
//             return FadeTransition(opacity: animation, child: child);
//           },
//         ),
//       );
//     } on FirebaseAuthException catch (e) {
//       setState(() => _isLoading = false);
//       String message = 'Login failed';
      
//       if (e.code == 'user-not-found') {
//         message = 'No user found with this email';
//       } else if (e.code == 'wrong-password') {
//         message = 'Wrong password';
//       } else if (e.code == 'invalid-email') {
//         message = 'Invalid email address';
//       }
      
//       _showErrorSnackBar(message);
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error_outline, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red.shade400,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Theme.of(context).primaryColor.withOpacity(0.8),
//               Theme.of(context).primaryColor,
//               Colors.purple.shade300,
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Logo
//                     Container(
//                       width: 100,
//                       height: 100,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 20,
//                             spreadRadius: 5,
//                           ),
//                         ],
//                       ),
//                       child: const Icon(
//                         Icons.school_rounded,
//                         size: 50,
//                         color: Colors.blueAccent,
//                       ),
//                     )
//                         .animate()
//                         .scale(duration: 600.ms, curve: Curves.elasticOut)
//                         .fadeIn(),

//                     const SizedBox(height: 24),

//                     // Welcome text
//                     const Text(
//                       'Welcome Back!',
//                       style: TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     )
//                         .animate()
//                         .fadeIn(delay: 200.ms)
//                         .slideY(begin: -0.2, delay: 200.ms),

//                     const SizedBox(height: 8),

//                     Text(
//                       'Sign in to continue learning',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.white.withOpacity(0.9),
//                       ),
//                     )
//                         .animate()
//                         .fadeIn(delay: 300.ms)
//                         .slideY(begin: -0.1, delay: 300.ms),

//                     const SizedBox(height: 40),

//                     // Google Sign-In Button (PRIMARY)
//                     _buildGoogleButton()
//                         .animate()
//                         .fadeIn(delay: 400.ms)
//                         .slideX(begin: -0.2, delay: 400.ms),

//                     const SizedBox(height: 24),

//                     // Divider
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Divider(
//                             color: Colors.white.withOpacity(0.5),
//                             thickness: 1,
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Text(
//                             'OR',
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.7),
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           child: Divider(
//                             color: Colors.white.withOpacity(0.5),
//                             thickness: 1,
//                           ),
//                         ),
//                       ],
//                     ).animate().fadeIn(delay: 500.ms),

//                     const SizedBox(height: 24),

//                     // Email field
//                     _buildEmailField()
//                         .animate()
//                         .fadeIn(delay: 600.ms)
//                         .slideX(begin: -0.2, delay: 600.ms),

//                     const SizedBox(height: 16),

//                     // Password field
//                     _buildPasswordField()
//                         .animate()
//                         .fadeIn(delay: 700.ms)
//                         .slideX(begin: -0.2, delay: 700.ms),

//                     const SizedBox(height: 24),

//                     // Sign In button
//                     _buildSignInButton()
//                         .animate()
//                         .fadeIn(delay: 800.ms)
//                         .scale(delay: 800.ms),

//                     const SizedBox(height: 16),

//                     // Sign Up link
//                     _buildSignUpLink()
//                         .animate()
//                         .fadeIn(delay: 900.ms),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildGoogleButton() {
//     return Container(
//       width: double.infinity,
//       height: 56,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: _isLoading ? null : _signInWithGoogle,
//           borderRadius: BorderRadius.circular(16),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 if (_isLoading)
//                   const SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 else ...[
//                   Image.asset(
//                     'assets/google_logo.png', // You'll need to add this
//                     width: 24,
//                     height: 24,
//                     errorBuilder: (_, __, ___) => const Icon(
//                       Icons.g_mobiledata,
//                       size: 32,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Text(
//                     'Continue with Google',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailField() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.9),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: TextFormField(
//         controller: _emailController,
//         keyboardType: TextInputType.emailAddress,
//         style: const TextStyle(fontSize: 16),
//         decoration: InputDecoration(
//           labelText: 'Email',
//           prefixIcon: const Icon(Icons.email_outlined),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide.none,
//           ),
//           filled: true,
//           fillColor: Colors.transparent,
//         ),
//         validator: (value) {
//           if (value == null || value.trim().isEmpty) {
//             return 'Please enter your email';
//           }
//           if (!value.contains('@')) {
//             return 'Please enter a valid email';
//           }
//           return null;
//         },
//       ),
//     );
//   }

//   Widget _buildPasswordField() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.9),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: TextFormField(
//         controller: _passwordController,
//         obscureText: _obscurePassword,
//         style: const TextStyle(fontSize: 16),
//         decoration: InputDecoration(
//           labelText: 'Password',
//           prefixIcon: const Icon(Icons.lock_outlined),
//           suffixIcon: IconButton(
//             icon: Icon(
//               _obscurePassword ? Icons.visibility_off : Icons.visibility,
//             ),
//             onPressed: () {
//               setState(() => _obscurePassword = !_obscurePassword);
//             },
//           ),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: BorderSide.none,
//           ),
//           filled: true,
//           fillColor: Colors.transparent,
//         ),
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter your password';
//           }
//           if (value.length < 6) {
//             return 'Password must be at least 6 characters';
//           }
//           return null;
//         },
//       ),
//     );
//   }

//   Widget _buildSignInButton() {
//     return Container(
//       width: double.infinity,
//       height: 56,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Colors.orange, Colors.deepOrange],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.orange.withOpacity(0.3),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: _isLoading ? null : _signInWithEmail,
//           borderRadius: BorderRadius.circular(16),
//           child: Center(
//             child: _isLoading
//                 ? const SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       strokeWidth: 2,
//                     ),
//                   )
//                 : const Text(
//                     'Sign In with Email',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSignUpLink() {
//     return TextButton(
//       onPressed: () {
//         // Navigate to sign up screen
//         Navigator.pushNamed(context, '/signup');
//       },
//       child: RichText(
//         text: TextSpan(
//           text: "Don't have an account? ",
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.9),
//             fontSize: 14,
//           ),
//           children: const [
//             TextSpan(
//               text: 'Sign Up',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }