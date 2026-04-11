import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = "en"; // default
  String get languageCode => _languageCode;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Load from Firestore
  Future<void> loadLanguage() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    _languageCode = doc.data()?['languageCode'] ?? 'en';
    notifyListeners();
  }

  // Update language
  Future<void> setLanguage(String code) async {
    _languageCode = code;
    notifyListeners();

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'languageCode': code,
      });
    }
  }
}
