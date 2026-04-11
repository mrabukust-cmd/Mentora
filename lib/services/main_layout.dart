// import 'package:flutter/material.dart';
// import 'package:mentora/screens/home/home_screen.dart';
// import 'package:mentora/screens/profile/profile_screen.dart';

// class MainLayout extends StatefulWidget {
//   const MainLayout({super.key});

//   @override
//   State<MainLayout> createState() => _MainLayoutState();
// }

// class _MainLayoutState extends State<MainLayout> {
//   int _currentIndex = 0;

//   final List<Widget> _screens = const [
//     HomeScreen(),
//     ChatContent(),
//     ProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Display the current screen based on selected tab
//       body: _screens[_currentIndex],

//       // Bottom navigation bar
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         selectedItemColor: Colors.blue,
//         unselectedItemColor: Colors.grey,
//         onTap: (index) {
//           setState(() => _currentIndex = index);
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: 'Chat',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ------------------- Chat Content -------------------
// class ChatContent extends StatelessWidget {
//   const ChatContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const SafeArea(
//       child: Center(
//         child: Text(
//           "Chat Screen Content Here",
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
//         ),
//       ),
//     );
//   }
// }
