import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentora/screens/home/home_screen.dart';
import 'package:mentora/screens/mentors/browse_mentors_screen.dart';
import 'package:mentora/screens/skills/my_skill_screen.dart';
import 'package:mentora/request/my_request_screen.dart';
import 'package:mentora/screens/profile/profile_screen.dart';
import 'package:mentora/screens/chat/chat_list_screen.dart';
import 'package:mentora/services/notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_uid == null) return;
      await NotificationService().checkPendingRequestsOnLogin();
      await NotificationService().startListeningForMessages(_uid!);
    });
  }

  @override
  void dispose() {
    NotificationService().stopListeningForMessages();
    super.dispose();
  }

  List<Widget> get _screens => [
    const HomeScreen(),
    const BrowseMentorsScreen(),
    const MySkillsScreen(),
    const MyRequestsScreen(),
    ChatListScreen(currentUserId: _uid ?? ''),
    const ProfileScreen(),
  ];

  /// Stream: total unread messages across all conversations
  Stream<int> get _unreadMessagesStream {
    if (_uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: _uid)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final unreadMap = Map<String, dynamic>.from(data['unreadCount'] ?? {});
        total += (unreadMap[_uid] as int? ?? 0);
      }
      return total;
    });
  }

  /// Stream: pending requests where I am the mentor
  Stream<int> get _pendingRequestsStream {
    if (_uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('requests')
        .where('mentorId', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _pendingRequestsStream,
      builder: (context, reqSnapshot) {
        final pendingRequests = reqSnapshot.data ?? 0;

        return StreamBuilder<int>(
          stream: _unreadMessagesStream,
          builder: (context, msgSnapshot) {
            final unreadMessages = msgSnapshot.data ?? 0;

            return Scaffold(
              body: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) =>
                    setState(() => _currentIndex = i),
                animationDuration: const Duration(milliseconds: 300),
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysShow,
                elevation: 8,
                height: 65,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.search_outlined),
                    selectedIcon: Icon(Icons.search_rounded),
                    label: 'Mentors',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.school_outlined),
                    selectedIcon: Icon(Icons.school_rounded),
                    label: 'Skills',
                  ),
                  // Requests tab with pending badge
                  NavigationDestination(
                    icon: _BadgeIcon(
                      icon: Icons.history_outlined,
                      count: pendingRequests,
                    ),
                    selectedIcon: _BadgeIcon(
                      icon: Icons.history_rounded,
                      count: pendingRequests,
                      selected: true,
                    ),
                    label: 'Requests',
                  ),
                  // Chat tab with unread messages badge
                  NavigationDestination(
                    icon: _BadgeIcon(
                      icon: Icons.chat_bubble_outline_rounded,
                      count: unreadMessages,
                    ),
                    selectedIcon: _BadgeIcon(
                      icon: Icons.chat_bubble_rounded,
                      count: unreadMessages,
                      selected: true,
                    ),
                    label: 'Chats',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Badge icon — shows a red dot with count when count > 0
class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool selected;

  const _BadgeIcon({
    required this.icon,
    required this.count,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints:
                  const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}