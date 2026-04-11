import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mentora/screens/chat/chat_models.dart';
import 'package:mentora/screens/chat/chat_models.dart';

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
    // Check if conversation already exists for this request
    final existing = await _conversations
        .where('requestId', isEqualTo: requestId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id; // already exists
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
        mentorId: mentorData['name'] ?? 'Mentor',
        learnerId: learnerData['name'] ?? 'Learner',
      },
      participantPhotos: {
        mentorId: mentorData['photoUrl'] ?? '',
        learnerId: learnerData['photoUrl'] ?? '',
      },
    );

    final docRef = await _conversations.add(conv.toMap());

    // Update the skill request with conversationId
    await _db.collection('skillRequests').doc(requestId).update({
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
  Future<void> _sendPushNotification({
    required String toUserId,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    // Get receiver's FCM token
    final userDoc = await _users.doc(toUserId).get();
    final data = userDoc.data() as Map<String, dynamic>? ?? {};
    final fcmToken = data['fcmToken'] as String?;

    if (fcmToken == null) return;

    // Store notification in Firestore (use Cloud Functions to actually send FCM)
    await _db.collection('notifications').add({
      'toUserId': toUserId,
      'fcmToken': fcmToken,
      'title': senderName,
      'body': message,
      'type': 'chat',
      'conversationId': conversationId,
      'createdAt': DateTime.now(),
      'sent': false,
    });
  }

  // ─── SAVE FCM TOKEN ───────────────────────────────────────
  Future<void> saveFcmToken(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _users.doc(userId).update({'fcmToken': token});
    }
  }
}
