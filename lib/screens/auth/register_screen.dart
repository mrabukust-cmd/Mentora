import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:mentora/main_screen.dart';
import 'package:mentora/screens/auth/login_screen.dart';
import 'package:mentora/services/auth_service.dart';
import 'package:mentora/widgets/auth_app_bar.dart';
import 'package:mentora/widgets/auth_text_field.dart';
import 'package:mentora/widgets/primary_button.dart';
import 'package:mentora/screens/auth/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _country, _state, _city;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus();
    if (_firstNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar("Please fill all required fields");
      return;
    }

    //LOcation Check
    if (_country == null || _state == null || _city == null) {
      _showSnackBar("Please select your complete location");
      return;
    }
    // “Why do you validate location before registration?”
    // Answer:
    // “Location is required for mentor matching logic, so validation ensures data integrity before account creation.”
    setState(() => _isLoading = true);

    try {
      final user = await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null) {
        // Save extra info
        // In register_screen.dart, update the Firestore document creation:
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'country': _country ?? '',
          'state': _state ?? '',
          'city': _city ?? '',

          'role': 'both',
          'skillsOffered': <String>[],
          'skillsWanted': <String>[],

          'rating': 0.0,
          'totalRatings': 0, // ⭐ ADD THIS
          'activeRequests': 0, // ⭐ ADD THIS
          'completedSessions': 0,

          'notificationsEnabled': true, // ⭐ ADD THIS
          'isDarkMode': false, // ⭐ ADD THIS
          'languageCode': 'en', // ⭐ ADD THIS

          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      _showSnackBar("Registration failed. Please try again.");
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AuthAppBar(title: "Connect•Learn•Exchange"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const AuthHeader(
                title: "Join Mentora",
                subtitle: "Create your learning journey today",
              ),
              const SizedBox(height: 30),
              AuthTextField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'Enter your first name',
                icon: Icons.person_outline,
              ),
              AuthTextField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'Enter your last name',
                icon: Icons.person_outline,
              ),
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
              ),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Create a password',
                icon: Icons.lock_outline,
                ispassword: true,
              ),
              const SizedBox(height: 20),
              Text(
                "Location",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CSCPickerPlus(
                layout: Layout.vertical,
                dropdownDialogRadius: 24,
                searchBarRadius: 24,
                countryDropdownLabel: "Country",
                stateDropdownLabel: "State",
                cityDropdownLabel: "City",
                onCountryChanged: (val) => _country = val,
                onStateChanged: (val) => _state = val,
                onCityChanged: (val) => _city = val,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text("Already have an account? Login"),
                ),
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                text: _isLoading ? "Creating account..." : "Register",
                onPressed: _isLoading ? null : _registerUser,
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
