import 'package:flutter/material.dart';

class AboutMentoraScreen extends StatelessWidget {
  const AboutMentoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Mentora')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Mentora is a peer tutoring and skill-sharing platform '
          'built for university students to connect and learn from each other. '
          'Version: 1.0.0',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
