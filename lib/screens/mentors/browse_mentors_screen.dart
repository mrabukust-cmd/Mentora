import 'package:flutter/material.dart';
import 'package:mentora/screens/mentors/mentor_detail.dart';
import 'package:mentora/screens/mentors/search_filter_screen.dart';
import 'package:mentora/services/matching_service.dart';

class BrowseMentorsScreen extends StatefulWidget {
  const BrowseMentorsScreen({super.key});

  @override
  State<BrowseMentorsScreen> createState() => _BrowseMentorsScreenState();
}

class _BrowseMentorsScreenState extends State<BrowseMentorsScreen> {
  final MatchingService _matchingService = MatchingService();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _mutualMatchOnly = false;
  bool _isLoading = true;
  String? _sortBy = 'match'; // 'match', 'rating', 'name'

  List<Map<String, dynamic>> _allMentors = [];
  List<String> _categories = ['All'];

  Map<String, dynamic>? _currentFilters;

  @override
  void initState() {
    super.initState();
    _loadMentors();
  }

  Future<void> _loadMentors() async {
    setState(() => _isLoading = true);
    try {
      final mentors = await _matchingService.getMutuallyMatchedMentors();
      final categorySet = <String>{'All'};
      for (final m in mentors) {
        for (final skill in (m['skillsOffered'] as List)) {
          final cat = (skill as Map)['category']?.toString();
          if (cat != null && cat.isNotEmpty) categorySet.add(cat);
        }
      }
      if (mounted) {
        setState(() {
          _allMentors = mentors;
          _categories = categorySet.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mentors: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredMentors {
    return _allMentors.where((mentor) {
      // Mutual match filter
      if (_mutualMatchOnly && !(mentor['isMutualMatch'] as bool)) return false;

      // Category filter
      if (_selectedCategory != 'All') {
        final hasCategory = (mentor['skillsOffered'] as List).any(
          (s) => (s as Map)['category']?.toString() == _selectedCategory,
        );
        if (!hasCategory) return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name =
            '${mentor['firstName']} ${mentor['lastName']}'.toLowerCase();
        final hasSkill = (mentor['skillsOffered'] as List).any(
          (s) =>
              (s as Map)['name']?.toString().toLowerCase().contains(q) ?? false,
        );
        if (!name.contains(q) && !hasSkill) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_sortBy == 'rating') {
          return (b['rating'] as double).compareTo(a['rating'] as double);
        }
        if (_sortBy == 'name') {
          return '${a['firstName']} ${a['lastName']}'
              .compareTo('${b['firstName']} ${b['lastName']}');
        }
        // Default: mutual matches first, then by match score, then rating
        final aMutual = (a['isMutualMatch'] as bool) ? 1 : 0;
        final bMutual = (b['isMutualMatch'] as bool) ? 1 : 0;
        if (bMutual != aMutual) return bMutual.compareTo(aMutual);
        final scoreCompare =
            (b['matchScore'] as int).compareTo(a['matchScore'] as int);
        if (scoreCompare != 0) return scoreCompare;
        return (b['rating'] as double).compareTo(a['rating'] as double);
      });
  }

  bool get _hasActiveFilters =>
      _mutualMatchOnly ||
      _selectedCategory != 'All' ||
      _searchQuery.isNotEmpty ||
      _sortBy != 'match';

  Future<void> _openFilterScreen() async {
    final filters = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchFilterScreen(initialFilters: _currentFilters),
      ),
    );
    if (filters != null && mounted) {
      setState(() {
        _currentFilters = filters;
        _selectedCategory = filters['category'] ?? 'All';
        _sortBy = filters['sortBy'] ?? 'match';
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _currentFilters = null;
      _selectedCategory = 'All';
      _searchQuery = '';
      _mutualMatchOnly = false;
      _sortBy = 'match';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Find Mentors'),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _openFilterScreen,
                tooltip: 'Filters',
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMentors,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or skill...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1F1F2E) : Colors.white,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ── Mutual match toggle ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _mutualMatchOnly = !_mutualMatchOnly),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _mutualMatchOnly
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF6C63FF),
                                  Color(0xFF00D4FF),
                                ],
                              )
                            : null,
                        color: _mutualMatchOnly
                            ? null
                            : (isDark
                                ? const Color(0xFF1F1F2E)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mutualMatchOnly
                              ? Colors.transparent
                              : const Color(0xFF6C63FF).withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 18,
                            color: _mutualMatchOnly
                                ? Colors.white
                                : const Color(0xFF6C63FF),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mutual Match Only',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _mutualMatchOnly
                                  ? Colors.white
                                  : const Color(0xFF6C63FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Category chips ──────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final selected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                    selectedColor: const Color(0xFF6C63FF),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // ── Results count ────────────────────────────────────
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${_filteredMentors.length} mentor${_filteredMentors.length == 1 ? '' : 's'} found',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (_filteredMentors
                      .any((m) => m['isMutualMatch'] as bool)) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz_rounded,
                              size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${_filteredMentors.where((m) => m['isMutualMatch'] as bool).length} mutual',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // ── Mentor list ──────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMentors.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadMentors,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _filteredMentors.length,
                          itemBuilder: (context, index) =>
                              _buildMentorCard(_filteredMentors[index], isDark),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor, bool isDark) {
    final isMutual = mentor['isMutualMatch'] as bool;
    final skills = mentor['skillsOffered'] as List;
    final rating = mentor['rating'] as double;
    final location = [mentor['city'], mentor['state'], mentor['country']]
        .where((s) => s.toString().trim().isNotEmpty)
        .join(', ');

    final skillsTheyCanTeach =
        List<String>.from(mentor['skillsTheyCanTeachMe'] ?? []);
    final skillsICanTeach =
        List<String>.from(mentor['skillsICanTeachThem'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isMutual
            ? BorderSide(
                color: const Color(0xFF6C63FF).withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      elevation: isMutual ? 4 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MentorDetailsScreen(
              mentorId: mentor['id'],
              mentorData: mentor,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        const Color(0xFF6C63FF).withOpacity(0.15),
                    child: Text(
                      mentor['firstName'].toString().isNotEmpty
                          ? mentor['firstName'].toString()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${mentor['firstName']} ${mentor['lastName']}'
                                    .trim(),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isMutual)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFF00D4FF)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.swap_horiz_rounded,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Mutual',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Star rating
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                                  i < rating.floor()
                                      ? Icons.star
                                      : i < rating
                                          ? Icons.star_half
                                          : Icons.star_border,
                                  size: 14,
                                  color: Colors.amber,
                                )),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            if ((mentor['totalRatings'] as int) > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${mentor['totalRatings']})',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ],
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // ── Mutual exchange section ────────────────────
              if (isMutual) ...[
                _buildExchangeRow(
                  icon: Icons.school_rounded,
                  label: 'They teach you:',
                  skills: skillsTheyCanTeach,
                  color: const Color(0xFF6C63FF),
                ),
                const SizedBox(height: 6),
                _buildExchangeRow(
                  icon: Icons.handshake_rounded,
                  label: 'You teach them:',
                  skills: skillsICanTeach,
                  color: const Color(0xFF1DD1A1),
                ),
                const SizedBox(height: 10),
              ] else ...[
                // Non-mutual: just show their skills
                Row(
                  children: [
                    Icon(Icons.school,
                        size: 15, color: Colors.blueAccent.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Text(
                      '${skills.length} skill${skills.length == 1 ? '' : 's'} offered',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills.take(3).map((skill) {
                    return _skillChip(
                        (skill as Map)['name']?.toString() ?? '', Colors.blueAccent);
                  }).toList(),
                ),
                if (skills.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('+${skills.length - 3} more',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic)),
                  ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeRow({
    required IconData icon,
    required String label,
    required List<String> skills,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: skills
                .take(3)
                .map((s) => _skillChip(
                      s[0].toUpperCase() + s.substring(1),
                      color,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _skillChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded,
                    size: 56, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(height: 20),
              Text(
                _mutualMatchOnly
                    ? 'No mutual matches found'
                    : 'No mentors found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _mutualMatchOnly
                    ? 'Add more skills to your profile to find mutual matches'
                    : 'Try adjusting your filters or search query',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}