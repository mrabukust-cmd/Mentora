import 'package:flutter/material.dart';

class SearchFilterScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  const SearchFilterScreen({super.key, this.initialFilters});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  // Filter values
  String? selectedCategory;
  String? selectedLevel;
  RangeValues ratingRange = const RangeValues(0, 5);
  bool onlyAvailable = false;
  String sortBy = 'rating'; // rating, name, recent

  final List<String> categories = [
    'All Categories',
    'Programming',
    'Design',
    'Business',
    'Marketing',
    'Languages',
    'Science',
    'Mathematics',
    'Arts',
    'Music',
    'Sports',
  ];

  final List<String> levels = [
    'All Levels',
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];

  final List<Map<String, dynamic>> sortOptions = [
    {'value': 'rating', 'label': 'Highest Rating', 'icon': Icons.star},
    {'value': 'name', 'label': 'Name (A-Z)', 'icon': Icons.sort_by_alpha},
    {'value': 'recent', 'label': 'Most Recent', 'icon': Icons.access_time},
  ];

  @override
  void initState() {
    super.initState();
    // Load initial filters if provided
    if (widget.initialFilters != null) {
      selectedCategory = widget.initialFilters!['category'];
      selectedLevel = widget.initialFilters!['level'];
      ratingRange = widget.initialFilters!['rating'] ?? ratingRange;
      onlyAvailable = widget.initialFilters!['available'] ?? false;
      sortBy = widget.initialFilters!['sortBy'] ?? 'rating';
    }
  }

  void _applyFilters() {
    final filters = {
      'category': selectedCategory,
      'level': selectedLevel,
      'rating': ratingRange,
      'available': onlyAvailable,
      'sortBy': sortBy,
    };

    Navigator.pop(context, filters);
  }

  void _resetFilters() {
    setState(() {
      selectedCategory = null;
      selectedLevel = null;
      ratingRange = const RangeValues(0, 5);
      onlyAvailable = false;
      sortBy = 'rating';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Filters'),
        centerTitle: true,
        actions: [
          TextButton(onPressed: _resetFilters, child: const Text('Reset')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Section
            _buildSectionTitle('Category'),
            const SizedBox(height: 12),
            _buildCategoryChips(),

            const SizedBox(height: 24),

            // Level Section
            _buildSectionTitle('Skill Level'),
            const SizedBox(height: 12),
            _buildLevelChips(),

            const SizedBox(height: 24),

            // Rating Range Section
            _buildSectionTitle('Minimum Rating'),
            const SizedBox(height: 12),
            _buildRatingSlider(),

            const SizedBox(height: 24),

            // Sort By Section
            _buildSectionTitle('Sort By'),
            const SizedBox(height: 12),
            _buildSortOptions(),

            const SizedBox(height: 24),

            // Availability Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Only Available Mentors'),
                subtitle: const Text('Show mentors accepting new students'),
                value: onlyAvailable,
                onChanged: (value) {
                  setState(() => onlyAvailable = value);
                },
                secondary: const Icon(Icons.check_circle_outline),
              ),
            ),

            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = category == selectedCategory;
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              selectedCategory = selected ? category : null;
            });
          },
          backgroundColor: Colors.grey[200],
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          checkmarkColor: Theme.of(context).primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLevelChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((level) {
        final isSelected = level == selectedLevel;
        return FilterChip(
          label: Text(level),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              selectedLevel = selected ? level : null;
            });
          },
          backgroundColor: Colors.grey[200],
          selectedColor: Colors.green.withOpacity(0.2),
          checkmarkColor: Colors.green,
          labelStyle: TextStyle(
            color: isSelected ? Colors.green : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      ratingRange.start.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Text('to'),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      ratingRange.end.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            RangeSlider(
              values: ratingRange,
              min: 0,
              max: 5,
              divisions: 10,
              labels: RangeLabels(
                ratingRange.start.toStringAsFixed(1),
                ratingRange.end.toStringAsFixed(1),
              ),
              onChanged: (values) {
                setState(() => ratingRange = values);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Column(
      children: sortOptions.map((option) {
        final isSelected = option['value'] == sortBy;
        return Card(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
          child: RadioListTile<String>(
            value: option['value'],
            groupValue: sortBy,
            onChanged: (value) {
              setState(() => sortBy = value!);
            },
            title: Text(
              option['label'],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            secondary: Icon(
              option['icon'],
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            activeColor: Theme.of(context).primaryColor,
          ),
        );
      }).toList(),
    );
  }
}
