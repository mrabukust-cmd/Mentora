import 'package:flutter/material.dart';
import 'package:mentora/screens/home/home_screen.dart';
import 'package:mentora/widgets/auth_app_bar.dart';
import 'package:mentora/widgets/primary_button.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AuthAppBar(title: "Forget Password"),
      body: SafeArea(child: PrimaryButton(text: "Recovery password", onPressed: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      })),
    );
  }
}