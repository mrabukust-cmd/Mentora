import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentora/screens/home/home_screen.dart';
import 'package:mentora/screens/mentors/browse_mentors_screen.dart';
import 'package:mentora/screens/skills/my_skill_screen.dart';
import 'package:mentora/request/my_request_screen.dart';
import 'package:mentora/screens/profile/profile_screen.dart';
import 'package:mentora/services/notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Show notification for pending requests on login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkPendingRequestsOnLogin();
    });
  }

  static const List<Widget> _screens = [
    HomeScreen(),
    BrowseMentorsScreen(),
    MySkillsScreen(),
    MyRequestsScreen(),
    ProfileScreen(),
  ];

  Stream<int> get _pendingRequestsStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('requests')
        .where('mentorId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _pendingRequestsStream,
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;
        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            animationDuration: const Duration(milliseconds: 300),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
              NavigationDestination(
                icon: _BadgeIcon(icon: Icons.history_outlined, count: pendingCount),
                selectedIcon: _BadgeIcon(icon: Icons.history_rounded, count: pendingCount, selected: true),
                label: 'Requests',
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
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool selected;
  const _BadgeIcon({required this.icon, required this.count, this.selected = false});

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
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}