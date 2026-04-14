import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Manages Agora call signaling via Firestore.
/// Each call is a document in the 'calls' collection.
class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── IMPORTANT: Replace with your Agora App ID from console.agora.io ──
  static const String agoraAppId = 'be795e97a4134272b2771d5b6ee0992c';

  // For testing use a temp token from Agora console.
  // In production use a token server.
  static const String agoraTempToken = ''; // leave empty for testing in debug

  // ─── INITIATE A CALL ──────────────────────────────────────
  Future<String> initiateCall({
    required String callerId,
    required String callerName,
    required String calleeId,
    required String calleeName,
    required String conversationId,
  }) async {
    // Channel name = conversationId (unique per pair)
    final channelName = 'mentora_$conversationId';

    final callDoc = await _db.collection('calls').add({
      'callerId': callerId,
      'callerName': callerName,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'channelName': channelName,
      'conversationId': conversationId,
      'status': 'ringing', // ringing → accepted / declined / ended
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return callDoc.id;
  }

  // ─── ACCEPT CALL ──────────────────────────────────────────
  Future<void> acceptCall(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── DECLINE CALL ─────────────────────────────────────────
  Future<void> declineCall(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── END CALL ─────────────────────────────────────────────
  Future<void> endCall(String callId) async {
    await _db.collection('calls').doc(callId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── LISTEN FOR INCOMING CALLS ────────────────────────────
  /// Returns a stream of incoming ringing calls for the current user.
  Stream<Map<String, dynamic>?> incomingCallStream(String userId) {
    return _db
        .collection('calls')
        .where('calleeId', isEqualTo: userId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return {'callId': doc.id, ...doc.data()};
    });
  }

  // ─── LISTEN FOR CALL STATUS CHANGES ──────────────────────
  Stream<String?> callStatusStream(String callId) {
    return _db.collection('calls').doc(callId).snapshots().map(
          (doc) => doc.data()?['status']?.toString(),
        );
  }

  // ─── GET CALL DATA ────────────────────────────────────────
  Future<Map<String, dynamic>?> getCall(String callId) async {
    final doc = await _db.collection('calls').doc(callId).get();
    if (!doc.exists) return null;
    return {'callId': doc.id, ...doc.data()!};
  }
}

/// Global navigator key used by IncomingCallOverlay
final GlobalKey<NavigatorState> agoraNavigatorKey = GlobalKey<NavigatorState>();