import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Load theme from Firestore
  Future<void> loadTheme() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    _isDarkMode = doc.data()?['isDarkMode'] ?? false;
    notifyListeners();
  }

  // Toggle theme
  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();

    final uid = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(uid).update({
      'isDarkMode': value,
    });
  }
}
