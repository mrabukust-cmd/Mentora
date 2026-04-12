import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mentora/screens/chat/chat_models.dart';
import 'package:mentora/services/home_service.dart';
import 'package:mentora/services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ─── COLLECTIONS ──────────────────────────────────────────
  CollectionReference get _conversations => _db.collection('conversations');
  CollectionReference get _users => _db.collection('users');

  CollectionReference _messages(String conversationId) =>
      _db.collection('conversations').doc(conversationId).collection('messages');

  // ─── CREATE CONVERSATION (called when request is ACCEPTED) ─
  Future<String> createConversationOnAccept({
    required String requestId,
    required String mentorId,
    required String learnerId,
  }) async {
    // Check if conversation already exists via the request document
    // (avoids a collection query — uses direct doc read which rules allow)
    final requestDoc = await _db.collection('requests').doc(requestId).get();
    final existingConvId = requestDoc.data()?['conversationId']?.toString();
    if (existingConvId != null && existingConvId.isNotEmpty) {
      return existingConvId; // already exists
    }

    // Fetch both user profiles
    final mentorDoc = await _users.doc(mentorId).get();
    final learnerDoc = await _users.doc(learnerId).get();

    final mentorData = mentorDoc.data() as Map<String, dynamic>? ?? {};
    final learnerData = learnerDoc.data() as Map<String, dynamic>? ?? {};

    // Create new conversation
    final conv = ConversationModel(
      id: '',
      participants: [mentorId, learnerId],
      requestId: requestId,
      lastMessage: '🤝 Skill exchange accepted! Say hello!',
      lastMessageTime: DateTime.now(),
      unreadCount: {mentorId: 0, learnerId: 1}, // learner gets notification
      participantNames: {
        mentorId: '${mentorData['firstName'] ?? ''} ${mentorData['lastName'] ?? ''}'.trim().isNotEmpty
            ? '${mentorData['firstName'] ?? ''} ${mentorData['lastName'] ?? ''}'.trim()
            : 'Mentor',
        learnerId: '${learnerData['firstName'] ?? ''} ${learnerData['lastName'] ?? ''}'.trim().isNotEmpty
            ? '${learnerData['firstName'] ?? ''} ${learnerData['lastName'] ?? ''}'.trim()
            : 'Student',
      },
      participantPhotos: {
        mentorId: mentorData['profileImageUrl'] ?? '',
        learnerId: learnerData['profileImageUrl'] ?? '',
      },
    );

    final docRef = await _conversations.add(conv.toMap());

    // Update the skill request with conversationId
    await _db.collection('requests').doc(requestId).update({
      'conversationId': docRef.id,
      'chatUnlocked': true,
    });

    return docRef.id;
  }

  // ─── SEND MESSAGE ──────────────────────────────────────────
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final message = MessageModel(
      id: '',
      conversationId: conversationId,
      senderId: senderId,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Add message
    await _messages(conversationId).add(message.toMap());

    // Update conversation's last message + unread count
    final convDoc = await _conversations.doc(conversationId).get();
    final convData = convDoc.data() as Map<String, dynamic>;
    final participants = List<String>.from(convData['participants']);

    // Increment unread for the OTHER user
    final otherId = participants.firstWhere((id) => id != senderId);

    await _conversations.doc(conversationId).update({
      'lastMessage': text.trim(),
      'lastMessageTime': DateTime.now(),
      'unreadCount.$otherId': FieldValue.increment(1),
    });

    // Send push notification
    await _sendPushNotification(
      toUserId: otherId,
      senderName: convData['participantNames'][senderId] ?? 'Someone',
      message: text.trim(),
      conversationId: conversationId,
    );
  }

  // ─── STREAM MESSAGES ──────────────────────────────────────
  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _messages(conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ─── STREAM ALL CONVERSATIONS FOR A USER ──────────────────
  Stream<List<ConversationModel>> streamUserConversations(String userId) {
    return _conversations
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ConversationModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ─── MARK MESSAGES AS READ ────────────────────────────────
  Future<void> markAsRead(String conversationId, String userId) async {
    // Reset unread count for this user
    await _conversations.doc(conversationId).update({
      'unreadCount.$userId': 0,
    });

    // Mark all unread messages as read
    final unread = await _messages(conversationId)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─── GET TOTAL UNREAD COUNT ────────────────────────────────
  Stream<int> streamTotalUnread(String userId) {
    return _conversations
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unreadMap = Map<String, dynamic>.from(data['unreadCount'] ?? {});
        total += (unreadMap[userId] as int? ?? 0);
      }
      return total;
    });
  }

  // ─── PUSH NOTIFICATIONS ───────────────────────────────────
  /// Shows a local notification on the RECEIVER's device when a message
  /// arrives (works when app is in foreground or background via FCM).
  Future<void> _sendPushNotification({
    required String toUserId,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    try {
      // Get receiver's FCM token for remote push (background/killed state)
      final userDoc = await _users.doc(toUserId).get();
      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      final fcmToken = data['fcmToken'] as String?;

      // Queue in Firestore for Cloud Function to deliver FCM push
      // (handles background / killed app state)
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _db.collection('pushNotifications').add({
          'toUserId': toUserId,
          'fcmToken': fcmToken,
          'title': senderName,
          'body': message,
          'type': 'chat',
          'conversationId': conversationId,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }

      // Also show immediate local notification for FOREGROUND state
      // (receiver sees it instantly if app is open but on a different screen)
      await NotificationService().showChatNotification(
        senderName: senderName,
        message: message,
        conversationId: conversationId,
        otherUserId: toUserId,
      );
    } catch (e) {
      debugPrint('Push notification error (non-fatal): $e');
    }
  }

  // ─── SAVE FCM TOKEN ───────────────────────────────────────
  Future<void> saveFcmToken(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _users.doc(userId).update({'fcmToken': token});
    }
  }
}