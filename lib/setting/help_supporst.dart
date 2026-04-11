import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'If you need help, contact us via email or phone.\n\n'
              'Email: support@mentora.com\n'
              'Phone: +123456789',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: const Text('Send Email'),
              onPressed: () {
                // Optional: integrate url_launcher to open email app
              },
            ),
          ],
        ),
      ),
    );
  }
}
