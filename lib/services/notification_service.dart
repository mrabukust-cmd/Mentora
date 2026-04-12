import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:mentora/main.dart';
import 'package:mentora/screens/chat/chat_screen.dart';

/// Service for handling push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Firestore listeners for incoming chat messages
  StreamSubscription? _conversationsSubscription;
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  String? _currentUserId;
  // Tracks the latest message timestamp per conversation to avoid
  // showing notifications for old messages on first listen
  final Map<String, DateTime> _lastSeenTimestamp = {};

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token and save to Firestore
      await _saveFCMToken();

      // Create chat notification channel
      await _createChatChannel();

      // Setup message handlers
      _setupMessageHandlers();

      _initialized = true;
      print('✅ Notification service initialized');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional notification permission');
    } else {
      print('❌ User declined notification permission');
    }
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTapped(response);
      },
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'mentora_channel',
      'Mentora Notifications',
      description: 'Notifications for Mentora app',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // ─── CHAT NOTIFICATION CHANNEL ───────────────────────────
  static const _chatChannel = AndroidNotificationChannel(
    'mentora_chat_channel',
    'Chat Messages',
    description: 'Notifications for new chat messages',
    importance: Importance.max,
    playSound: true,
  );

  /// Call this once during initialize() to register the chat channel
  Future<void> _createChatChannel() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_chatChannel);
  }

  // ─── FIRESTORE MESSAGE LISTENER ──────────────────────────
  /// Start listening to all conversations the current user is in.
  /// When a new message arrives from someone else, show a local notification.
  /// Call this after login (from MainScreen.initState).
  Future<void> startListeningForMessages(String userId) async {
    _currentUserId = userId;

    // Cancel any existing subscriptions first
    await stopListeningForMessages();

    // Watch all conversations where this user is a participant
    _conversationsSubscription = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final conversationId = doc.id;
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);

        // Only listen to conversations this user is actually in
        if (!participants.contains(userId)) continue;

        // Already subscribed to this conversation
        if (_messageSubscriptions.containsKey(conversationId)) continue;

        // Get participant names map to find sender name later
        final names = Map<String, String>.from(
          (data['participantNames'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ) ??
              {},
        );

        // Record current time — only notify for messages AFTER this moment
        _lastSeenTimestamp[conversationId] = DateTime.now();

        // Subscribe to new messages — no orderBy to avoid index requirement.
        // We use snapshots with docChanges to detect only newly ADDED messages.
        final sub = FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .snapshots()
            .listen((msgSnap) {
          // Only look at documents that were just added (not existing ones)
          for (final change in msgSnap.docChanges) {
            if (change.type != DocumentChangeType.added) continue;

            final msgData = change.doc.data();
            if (msgData == null) continue;

            final senderId = msgData['senderId']?.toString() ?? '';
            final text = msgData['text']?.toString() ?? '';

            // Ignore messages sent by ME
            if (senderId == userId) continue;

            // Parse timestamp
            DateTime msgTime;
            final ts = msgData['timestamp'];
            if (ts is Timestamp) {
              msgTime = ts.toDate();
            } else {
              // No timestamp yet (optimistic write) — treat as now
              msgTime = DateTime.now();
            }

            // Ignore messages older than when we started listening
            // (prevents notifying on historical messages during initial load)
            final lastSeen = _lastSeenTimestamp[conversationId];
            if (lastSeen != null && msgTime.isBefore(lastSeen)) continue;

            // Update last seen
            _lastSeenTimestamp[conversationId] = msgTime;

            // Get sender display name from conversation's participantNames
            final senderName = names[senderId] ?? 'New message';

            // Show local notification on THIS device
            showChatNotification(
              senderName: senderName,
              message: text,
              conversationId: conversationId,
              otherUserId: senderId,
            );
          }
        }, onError: (e) {
          debugPrint('Message listener error for $conversationId: $e');
        });

        _messageSubscriptions[conversationId] = sub;
      }
    }, onError: (e) {
      debugPrint('Conversations listener error: $e');
    });
  }

  /// Stop all Firestore message listeners (call on logout).
  Future<void> stopListeningForMessages() async {
    await _conversationsSubscription?.cancel();
    _conversationsSubscription = null;
    for (final sub in _messageSubscriptions.values) {
      await sub.cancel();
    }
    _messageSubscriptions.clear();
    _lastSeenTimestamp.clear();
    _currentUserId = null;
  }

  /// Show a local notification for a new chat message.

  /// Call this from ChatService when a message is sent.
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String conversationId,
    required String otherUserId,
  }) async {
    // Don't notify if the user is currently viewing this conversation
    if (_activeChatConversationId == conversationId) return;

    final notifId = conversationId.hashCode.abs() % 100000;

    await _localNotifications.show(
      notifId,
      '💬 $senderName',
      message.length > 100 ? '${message.substring(0, 97)}...' : message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'mentora_chat_channel',
          'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(message),
          category: AndroidNotificationCategory.message,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'chat:$conversationId:$otherUserId',
    );
  }

  // Track the currently open chat so we suppress notifications for it
  String? _activeChatConversationId;

  void setActiveChatConversation(String? conversationId) {
    _activeChatConversationId = conversationId;
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
      );

      print('✅ FCM token saved: ${token.substring(0, 20)}...');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Call this right after login to show a local notification for pending requests.
  Future<void> checkPendingRequestsOnLogin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('mentorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();
      final count = snapshot.docs.length;
      if (count == 0) return;
      final docs = List.of(snapshot.docs)
        ..sort((a, b) {
          final aT = a.data()['createdAt'] as Timestamp?;
          final bT = b.data()['createdAt'] as Timestamp?;
          if (aT == null || bT == null) return 0;
          return bT.compareTo(aT);
        });
      final latest = docs.first.data();
      final requester = latest['requesterName']?.toString() ?? 'Someone';
      final skill = latest['skillName']?.toString() ?? 'a skill';
      final title = count == 1 ? '🎓 New skill request!' : '🎓 $count pending requests!';
      final body = count == 1
          ? '$requester wants to learn $skill from you'
          : 'Latest: $requester wants to learn $skill';
      await _localNotifications.show(
        99901,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mentora_channel', 'Mentora Notifications',
            channelDescription: 'Notifications for Mentora app',
            importance: Importance.high, priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'pending_requests',
      );
    } catch (e) {
      print('Error checking pending requests on login: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle terminated state messages
    _handleTerminatedMessage();
  }

  /// Handle foreground messages (app is open)

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Local notification
    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? '',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mentora_channel',
          'Mentora Notifications',
          channelDescription: 'Notifications for Mentora app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['type']?.toString(),
    );

    // In-app banner
    final context = navigatorKey.currentContext;
    if (context != null) {
    showToast(
      notification.body ?? '',
      context: navigatorKey.currentContext!,
      animation: StyledToastAnimation.slideFromTop,
      reverseAnimation: StyledToastAnimation.slideToTop,
      position: StyledToastPosition.top,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.blueAccent,
      textStyle: const TextStyle(color: Colors.white),
    );
  }
  }

  /// Handle background messages (app in background)
  void _handleBackgroundMessage(RemoteMessage message) {
    print('📬 Background message opened: ${message.notification?.title}');
    _navigateBasedOnNotification(message.data);
  }

  /// Handle terminated state messages
  Future<void> _handleTerminatedMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      print('📬 Terminated message opened: ${message.notification?.title}');
      _navigateBasedOnNotification(message.data);
    }
  }

  /// Navigate based on notification type
  void _navigateBasedOnNotification(Map<String, dynamic> data) {
    final type = data['type'];
    final requestId = data['requestId'];

    if (type == 'new_request') {
      navigatorKey.currentState?.pushNamed(
        '/request-details',
        arguments: requestId,
      );
    } else if (type == 'request_accepted') {
      navigatorKey.currentState?.pushNamed('/my-requests');
    }
    // Chat notifications handled via payload in _onNotificationTapped
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    print('📬 Notification tapped with payload: $payload');

    // chat:conversationId:otherUserId
    if (payload.startsWith('chat:')) {
      final parts = payload.split(':');
      if (parts.length >= 3) {
        final conversationId = parts[1];
        final otherUserId = parts[2];
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        // Push to chat screen
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => _ChatScreenPlaceholder(
              conversationId: conversationId,
              currentUserId: currentUser.uid,
              otherUserId: otherUserId,
            ),
          ),
        );
      }
    } else if (payload == 'pending_requests') {
      navigatorKey.currentState?.pushNamed('/requests');
    }
  }

  /// Send notification to specific user (call this from Cloud Functions)
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) {
        print('⚠️ No FCM token for user $userId');
        return;
      }

      // Create notification document for Cloud Functions to process
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      print('✅ Notification queued for user $userId');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  /// Helper method to send request notifications
  static Future<void> notifyNewRequest({
    required String mentorId,
    required String studentName,
    required String skillName,
    required String requestId,
  }) async {
    await sendNotificationToUser(
      userId: mentorId,
      title: 'New Request from $studentName',
      body: 'Wants to learn $skillName',
      data: {'type': 'new_request', 'requestId': requestId},
    );
  }

  /// Helper method to send request accepted notification
  static Future<void> notifyRequestAccepted({
    required String studentId,
    required String mentorName,
    required String skillName,
    required String requestId,
  }) async {
    await sendNotificationToUser(
      userId: studentId,
      title: 'Request Accepted! 🎉',
      body: '$mentorName accepted your request for $skillName',
      data: {'type': 'request_accepted', 'requestId': requestId},
    );
  }

  /// Helper method to send session reminder
  static Future<void> notifySessionReminder({
    required String userId,
    required String mentorName,
    required String skillName,
    required DateTime sessionDate,
    required String requestId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Session Reminder',
      body: 'Session with $mentorName for $skillName tomorrow',
      data: {'type': 'session_reminder', 'requestId': requestId},
    );
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 Background message: ${message.notification?.title}');
}

/// Helper widget: fetches conversation details then opens ChatScreen.
/// Used when user taps a chat notification.
class _ChatScreenPlaceholder extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String otherUserId;

  const _ChatScreenPlaceholder({
    required this.conversationId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<_ChatScreenPlaceholder> createState() => _ChatScreenPlaceholderState();
}

class _ChatScreenPlaceholderState extends State<_ChatScreenPlaceholder> {
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      final data = userDoc.data() ?? {};
      final name =
          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
      final photo = data['profileImageUrl']?.toString() ?? '';

      if (!mounted) return;
      // Replace this placeholder with the real ChatScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: widget.conversationId,
            currentUserId: widget.currentUserId,
            otherUserId: widget.otherUserId,
            otherUserName: name.isNotEmpty ? name : 'User',
            otherUserPhoto: photo,
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}