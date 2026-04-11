// providers/home_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide debugPrint;
import 'package:mentora/services/home_service.dart' hide debugPrint;
import 'package:mentora/services/matching_service.dart';

class HomeProvider extends ChangeNotifier {
  final HomeService _homeService = HomeService();
  final MatchingService _matchingService = MatchingService();

  // State variables
  bool _isLoading = false;
  bool _isLoadingMentors = false;
  bool _hasData = false;
  String? _errorMessage;

  // User data
  String _firstName = 'Student';
  int _skillsOffered = 0;
  int _skillsWanted = 0;
  int _activeRequests = 0;
  int _pendingSessions = 0;
  int _completedSessions = 0;

  // Recommended mentors
  List<Map<String, dynamic>> _recommendedMentors = [];

  // Search
  String _searchQuery = '';

  // Categories
  final Map<String, Map<String, dynamic>> _categories = {
    'IT Skills': {
      'icon': Icons.computer_rounded,
      'color': Colors.blue,
      'skills': [
        'Flutter Development',
        'Frontend Web',
        'Backend Web',
        'Firebase',
        'API Integration',
        'Cloud Services',
      ],
    },
    'Programming': {
      'icon': Icons.code_rounded,
      'color': Colors.purple,
      'skills': ['Python', 'Java', 'C++', 'JavaScript', 'TypeScript', 'Dart'],
    },
    'Design': {
      'icon': Icons.palette_rounded,
      'color': Colors.pink,
      'skills': ['UI/UX Design', 'Graphic Design', 'Video Editing', 'Canva'],
    },
    'Business': {
      'icon': Icons.business_rounded,
      'color': Colors.orange,
      'skills': ['Freelancing', 'Startup Basics', 'Digital Marketing'],
    },
  };

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMentors => _isLoadingMentors;
  bool get hasData => _hasData;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  String get firstName => _firstName;
  int get skillsOffered => _skillsOffered;
  int get skillsWanted => _skillsWanted;
  int get activeRequests => _activeRequests;
  int get pendingSessions => _pendingSessions;
  int get completedSessions => _completedSessions;

  List<Map<String, dynamic>> get recommendedMentors => _recommendedMentors;
  String get searchQuery => _searchQuery;
  Map<String, Map<String, dynamic>> get categories => _categories;

  // Load all home data
  Future<void> loadHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load user data and stats in parallel
      await Future.wait([
        _loadUserData(),
        _loadRequestsStats(),
      ]);

      // Load mentors separately (non-blocking)
      _loadRecommendedMentors();

      _hasData = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading home data: $e');
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user profile data
  Future<void> _loadUserData() async {
    try {
      final userData = await _homeService.getUserData();

      _firstName = userData['firstName'] ?? 'Student';
      _skillsOffered = (userData['skillsOffered'] as List?)?.length ?? 0;
      _skillsWanted = (userData['skillsWanted'] as List?)?.length ?? 0;
      _completedSessions = userData['completedSessions'] ?? 0;
    } catch (e) {
      debugPrint('Error loading user data: $e');
      rethrow;
    }
  }

  // Load requests statistics
  Future<void> _loadRequestsStats() async {
    try {
      final stats = await _homeService.getRequestsStats();

      _activeRequests = stats['activeRequests'] ?? 0;
      _pendingSessions = stats['pendingSessions'] ?? 0;
    } catch (e) {
      debugPrint('Error loading requests stats: $e');
      rethrow;
    }
  }

  // Load recommended mentors (async, non-blocking)
  Future<void> _loadRecommendedMentors() async {
    _isLoadingMentors = true;
    notifyListeners();

    try {
      _recommendedMentors = await _matchingService.getMatchedMentors();
    } catch (e) {
      debugPrint('Error loading recommended mentors: $e');
      _recommendedMentors = [];
    } finally {
      _isLoadingMentors = false;
      notifyListeners();
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  // Get filtered categories based on search
  List<MapEntry<String, Map<String, dynamic>>> getFilteredCategories() {
    if (_searchQuery.isEmpty) return _categories.entries.toList();

    return _categories.entries.where((entry) {
      final categoryMatch = entry.key.toLowerCase().contains(_searchQuery);
      final skillsMatch = entry.value['skills'].any(
        (skill) => skill.toString().toLowerCase().contains(_searchQuery),
      );
      return categoryMatch || skillsMatch;
    }).toList();
  }

  // Get filtered skills from a category
  List<String> getFilteredSkills(List<dynamic> skills) {
    if (_searchQuery.isEmpty) return List<String>.from(skills);

    return skills
        .where((skill) => skill.toString().toLowerCase().contains(_searchQuery))
        .toList()
        .cast<String>();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network')) {
      return 'No internet connection. Please check your network.';
    } else if (errorString.contains('permission')) {
      return 'Access denied. Please check your permissions.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'Something went wrong. Pull to refresh.';
    }
  }

  // Refresh specific data
  Future<void> refreshUserData() async {
    try {
      await _loadUserData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  Future<void> refreshRequestsStats() async {
    try {
      await _loadRequestsStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing requests stats: $e');
    }
  }
}