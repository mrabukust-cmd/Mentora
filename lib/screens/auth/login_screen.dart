import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentora/main_screen.dart';
import 'package:mentora/screens/auth/auth_header.dart';
import 'package:mentora/services/auth_service.dart';
import 'package:mentora/widgets/auth_app_bar.dart';
import 'package:mentora/widgets/auth_text_field.dart';
import 'package:mentora/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  final AuthService _authService = AuthService();

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showError("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.loginWithEmail(email: email, password: password);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> resetpassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showError("Please enter your email to reset password");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent")),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showError("User not found. Please register first.");
      } else if (e.code == 'invalid-email') {
        showError("Invalid email address.");
      } else {
        showError("Failed to send reset email. Try again.");
      }
    } catch (e) {
      showError("Something went wrong. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AuthAppBar(title: "Connect•Learn•Exchange"),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                AuthHeader(
                  title: "Welcome Back!",
                  subtitle: "Login to your account",
                ),
                const SizedBox(height: 5),
                AuthTextField(
                  label: "Email",
                  hint: "Enter your email",
                  icon: Icons.email,
                  controller: emailController,
                ),
                AuthTextField(
                  label: "Password",
                  hint: "Enter your password",
                  icon: Icons.lock,
                  ispassword: true,
                  controller: passwordController,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: resetpassword,
                    child: const Text("Forgot Password?"),
                  ),
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(text: "Login", onPressed: login),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
