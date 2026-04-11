import 'package:flutter/material.dart';
import 'package:mentora/screens/home/home_screen.dart';
import 'package:mentora/screens/mentors/browse_mentors_screen.dart';
import 'package:mentora/screens/skills/my_skill_screen.dart';
import 'package:mentora/request/my_request_screen.dart';
import 'package:mentora/screens/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // ✅ FIXED: Define screens as a static final list (never changes)
  static const List<Widget> _screens = [
    HomeScreen(), // 0: Home/Dashboard
    BrowseMentorsScreen(), // 1: Find Mentors
    MySkillsScreen(), // 2: My Skills
    MyRequestsScreen(), // 3: My Requests
    ProfileScreen(), // 4: Profile
  ];

  // ✅ FIXED: Define destinations as a static final list (never changes)
  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search_rounded),
      label: 'Mentors',
    ),
    NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school_rounded),
      label: 'Skills',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history_rounded),
      label: 'Requests',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: _destinations,
        animationDuration: const Duration(milliseconds: 300),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        // ✅ ADD THESE FOR BETTER CONSISTENCY
        elevation: 8,
        height: 65,
      ),
    );
  }
}
