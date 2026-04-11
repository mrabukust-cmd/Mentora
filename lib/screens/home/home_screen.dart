// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:mentora/screens/home/home_provider.dart';
import 'package:mentora/screens/mentors/mentor_list.dart';
import 'package:mentora/widgets/error_widget.dart';
import 'package:provider/provider.dart';
import 'package:mentora/screens/mentors/browse_mentors_screen.dart';
import 'package:mentora/screens/profile/profile_screen.dart';
import 'package:mentora/screens/skills/my_skill_screen.dart';
import 'package:mentora/request/my_request_screen.dart';
import 'package:mentora/screens/mentors/mentor_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadHomeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;
    final isLargeScreen = size.width >= 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark
                ? [const Color(0xFF8B7FFF), const Color(0xFF00E5FF)]
                : [const Color(0xFF6C63FF), const Color(0xFF00D4FF)],
          ).createShader(bounds),
          child: Text(
            'Mentora',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF8B7FFF), const Color(0xFF00E5FF)]
                    : [const Color(0xFF6C63FF), const Color(0xFF00D4FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isDark
                              ? const Color(0xFF8B7FFF)
                              : const Color(0xFF6C63FF))
                          .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: isSmallScreen ? 20 : 24,
              ),
              onPressed: _navigateToProfile,
            ),
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.hasData) {
            return ModernLoadingSkeleton(isDark: isDark);
          }

          if (provider.hasError && !provider.hasData) {
            return ErrorDisplay(
              message: provider.errorMessage ?? 'Failed to load data',
              onRetry: () => provider.loadHomeData(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadHomeData(),
            color: isDark ? const Color(0xFF8B7FFF) : const Color(0xFF6C63FF),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [const Color(0xFFF8F9FF), const Color(0xFFE8F0FF)],
                ),
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeaderSection(provider, isDark, size),
                    _buildContentSection(provider, isDark, size),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(HomeProvider provider, bool isDark, Size size) {
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2D2D44), const Color(0xFF1F4068)]
              : [const Color(0xFF6C63FF), const Color(0xFF00D4FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF8B7FFF) : const Color(0xFF6C63FF))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: isSmallScreen ? 50 : 60),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : (isMediumScreen ? 20 : 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getGreetingEmoji(),
                            style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Text(
                        provider.firstName,
                        style: TextStyle(
                          fontSize: isSmallScreen
                              ? 28
                              : (isMediumScreen ? 36 : 42),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Text(
                        'What would you like to learn today?',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      _buildModernSearchBar(provider, isDark, size),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSearchBar(HomeProvider provider, bool isDark, Size size) {
    final isSmallScreen = size.width < 360;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D44) : Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (query) => provider.updateSearchQuery(query),
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search skills, mentors...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey[400],
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF8B7FFF), const Color(0xFF00E5FF)]
                    : [const Color(0xFF6C63FF), const Color(0xFF00D4FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          suffixIcon: provider.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    provider.updateSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
          contentPadding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 14 : 18,
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(HomeProvider provider, bool isDark, Size size) {
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isSmallScreen ? 16 : (isMediumScreen ? 20 : 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildAnimatedStatsGrid(provider, isDark, size),
            SizedBox(height: isSmallScreen ? 24 : 30),
            _buildQuickActions(isDark, size),
            SizedBox(height: isSmallScreen ? 24 : 30),
            _buildRecommendedMentors(provider, isDark, size),
            SizedBox(height: isSmallScreen ? 24 : 30),
            _buildExploreSkills(provider, isDark, size),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStatsGrid(
    HomeProvider provider,
    bool isDark,
    Size size,
  ) {
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Journey',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : (isMediumScreen ? 22 : 26),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3142),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Row(
          children: [
            _buildGlassStatCard(
              label: 'Skills Offered',
              value: provider.skillsOffered,
              icon: Icons.workspace_premium_rounded,
              gradient: isDark
                  ? [const Color(0xFF8B7FFF), const Color(0xFF6B5FD5)]
                  : [const Color(0xFF6C63FF), const Color(0xFF5A52D5)],
              isDark: isDark,
              size: size,
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            _buildGlassStatCard(
              label: 'Learning',
              value: provider.skillsWanted,
              icon: Icons.emoji_objects_rounded,
              gradient: isDark
                  ? [const Color(0xFFFF7BAD), const Color(0xFFD07C94)]
                  : [const Color(0xFFFF6B9D), const Color(0xFFC06C84)],
              isDark: isDark,
              size: size,
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Row(
          children: [
            _buildGlassStatCard(
              label: 'Active',
              value: provider.activeRequests,
              icon: Icons.rocket_launch_rounded,
              gradient: isDark
                  ? [const Color(0xFF00E5FF), const Color(0xFF00AACC)]
                  : [const Color(0xFF00D4FF), const Color(0xFF0099CC)],
              isDark: isDark,
              size: size,
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            _buildGlassStatCard(
              label: 'Completed',
              value: provider.completedSessions,
              icon: Icons.verified_rounded,
              gradient: isDark
                  ? [const Color(0xFF2EE1B1), const Color(0xFF20BC94)]
                  : [const Color(0xFF1DD1A1), const Color(0xFF10AC84)],
              isDark: isDark,
              size: size,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassStatCard({
    required String label,
    required int value,
    required IconData icon,
    required List<Color> gradient,
    required bool isDark,
    required Size size,
  }) {
    final isSmallScreen = size.width < 360;

    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, animation, child) {
          return Transform.scale(
            scale: 0.8 + (animation * 0.2),
            child: Opacity(
              opacity: animation,
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
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

  Widget _buildQuickActions(bool isDark, Size size) {
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;

    final actions = [
      {
        'icon': Icons.explore_rounded,
        'label': 'Find Mentors',
        'gradient': isDark
            ? [const Color(0xFF8B7FFF), const Color(0xFF6B5FD5)]
            : [const Color(0xFF6C63FF), const Color(0xFF5A52D5)],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BrowseMentorsScreen()),
        ),
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'label': 'My Skills',
        'gradient': isDark
            ? [const Color(0xFF2EE1B1), const Color(0xFF20BC94)]
            : [const Color(0xFF1DD1A1), const Color(0xFF10AC84)],
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MySkillsScreen()),
          );
          if (mounted) context.read<HomeProvider>().loadHomeData();
        },
      },
      {
        'icon': Icons.history_rounded,
        'label': 'Requests',
        'gradient': isDark
            ? [const Color(0xFFFF7BAD), const Color(0xFFD07C94)]
            : [const Color(0xFFFF6B9D), const Color(0xFFC06C84)],
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
          );
          if (mounted) context.read<HomeProvider>().loadHomeData();
        },
      },
      {
        'icon': Icons.person_rounded,
        'label': 'Profile',
        'gradient': isDark
            ? [const Color(0xFF00E5FF), const Color(0xFF00AACC)]
            : [const Color(0xFF00D4FF), const Color(0xFF0099CC)],
        'onTap': _navigateToProfile,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : (isMediumScreen ? 22 : 26),
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3142),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: isSmallScreen ? 1.2 : 1.3,
            crossAxisSpacing: isSmallScreen ? 8 : 12,
            mainAxisSpacing: isSmallScreen ? 8 : 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              gradient: action['gradient'] as List<Color>,
              onTap: action['onTap'] as VoidCallback,
              delay: index * 100,
              isDark: isDark,
              size: size,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
    required int delay,
    required bool isDark,
    required Size size,
  }) {
    final isSmallScreen = size.width < 360;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: 0.8 + (animation * 0.2),
          child: Opacity(
            opacity: animation,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient
                          .map((c) => c.withOpacity(isDark ? 0.15 : 0.1))
                          .toList(),
                    ),
                    borderRadius: BorderRadius.circular(
                      isSmallScreen ? 16 : 20,
                    ),
                    border: Border.all(
                      color: gradient[0].withOpacity(isDark ? 0.4 : 0.3),
                      width: 1.5,
                    ),
                  ),
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  // child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradient),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: gradient[0].withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: isSmallScreen ? 24 : 28,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : gradient[0],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildRecommendedMentors(
    HomeProvider provider,
    bool isDark,
    Size size,
  ) {
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF8B7FFF), const Color(0xFF00E5FF)]
                      : [const Color(0xFF6C63FF), const Color(0xFF00D4FF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.stars_rounded,
                color: Colors.white,
                size: isSmallScreen ? 18 : 20,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Text(
              'Top Mentors',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : (isMediumScreen ? 22 : 26),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2D3142),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (provider.isLoadingMentors)
          _buildMentorLoadingSkeleton(isDark, size)
        else if (provider.recommendedMentors.isEmpty)
          _buildEmptyMentorsCard(isDark, size)
        else
          SizedBox(
            height: isSmallScreen ? 220 : (isMediumScreen ? 240 : 260),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.recommendedMentors.length,
              itemBuilder: (context, index) {
                return _buildMentorCard(
                  provider.recommendedMentors[index],
                  index,
                  isDark,
                  size,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMentorCard(
    Map<String, dynamic> mentor,
    int index,
    bool isDark,
    Size size,
  ) {
    final isSmallScreen = size.width < 360;

    final gradients = isDark
        ? [
            [const Color(0xFF8B7FFF), const Color(0xFF6B5FD5)],
            [const Color(0xFF2EE1B1), const Color(0xFF20BC94)],
            [const Color(0xFFFF7BAD), const Color(0xFFD07C94)],
            [const Color(0xFF00E5FF), const Color(0xFF00AACC)],
          ]
        : [
            [const Color(0xFF6C63FF), const Color(0xFF5A52D5)],
            [const Color(0xFF1DD1A1), const Color(0xFF10AC84)],
            [const Color(0xFFFF6B9D), const Color(0xFFC06C84)],
            [const Color(0xFF00D4FF), const Color(0xFF0099CC)],
          ];
    final gradient = gradients[index % gradients.length];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: 0.8 + (animation * 0.2),
          child: Opacity(
            opacity: animation,
            child: Container(
              width: isSmallScreen ? 180 : 200,
              margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F2E) : Colors.white,
                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MentorDetailsScreen(
                        mentorId: mentor['mentorId'] ?? '',
                        mentorData: {
                          'firstName': (mentor['name'] as String).split(' ').first,
                          'lastName': (mentor['name'] as String).split(' ').length > 1
                              ? (mentor['name'] as String).split(' ').sublist(1).join(' ')
                              : '',
                          'email': mentor['email'] ?? '',
                          'city': mentor['city'] ?? '',
                          'state': mentor['state'] ?? '',
                          'country': mentor['country'] ?? '',
                          'skillsOffered': mentor['skillsOffered'] ?? [
                            {'name': mentor['skill'], 'category': mentor['category'] ?? '', 'level': ''}
                          ],
                          'rating': mentor['rating'] ?? 0.0,
                          'totalRatings': mentor['totalRatings'] ?? 0,
                        },
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: isSmallScreen ? 55 : 60,
                          height: isSmallScreen ? 55 : 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradient),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: gradient[0].withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              mentor['name'][0].toUpperCase(),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Text(
                          mentor['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 16 : 18,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF2D3142),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          mentor['skill'],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: isSmallScreen ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(
                                  isDark ? 0.2 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: isSmallScreen ? 14 : 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mentor['rating'].toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: gradient),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMentorLoadingSkeleton(bool isDark, Size size) {
    final isSmallScreen = size.width < 360;

    return SizedBox(
      height: isSmallScreen ? 220 : 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: isSmallScreen ? 180 : 200,
            margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D44) : Colors.grey[200],
              borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyMentorsCard(bool isDark, Size size) {
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 32 : 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF8B7FFF).withOpacity(0.15),
                  const Color(0xFF00E5FF).withOpacity(0.15),
                ]
              : [
                  const Color(0xFF6C63FF).withOpacity(0.05),
                  const Color(0xFF00D4FF).withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
        border: Border.all(
          color: (isDark ? const Color(0xFF8B7FFF) : const Color(0xFF6C63FF))
              .withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF8B7FFF), const Color(0xFF00E5FF)]
                    : [const Color(0xFF6C63FF), const Color(0xFF00D4FF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.people_outline,
              size: isSmallScreen ? 36 : 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            'No mentors available yet',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'Check back later or add skills to help others',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreSkills(HomeProvider provider, bool isDark, Size size) {
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;
    final filteredCategories = provider.getFilteredCategories();

    if (filteredCategories.isEmpty && provider.searchQuery.isNotEmpty) {
      return _buildNoSearchResults(isDark, size);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFFFF7BAD), const Color(0xFFD07C94)]
                      : [const Color(0xFFFF6B9D), const Color(0xFFC06C84)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.explore_rounded,
                color: Colors.white,
                size: isSmallScreen ? 18 : 20,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Text(
              'Explore Skills',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : (isMediumScreen ? 22 : 26),
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2D3142),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        ...filteredCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final mapEntry = entry.value;
          final categoryName = mapEntry.key;
          final categoryData = mapEntry.value;
          final filteredSkills = provider.getFilteredSkills(
            categoryData['skills'],
          );

          if (filteredSkills.isEmpty) return const SizedBox.shrink();

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, animation, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - animation)),
                child: Opacity(
                  opacity: animation,
                  child: Container(
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F1F2E) : Colors.white,
                      borderRadius: BorderRadius.circular(
                        isSmallScreen ? 16 : 20,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (categoryData['color'] as Color).withOpacity(
                            0.1,
                          ),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                categoryData['color'] as Color,
                                (categoryData['color'] as Color).withOpacity(
                                  0.7,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: (categoryData['color'] as Color)
                                    .withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            categoryData['icon'] as IconData,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : 24,
                          ),
                        ),
                        title: Text(
                          categoryName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF2D3142),
                          ),
                        ),
                        subtitle: Text(
                          '${filteredSkills.length} ${filteredSkills.length == 1 ? 'skill' : 'skills'}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        children: filteredSkills.asMap().entries.map((
                          skillEntry,
                        ) {
                          final skillIndex = skillEntry.key;
                          final skill = skillEntry.value;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 300 + (skillIndex * 50),
                            ),
                            builder: (context, anim, child) {
                              return Transform.translate(
                                offset: Offset(20 * (1 - anim), 0),
                                child: Opacity(
                                  opacity: anim,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          (categoryData['color'] as Color)
                                              .withOpacity(isDark ? 0.1 : 0.05),
                                          (categoryData['color'] as Color)
                                              .withOpacity(
                                                isDark ? 0.05 : 0.02,
                                              ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: EdgeInsets.all(
                                          isSmallScreen ? 8 : 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (categoryData['color'] as Color)
                                                  .withOpacity(
                                                    isDark ? 0.2 : 0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.auto_awesome_rounded,
                                          size: isSmallScreen ? 18 : 20,
                                          color: categoryData['color'] as Color,
                                        ),
                                      ),
                                      title: Text(
                                        skill,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallScreen ? 14 : 15,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: EdgeInsets.all(
                                          isSmallScreen ? 6 : 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              categoryData['color'] as Color,
                                              (categoryData['color'] as Color)
                                                  .withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          size: isSmallScreen ? 14 : 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MentorListScreen(skill: skill),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNoSearchResults(bool isDark, Size size) {
    final isSmallScreen = size.width < 360;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 32 : 40),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF8B7FFF).withOpacity(0.2),
                        const Color(0xFF00E5FF).withOpacity(0.2),
                      ]
                    : [
                        const Color(0xFF6C63FF).withOpacity(0.1),
                        const Color(0xFF00D4FF).withOpacity(0.1),
                      ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: isSmallScreen ? 50 : 60,
              color: isDark ? const Color(0xFF8B7FFF) : const Color(0xFF6C63FF),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            'No skills found',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'Try different keywords',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    if (mounted) {
      context.read<HomeProvider>().loadHomeData();
    }
  }
}

// Modern Loading Skeleton
class ModernLoadingSkeleton extends StatefulWidget {
  final bool isDark;

  const ModernLoadingSkeleton({super.key, required this.isDark});

  @override
  State<ModernLoadingSkeleton> createState() => _ModernLoadingSkeletonState();
}

class _ModernLoadingSkeletonState extends State<ModernLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [const Color(0xFFF8F9FF), const Color(0xFFE8F0FF)],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: isSmallScreen ? 260 : 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isDark
                      ? [const Color(0xFF2D2D44), const Color(0xFF1F4068)]
                      : [const Color(0xFF6C63FF), const Color(0xFF00D4FF)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isSmallScreen ? 50 : 60),
                      _buildShimmerBox(120, 20, Colors.white30),
                      const SizedBox(height: 8),
                      _buildShimmerBox(200, 36, Colors.white30),
                      const SizedBox(height: 24),
                      _buildShimmerBox(double.infinity, 56, Colors.white30),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF0F0F1E) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildShimmerBox(
                            double.infinity,
                            isSmallScreen ? 110 : 120,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: _buildShimmerBox(
                            double.infinity,
                            isSmallScreen ? 110 : 120,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: isSmallScreen ? 8 : 12,
                      mainAxisSpacing: isSmallScreen ? 8 : 12,
                      childAspectRatio: isSmallScreen ? 1.4 : 1.5,
                      children: List.generate(
                        4,
                        (index) =>
                            _buildShimmerBox(double.infinity, double.infinity),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height, [Color? baseColor]) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerColor =
            baseColor ??
            (widget.isDark ? const Color(0xFF2D2D44) : Colors.grey[200]!);
        final shimmerHighlight =
            baseColor?.withOpacity(0.5) ??
            (widget.isDark ? const Color(0xFF3D3D54) : Colors.grey[100]!);

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [shimmerColor, shimmerHighlight, shimmerColor],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}