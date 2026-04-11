// services/request_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser!.uid;

  // Centralized error handling
  Future<T> _handleFirestoreOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  String _handleFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action';
      case 'not-found':
        return 'Resource not found';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  // Get sent requests with proper error handling
  Stream<List<Map<String, dynamic>>> getMySentRequests() {
    return _firestore
        .collection('requests')
        .where('requesterId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        })
        .handleError((error) {
          throw _handleFirebaseException(error);
        });
  }

  // Get received requests
  Stream<List<Map<String, dynamic>>> getMyReceivedRequests() {
    return _firestore
        .collection('requests')
        .where('mentorId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  // Create request with validation
  Future<void> createRequest({
    required String mentorId,
    required String mentorName,
    required String mentorEmail,
    required String skillName,
    required String skillCategory,
    required String message,
    DateTime? preferredDate,
    String? preferredTime,
  }) async {
    // Validation
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    if (mentorId == _currentUserId) {
      throw Exception('You cannot send a request to yourself');
    }

    return _handleFirestoreOperation(() async {
      // Get requester info
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      final userData = userDoc.data()!;

      // Check for duplicate pending requests
      final existingRequests = await _firestore
          .collection('requests')
          .where('requesterId', isEqualTo: _currentUserId)
          .where('mentorId', isEqualTo: mentorId)
          .where('skillName', isEqualTo: skillName)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      if (existingRequests.docs.isNotEmpty) {
        throw Exception(
          'You already have a pending request for this skill with this mentor',
        );
      }

      // Create request
      await _firestore.collection('requests').add({
        'requesterId': _currentUserId,
        'requesterName': '${userData['firstName']} ${userData['lastName']}',
        'requesterEmail': userData['email'],
        'mentorId': mentorId,
        'mentorName': mentorName,
        'mentorEmail': mentorEmail,
        'skillName': skillName,
        'skillCategory': skillCategory,
        'message': message.trim(),
        'preferredDate': preferredDate != null
            ? Timestamp.fromDate(preferredDate)
            : null,
        'preferredTime': preferredTime,
        'status': 'pending',
        'rating': 0.0,
        'review': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update mentor's pending request count
      await _firestore.collection('users').doc(mentorId).update({
        'activeRequests': FieldValue.increment(1),
      });
    });
  }

  // Accept request with transaction
  Future<void> acceptRequest({
    required String requestId,
    required DateTime sessionDate,
    required String sessionTime,
    required String meetingLocation,
  }) async {
    return _handleFirestoreOperation(() async {
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore.collection('requests').doc(requestId);
        final requestDoc = await transaction.get(requestRef);

        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }

        final data = requestDoc.data()!;

        if (data['mentorId'] != _currentUserId) {
          throw Exception('Unauthorized action');
        }

        if (data['status'] != 'pending') {
          throw Exception('Request is no longer pending');
        }

        transaction.update(requestRef, {
          'status': 'accepted',
          'sessionDate': Timestamp.fromDate(sessionDate),
          'sessionTime': sessionTime,
          'meetingLocation': meetingLocation.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    });
  }

  // Reject request
  Future<void> rejectRequest(String requestId) async {
    return _handleFirestoreOperation(() async {
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore.collection('requests').doc(requestId);
        final requestDoc = await transaction.get(requestRef);

        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }

        final data = requestDoc.data()!;

        if (data['mentorId'] != _currentUserId) {
          throw Exception('Unauthorized action');
        }

        transaction.update(requestRef, {
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Decrement mentor's active request count
        final mentorRef = _firestore.collection('users').doc(data['mentorId']);
        transaction.update(mentorRef, {
          'activeRequests': FieldValue.increment(-1),
        });
      });
    });
  }

  // Complete request
  Future<void> completeRequest(String requestId) async {
    return _handleFirestoreOperation(() async {
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore.collection('requests').doc(requestId);
        final requestDoc = await transaction.get(requestRef);

        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }

        final data = requestDoc.data()!;

        if (data['mentorId'] != _currentUserId) {
          throw Exception('Unauthorized action');
        }

        if (data['status'] != 'accepted') {
          throw Exception('Only accepted requests can be completed');
        }

        transaction.update(requestRef, {
          'status': 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update mentor stats
        final mentorRef = _firestore.collection('users').doc(data['mentorId']);
        transaction.update(mentorRef, {
          'completedSessions': FieldValue.increment(1),
          'activeRequests': FieldValue.increment(-1),
        });
      });
    });
  }

  // Submit rating
  Future<void> submitRating({
    required String requestId,
    required double rating,
    String? review,
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    return _handleFirestoreOperation(() async {
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore.collection('requests').doc(requestId);
        final requestDoc = await transaction.get(requestRef);

        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }

        final data = requestDoc.data()!;

        if (data['requesterId'] != _currentUserId) {
          throw Exception('Unauthorized action');
        }

        if (data['status'] != 'completed') {
          throw Exception('Can only rate completed sessions');
        }

        if ((data['rating'] ?? 0.0) > 0) {
          throw Exception('You have already rated this session');
        }

        // Update request with rating
        transaction.update(requestRef, {
          'rating': rating,
          'review': review?.trim() ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update mentor's overall rating
        final mentorRef = _firestore.collection('users').doc(data['mentorId']);
        final mentorDoc = await transaction.get(mentorRef);
        final mentorData = mentorDoc.data()!;

        final currentRating = (mentorData['rating'] ?? 0.0) as double;
        final totalRatings = (mentorData['totalRatings'] ?? 0) as int;

        final newTotalRatings = totalRatings + 1;
        final newRating =
            ((currentRating * totalRatings) + rating) / newTotalRatings;

        transaction.update(mentorRef, {
          'rating': newRating,
          'totalRatings': newTotalRatings,
        });
      });
    });
  }

  // Cancel request (by requester)
  Future<void> cancelRequest(String requestId) async {
    return _handleFirestoreOperation(() async {
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore.collection('requests').doc(requestId);
        final requestDoc = await transaction.get(requestRef);

        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }

        final data = requestDoc.data()!;

        if (data['requesterId'] != _currentUserId) {
          throw Exception('Unauthorized action');
        }

        if (data['status'] != 'pending') {
          throw Exception('Can only cancel pending requests');
        }

        transaction.update(requestRef, {
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Decrement mentor's pending count
        final mentorRef = _firestore.collection('users').doc(data['mentorId']);
        transaction.update(mentorRef, {
          'activeRequests': FieldValue.increment(-1),
        });
      });
    });
  }
}
