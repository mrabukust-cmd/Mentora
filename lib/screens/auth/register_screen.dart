import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentora/screens/auth/auth_header.dart';
import 'package:mentora/screens/auth/login_screen.dart';
import 'package:mentora/screens/home/home_screen.dart';
import 'package:mentora/services/auth_service.dart';
import 'package:mentora/widgets/auth_app_bar.dart';
import 'package:mentora/widgets/auth_text_field.dart';
import 'package:mentora/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AuthAppBar(title: "Connect.Learn.Exchange."),
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
                  title: "Join Mentora",
                  subtitle: "Let's create your account together",
                ),
                AuthTextField(
                  controller: _firstNameController,
                  label: "First Name",
                  hint: "Enter your first name",
                  icon: Icons.person,
                ),
                AuthTextField(
                  label: "Last Name",
                  hint: "Enter your last name",
                  icon: Icons.person,
                  controller: _lastNameController,
                ),
                AuthTextField(
                  label: "Email",
                  hint: "Enter your email",
                  icon: Icons.email,
                  controller: _emailController,
                ),
                AuthTextField(
                  label: "Password",
                  hint: "Enter your password",
                  icon: Icons.lock,
                  ispassword: true,
                  controller: _passwordController,
                ),
                //------------------------------------------Country,state,city name-------------------------------------
                const SizedBox(height: 15),
                Text(
                  "Location",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CSCPickerPlus(
                  layout: Layout.vertical,
                  onCountryChanged: (Country) {},
                  onStateChanged: (State) {},
                  onCityChanged: (City) {},
                  dropdownDialogRadius: 30,
                  searchBarRadius: 50,
                  countryDropdownLabel: 'Country',
                  stateDropdownLabel: 'State',
                  cityDropdownLabel: 'City',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: const Text("Already have an account? Login"),
                  ),
                ),
                const SizedBox(height: 30),
                PrimaryButton(
                  text: 'Register',
                  onPressed: () async {
                    setState(() {
                      _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Register");
                    });

                    try {
                      User? user = await _authService.registerWithEmail(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );

                      if (user != null) {
                        // Registration successful
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      }
                    } catch (e) {
                      // Show error as snackbar
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
