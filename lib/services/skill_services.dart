import 'package:cloud_firestore/cloud_firestore.dart';

class SkillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<dynamic>> fetchMyOfferedSkills(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return (doc.data()?['skillsOffered'] as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>> fetchMyWantedSkills(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return (doc.data()?['skillsWanted'] as List<dynamic>?) ?? [];
  }

  Future<void> addSkillOffered({
    required String uid,
    required String name,
    required String category,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'skillsOffered': FieldValue.arrayUnion([
        {'name': name, 'category': category},
      ]),
    });
  }

  Future<void> addSkillWanted({
    required String uid,
    required String name,
    required String category,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'skillsWanted': FieldValue.arrayUnion([
        {'name': name, 'category': category},
      ]),
    });
  }
}
