import 'package:flutter/material.dart';
import 'package:mentora/screens/auth/login_screen.dart';
import 'package:mentora/screens/auth/register_screen.dart';
import 'package:mentora/widgets/auth_app_bar.dart';
import 'package:mentora/widgets/primary_button.dart';

class MainAuth extends StatelessWidget {
  const MainAuth({super.key});

  @override
  Widget build(BuildContext context) {
    //-----------------------------------------get device size (For Responsiveness)--------------------------------------------------------------
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AuthAppBar(title: "Connect.Learn.Exchange."),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: size.width * 0.85,
                  height: 52,
                  child: PrimaryButton(
                    text: "Register",
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: size.width * 0.85,
                  height: 52,
                  child:
                PrimaryButton(
                  text: "Login",
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
