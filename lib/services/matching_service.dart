import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns users who:
  /// 1. Offer a skill that the current user WANTS
  /// 2. Want a skill that the current user OFFERS
  /// (True mutual skill exchange matching)
  Future<List<Map<String, dynamic>>> getMatchedMentors() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Get current user document
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    if (!userDoc.exists) return [];

    final userData = userDoc.data()!;
    final userCity = userData['city'] ?? '';

    // My skills offered (names, lowercased for comparison)
    final myOfferedSkills = _extractSkillNames(userData['skillsOffered']);

    // My skills wanted (names, lowercased for comparison)
    final myWantedSkills = _extractSkillNames(userData['skillsWanted']);

    // If I have nothing to offer or nothing to learn, no mutual match possible
    if (myOfferedSkills.isEmpty || myWantedSkills.isEmpty) return [];

    // Get all users
    final usersSnapshot = await _firestore.collection('users').get();
    List<Map<String, dynamic>> results = [];

    for (var doc in usersSnapshot.docs) {
      if (doc.id == currentUserId) continue;

      // Only same city
      if ((doc['city'] ?? '') != userCity) continue;

      final otherData = doc.data();

      // Their offered skills
      final theirOfferedSkillNames = _extractSkillNames(otherData['skillsOffered']);
      // Their wanted skills
      final theirWantedSkillNames = _extractSkillNames(otherData['skillsWanted']);

      // Find skills THEY offer that I WANT
      final skillsTheyCanTeachMe = theirOfferedSkillNames
          .where((skill) => myWantedSkills.contains(skill))
          .toList();

      // Find skills I offer that THEY WANT
      final skillsICanTeachThem = myOfferedSkills
          .where((skill) => theirWantedSkillNames.contains(skill))
          .toList();

      // Both conditions must be true for a mutual match
      if (skillsTheyCanTeachMe.isEmpty || skillsICanTeachThem.isEmpty) continue;

      // Build the full skill objects for display
      final List<Map<String, dynamic>> skillsOffered =
          List<Map<String, dynamic>>.from(otherData['skillsOffered'] ?? []);

      final matchedOfferedSkills = skillsOffered
          .where((s) => skillsTheyCanTeachMe.contains(
                (s['name'] ?? '').toString().toLowerCase().trim(),
              ))
          .toList();

      // Add each skill as a separate recommendation
      for (var skill in matchedOfferedSkills) {
        results.add({
          'mentorId': doc.id,
          'name': '${otherData['firstName'] ?? ''} ${otherData['lastName'] ?? ''}'.trim(),
          // Extra fields needed by MentorDetailsScreen
          'firstName': otherData['firstName'] ?? '',
          'lastName': otherData['lastName'] ?? '',
          'email': otherData['email'] ?? '',
          'city': otherData['city'] ?? '',
          'state': otherData['state'] ?? '',
          'country': otherData['country'] ?? '',
          'skillsOffered': List<Map<String, dynamic>>.from(otherData['skillsOffered'] ?? []),
          'skill': skill['name'],
          'category': skill['category'] ?? '',
          'rating': (otherData['rating'] ?? 0.0) as double,
          'totalRatings': (otherData['totalRatings'] ?? 0) as int,
          // Skills I can offer them in return (for UI display)
          'mySkillsForThem': skillsICanTeachThem,
          'matchScore': skillsTheyCanTeachMe.length + skillsICanTeachThem.length,
        });
      }
    }

    // Sort by match score (best mutual matches first), then by rating
    results.sort((a, b) {
      final scoreCompare = (b['matchScore'] as int).compareTo(a['matchScore'] as int);
      if (scoreCompare != 0) return scoreCompare;
      return (b['rating'] as double).compareTo(a['rating'] as double);
    });

    return results;
  }

  /// Check if two specific users are a mutual match
  Future<MutualMatchResult> checkMutualMatch({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final results = await Future.wait([
      _firestore.collection('users').doc(currentUserId).get(),
      _firestore.collection('users').doc(otherUserId).get(),
    ]);

    final myData = results[0].data() ?? {};
    final theirData = results[1].data() ?? {};

    final myOffered = _extractSkillNames(myData['skillsOffered']);
    final myWanted = _extractSkillNames(myData['skillsWanted']);
    final theirOffered = _extractSkillNames(theirData['skillsOffered']);
    final theirWanted = _extractSkillNames(theirData['skillsWanted']);

    final skillsTheyCanTeachMe =
        theirOffered.where((s) => myWanted.contains(s)).toList();
    final skillsICanTeachThem =
        myOffered.where((s) => theirWanted.contains(s)).toList();

    return MutualMatchResult(
      isMutualMatch: skillsTheyCanTeachMe.isNotEmpty && skillsICanTeachThem.isNotEmpty,
      skillsTheyOffer: skillsTheyCanTeachMe,
      skillsYouOffer: skillsICanTeachThem,
    );
  }

  /// Browse mentors filtered by mutual match logic
  /// Used in BrowseMentorsScreen for filtering
  Future<List<Map<String, dynamic>>> getMutuallyMatchedMentors({
    String? cityFilter,
    String? skillFilter,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    if (!userDoc.exists) return [];

    final userData = userDoc.data()!;
    final userCity = cityFilter ?? userData['city'] ?? '';

    final myOfferedSkills = _extractSkillNames(userData['skillsOffered']);
    final myWantedSkills = _extractSkillNames(userData['skillsWanted']);

    final usersSnapshot = await _firestore.collection('users').get();
    List<Map<String, dynamic>> results = [];

    for (var doc in usersSnapshot.docs) {
      if (doc.id == currentUserId) continue;
      if ((doc['city'] ?? '') != userCity) continue;

      final otherData = doc.data();
      final theirOffered = _extractSkillNames(otherData['skillsOffered']);
      final theirWanted = _extractSkillNames(otherData['skillsWanted']);

      // Skills they can teach me
      final canTeachMe = myWantedSkills.isEmpty
          ? theirOffered // if I haven't set wanted skills, show all
          : theirOffered.where((s) => myWantedSkills.contains(s)).toList();

      // Skills I can offer them
      final iCanTeach = myOfferedSkills.isEmpty
          ? <String>[]
          : myOfferedSkills.where((s) => theirWanted.contains(s)).toList();

      // Apply skill filter if provided
      if (skillFilter != null && skillFilter.isNotEmpty) {
        final filterLower = skillFilter.toLowerCase().trim();
        if (!canTeachMe.any((s) => s.contains(filterLower))) continue;
      }

      // At minimum, they must offer something I want
      if (canTeachMe.isEmpty) continue;

      final List<Map<String, dynamic>> skillsOffered =
          List<Map<String, dynamic>>.from(otherData['skillsOffered'] ?? []);

      results.add({
        'id': doc.id,
        'firstName': otherData['firstName'] ?? '',
        'lastName': otherData['lastName'] ?? '',
        'city': otherData['city'] ?? '',
        'state': otherData['state'] ?? '',
        'country': otherData['country'] ?? '',
        'skillsOffered': skillsOffered,
        'rating': (otherData['rating'] ?? 0.0) as double,
        'totalRatings': (otherData['totalRatings'] ?? 0) as int,
        'completedSessions': (otherData['completedSessions'] ?? 0) as int,
        // Mutual match info
        'isMutualMatch': iCanTeach.isNotEmpty,
        'skillsTheyCanTeachMe': canTeachMe,
        'skillsICanTeachThem': iCanTeach,
        'matchScore': canTeachMe.length + iCanTeach.length,
      });
    }

    // Sort: mutual matches first, then by rating
    results.sort((a, b) {
      final aMutual = a['isMutualMatch'] as bool ? 1 : 0;
      final bMutual = b['isMutualMatch'] as bool ? 1 : 0;
      if (bMutual != aMutual) return bMutual.compareTo(aMutual);
      return (b['rating'] as double).compareTo(a['rating'] as double);
    });

    return results;
  }

  // ─── HELPERS ──────────────────────────────────────────────

  /// Extract lowercase trimmed skill names from a Firestore skills list
  List<String> _extractSkillNames(dynamic skillsData) {
    if (skillsData == null || skillsData is! List) return [];
    return skillsData
        .whereType<Map>()
        .map((s) => s['name']?.toString().toLowerCase().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }
}

/// Result of checking mutual match between two users
class MutualMatchResult {
  final bool isMutualMatch;
  final List<String> skillsTheyOffer; // skills they can teach me
  final List<String> skillsYouOffer;  // skills I can teach them

  const MutualMatchResult({
    required this.isMutualMatch,
    required this.skillsTheyOffer,
    required this.skillsYouOffer,
  });
}