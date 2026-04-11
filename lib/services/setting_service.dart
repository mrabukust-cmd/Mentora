import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // Get notification setting
  Stream<bool> notificationStatus() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .snapshots()
        .map((doc) => doc.data()?['notificationsEnabled'] ?? true);
  }

  // Update notification setting
  Future<void> updateNotification(bool value) async {
    await _firestore.collection('users').doc(_uid).update({
      'notificationsEnabled': value,
    });
  }
}
