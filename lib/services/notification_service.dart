import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:mentora/main.dart';

/// Service for handling push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

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
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      print('📬 Notification tapped with payload: $payload');
      // TODO: Navigate based on payload
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
