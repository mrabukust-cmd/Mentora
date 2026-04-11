// services/home_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.uid;
  }

  // Centralized error handling
  Future<T> _handleOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e);
    } on Exception catch (e) {
      throw Exception('Error: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  String _handleFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to access this data';
      case 'not-found':
        return 'Data not found';
      case 'unavailable':
        return 'Service temporarily unavailable';
      case 'deadline-exceeded':
        return 'Request timed out';
      default:
        return 'Error: ${e.message}';
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>> getUserData() async {
    return _handleOperation(() async {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (!doc.exists) {
        throw Exception('User profile not found');
      }

      return doc.data()!;
    });
  }

  /// Get requests statistics
  Future<Map<String, int>> getRequestsStats() async {
    return _handleOperation(() async {
      // Use batch read for better performance
      final results = await Future.wait([
        _getActiveRequestsCount(),
        _getPendingSessionsCount(),
      ]);

      return {
        'activeRequests': results[0],
        'pendingSessions': results[1],
      };
    });
  }

  /// Get count of active requests (sent by user)
  Future<int> _getActiveRequestsCount() async {
    try {
      final snapshot = await _firestore
          .collection('requests')
          .where('requesterId', isEqualTo: _currentUserId)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting active requests count: $e');
      return 0;
    }
  }

  /// Get count of pending sessions (received by user as mentor)
  Future<int> _getPendingSessionsCount() async {
    try {
      final snapshot = await _firestore
          .collection('requests')
          .where('mentorId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting pending sessions count: $e');
      return 0;
    }
  }

  /// Get user's skills statistics
  Future<Map<String, int>> getSkillsStats() async {
    return _handleOperation(() async {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (!doc.exists) {
        return {'skillsOffered': 0, 'skillsWanted': 0};
      }

      final data = doc.data()!;
      final skillsOffered = (data['skillsOffered'] as List?)?.length ?? 0;
      final skillsWanted = (data['skillsWanted'] as List?)?.length ?? 0;

      return {
        'skillsOffered': skillsOffered,
        'skillsWanted': skillsWanted,
      };
    });
  }

  /// Stream user data for real-time updates
  Stream<Map<String, dynamic>> streamUserData() {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('User profile not found');
          }
          return snapshot.data()!;
        })
        .handleError((error) {
          throw _handleFirebaseException(error);
        });
  }

  /// Stream requests statistics for real-time updates
  Stream<Map<String, int>> streamRequestsStats() {
    // Create a combined stream of both sent and received requests
    return _firestore
        .collection('requests')
        .where('requesterId', isEqualTo: _currentUserId)
        .snapshots()
        .asyncMap((sentSnapshot) async {
          // Get received requests count
          final receivedSnapshot = await _firestore
              .collection('requests')
              .where('mentorId', isEqualTo: _currentUserId)
              .where('status', isEqualTo: 'pending')
              .get();

          // Count active requests (sent)
          final activeRequests = sentSnapshot.docs
              .where((doc) => ['pending', 'accepted'].contains(doc['status']))
              .length;

          return {
            'activeRequests': activeRequests,
            'pendingSessions': receivedSnapshot.docs.length,
          };
        });
  }

  /// Check if user document exists
  Future<bool> userExists() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking user exists: $e');
      return false;
    }
  }

  /// Get user's location
  Future<Map<String, String>> getUserLocation() async {
    return _handleOperation(() async {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (!doc.exists) {
        throw Exception('User profile not found');
      }

      final data = doc.data()!;
      return {
        'city': data['city']?.toString() ?? '',
        'state': data['state']?.toString() ?? '',
        'country': data['country']?.toString() ?? '',
      };
    });
  }
}

// Debug print helper
void debugPrint(String message) {
  if (kDebugMode) {
    print(message);
  }
}

