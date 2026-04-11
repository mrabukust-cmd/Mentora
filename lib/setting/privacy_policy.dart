import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'Privacy Policy content goes here...\n\n'
            'You can add your app’s privacy rules, data usage, '
            'and user rights here for FYP demonstration.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
