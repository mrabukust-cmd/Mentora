import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mentora/request/my_request_screen.dart';
import 'package:mentora/request/request_history_screen.dart';
import 'package:mentora/screens/auth/main_auth.dart';
import 'package:mentora/screens/profile/edit_profile.dart';
import 'package:mentora/screens/skills/my_skill_screen.dart';
import 'package:mentora/setting/setting.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  // User data
  String firstName = '';
  String lastName = '';
  String email = '';
  String location = '';
  String? profileImageUrl;

  // Stats
  int skillsOffered = 0;
  int skillsWanted = 0;
  int sentRequests = 0;
  int receivedRequests = 0;
  int completedSessions = 0;

  double userRating = 0.0;
  int totalRatings = 0;

  bool isLoading = true;
  bool isUploadingImage = false;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Animation controllers
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _actionsController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _statsScale;
  late Animation<double> _actionsFade;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadProfileData();
  }

  void _initAnimations() {
    // Header animations
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    // Stats animations
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _statsScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.elasticOut),
    );

    // Actions animations
    _actionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _actionsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _actionsController, curve: Curves.easeIn),
    );
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([
        _fetchUserInfo(),
        _fetchRequestsCount(),
      ]);

      if (mounted) {
        setState(() => isLoading = false);
        // Start animations
        _headerController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _statsController.forward();
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _actionsController.forward();
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading profile: $e");
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar('Failed to load profile data');
      }
    }
  }

  Future<void> _fetchUserInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!doc.exists) {
        debugPrint("❌ User document not found");
        return;
      }

      final data = doc.data()!;

      if (mounted) {
        setState(() {
          firstName = data['firstName'] ?? 'No Name';
          lastName = data['lastName'] ?? '';
          email = FirebaseAuth.instance.currentUser?.email ?? 'No Email';
          profileImageUrl = data['profileImageUrl'] as String?;

          location = _buildLocationString(
            data['city'] as String?,
            data['state'] as String?,
            data['country'] as String?,
          );

          final offeredSkills = data['skillsOffered'] as List<dynamic>? ?? [];
          final wantedSkills = data['skillsWanted'] as List<dynamic>? ?? [];
          skillsOffered = offeredSkills.length;
          skillsWanted = wantedSkills.length;

          completedSessions = (data['completedSessions'] as int?) ?? 0;
          userRating = (data['rating'] ?? 0.0) as double;
          totalRatings = (data['totalRatings'] ?? 0) as int;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching user info: $e");
      rethrow;
    }
  }

  Future<void> _fetchRequestsCount() async {
    try {
      final sentSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('requesterId', isEqualTo: currentUserId)
          .where('status', whereIn: ['pending', 'accepted']).get();

      final receivedSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('mentorId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          sentRequests = sentSnapshot.docs.length;
          receivedRequests = receivedSnapshot.docs.length;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching requests count: $e");
      rethrow;
    }
  }

  String _buildLocationString(String? city, String? state, String? country) {
    final parts = <String>[];
    if (city?.trim().isNotEmpty ?? false) parts.add(city!.trim());
    if (state?.trim().isNotEmpty ?? false) parts.add(state!.trim());
    if (country?.trim().isNotEmpty ?? false) parts.add(country!.trim());
    return parts.join(', ');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Choose Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.purple),
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (profileImageUrl != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      await _uploadProfileImage(File(image.path));
    } catch (e) {
      debugPrint("❌ Error picking image: $e");
      _showErrorSnackBar('Failed to pick image');
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    setState(() => isUploadingImage = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$currentUserId.jpg');

      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'profileImageUrl': downloadUrl});

      if (mounted) {
        setState(() {
          profileImageUrl = downloadUrl;
          isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error uploading image: $e");
      if (mounted) {
        setState(() => isUploadingImage = false);
        _showErrorSnackBar('Failed to upload image');
      }
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() => isUploadingImage = true);

    try {
      if (profileImageUrl != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$currentUserId.jpg');
        await storageRef.delete();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'profileImageUrl': FieldValue.delete()});

      if (mounted) {
        setState(() {
          profileImageUrl = null;
          isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error removing image: $e");
      if (mounted) {
        setState(() => isUploadingImage = false);
        _showErrorSnackBar('Failed to remove image');
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainAuth()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to logout: $e');
      }
    }
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 500 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.1),
                      Colors.white,
                    ],
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 32),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<int>(
                      duration: const Duration(milliseconds: 1000),
                      tween: IntTween(begin: 0, end: count),
                      builder: (context, value, child) {
                        return Text(
                          value.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionItem({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        iconColor.withOpacity(0.05),
                        Colors.white,
                      ],
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 60),
                              Hero(
                                tag: 'profile_image',
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: isSmallScreen ? 55 : 65,
                                        backgroundColor: Colors.white,
                                        backgroundImage: profileImageUrl != null
                                            ? NetworkImage(profileImageUrl!)
                                            : null,
                                        child: profileImageUrl == null
                                            ? Text(
                                                firstName.isNotEmpty
                                                    ? firstName[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen
                                                      ? 40
                                                      : 48,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    if (isUploadingImage)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.black.withOpacity(0.5),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: isUploadingImage
                                            ? null
                                            : _showImageSourceDialog,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.camera_alt,
                                            size: 20,
                                            color: Theme.of(context)
                                                .primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '$firstName $lastName'.trim(),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 24 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 15,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 16, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        location,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (totalRatings > 0) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${userRating.toStringAsFixed(1)} ($totalRatings ${totalRatings == 1 ? 'review' : 'reviews'})',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _headerController.reset();
                        _statsController.reset();
                        _actionsController.reset();
                        _loadProfileData();
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: ScaleTransition(
                    scale: _statsScale,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistics',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildStatCard(
                                label: 'Skills Offered',
                                count: skillsOffered,
                                icon: Icons.school,
                                color: Colors.blueAccent,
                                index: 0,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                label: 'Skills Wanted',
                                count: skillsWanted,
                                icon: Icons.lightbulb,
                                color: Colors.orange,
                                index: 1,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatCard(
                                label: 'Sent',
                                count: sentRequests,
                                icon: Icons.send,
                                color: Colors.purple,
                                index: 2,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                label: 'Received',
                                count: receivedRequests,
                                icon: Icons.inbox,
                                color: Colors.teal,
                                index: 3,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                label: 'Completed',
                                count: completedSessions,
                                icon: Icons.check_circle,
                                color: Colors.green,
                                index: 4,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          FadeTransition(
                            opacity: _actionsFade,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildActionItem(
                                  label: 'Edit Profile',
                                  icon: Icons.edit,
                                  iconColor: Colors.blueAccent,
                                  index: 0,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                    if (result == true) {
                                      _headerController.reset();
                                      _statsController.reset();
                                      _actionsController.reset();
                                      _loadProfileData();
                                    }
                                  },
                                ),
                                _buildActionItem(
                                  label: 'My Skills',
                                  icon: Icons.school,
                                  iconColor: Colors.green,
                                  index: 1,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MySkillsScreen(),
                                      ),
                                    ).then((_) {
                                      _headerController.reset();
                                      _statsController.reset();
                                      _actionsController.reset();
                                      _loadProfileData();
                                    });
                                  },
                                ),
                                _buildActionItem(
                                  label: 'My Requests',
                                  icon: Icons.history,
                                  iconColor: Colors.orange,
                                  index: 2,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MyRequestsScreen(),
                                      ),
                                    ).then((_) {
                                      _headerController.reset();
                                      _statsController.reset();
                                      _actionsController.reset();
                                      _loadProfileData();
                                    });
                                  },
                                ),
                                _buildActionItem(
                                  label: 'Settings',
                                  icon: Icons.settings,
                                  iconColor: Colors.grey[700]!,
                                  index: 3,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SettingsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionItem(
                                  label: 'History',
                                  icon: Icons.history,
                                  iconColor: Colors.grey[700]!,
                                  index: 3,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RequestHistoryScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionItem(
                                  label: 'Logout',
                                  icon: Icons.logout,
                                  iconColor: Colors.red,
                                  index: 4,
                                  onTap: _logout,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    _actionsController.dispose();
    super.dispose();
  }
}