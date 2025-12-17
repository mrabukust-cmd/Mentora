import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mentora/screens/auth/main_auth.dart';
import 'package:mentora/screens/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () => checkUser());
  }

  void checkUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => MainAuth()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => MainAuth()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 90,
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
              SizedBox(height: 20),
              Text('Mentora', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.green)
            ],
          ),
        ),
      ),
    );
  }
}