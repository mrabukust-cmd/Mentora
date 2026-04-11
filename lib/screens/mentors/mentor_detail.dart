import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentora/screens/booking/send_request.dart'
    show SendRequestScreen;

class MentorDetailsScreen extends StatefulWidget {
  final String mentorId;
  final Map<String, dynamic> mentorData;

  const MentorDetailsScreen({
    super.key,
    required this.mentorId,
    required this.mentorData,
  });

  @override
  State<MentorDetailsScreen> createState() => _MentorDetailsScreenState();
}

class _MentorDetailsScreenState extends State<MentorDetailsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> completedRequests = [];
  double averageRating = 0.0;
  int totalReviews = 0;

  // ✅ ADDED: Selected skill state
  String? selectedSkill;
  String? selectedSkillCategory;

  @override
  void initState() {
    super.initState();
    _loadMentorStats();

    // ✅ Set default selected skill (first skill)
    final skills = widget.mentorData['skillsOffered'] as List<dynamic>;
    if (skills.isNotEmpty) {
      selectedSkill = skills[0]['name'];
      selectedSkillCategory = skills[0]['category'];
    }
  }

  Future<void> _loadMentorStats() async {
    try {
      // Get mentor's profile data for overall rating
      final mentorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mentorId)
          .get();

      if (mentorDoc.exists) {
        final mentorData = mentorDoc.data()!;
        final profileRating = (mentorData['rating'] ?? 0.0) as double;
        final profileTotalRatings = (mentorData['totalRatings'] ?? 0) as int;

        if (mounted) {
          setState(() {
            averageRating = profileRating;
            totalReviews = profileTotalRatings;
          });
        }
      }

      // Get completed requests with reviews for display
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('mentorId', isEqualTo: widget.mentorId)
          .where('status', isEqualTo: 'completed')
          .get();

      List<Map<String, dynamic>> reviews = [];

      for (var doc in requestsSnapshot.docs) {
        final data = doc.data();
        if (data['rating'] != null && data['rating'] > 0) {
          reviews.add({
            'requesterName': data['requesterName'] ?? 'Anonymous',
            'rating': data['rating'],
            'review': data['review'] ?? '',
            'createdAt': data['createdAt'],
            'skillName': data['skillName'] ?? '',
          });
        }
      }

      // Sort reviews by most recent
      reviews.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          completedRequests = reviews;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading mentor stats: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skills = widget.mentorData['skillsOffered'] as List<dynamic>;
    final location = [
      widget.mentorData['city'],
      widget.mentorData['state'],
      widget.mentorData['country'],
    ].where((s) => s.toString().trim().isNotEmpty).join(', ');

    final firstName = widget.mentorData['firstName'] ?? '';
    final lastName = widget.mentorData['lastName'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mentor Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blueAccent.withOpacity(0.1),
                        Colors.white,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        '$firstName $lastName'.trim(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location
                      if (location.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Rating
                      if (!isLoading && totalReviews > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildRatingStars(averageRating),
                            const SizedBox(width: 8),
                            Text(
                              '${averageRating.toStringAsFixed(1)} ($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Skills Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Skills Offered (${skills.length})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ✅ ADDED: Skill Selection Dropdown
                      Card(
                        color: Colors.blue.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select skill for request:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedSkill,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: skills.map((skill) {
                                  final skillName =
                                      skill['name']?.toString() ?? 'Unknown';
                                  return DropdownMenuItem<String>(
                                    value: skillName,
                                    child: Text(skillName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedSkill = value;
                                    // Update category when skill changes
                                    final skill = skills.firstWhere(
                                      (s) => s['name'] == value,
                                      orElse: () => {'category': 'General'},
                                    );
                                    selectedSkillCategory = skill['category'];
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Skills List
                      ...skills.map((skill) {
                        final skillName =
                            skill['name']?.toString() ?? 'Unknown';
                        final category = skill['category']?.toString() ?? '';
                        final level = skill['level']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent.withOpacity(
                                0.2,
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.blueAccent,
                              ),
                            ),
                            title: Text(
                              skillName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '$category${level.isNotEmpty ? ' • $level' : ''}',
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 24),

                      // Reviews Section
                      if (!isLoading && completedRequests.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.rate_review,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Reviews',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // In the reviews section, update the review card:
                        ...completedRequests.map((review) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.blueAccent
                                            .withOpacity(0.1),
                                        child: Text(
                                          review['requesterName']
                                                  .toString()
                                                  .isNotEmpty
                                              ? review['requesterName']
                                                    .toString()[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review['requesterName'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (review['skillName']
                                                    ?.toString()
                                                    .isNotEmpty ??
                                                false)
                                              Text(
                                                review['skillName'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      _buildRatingStars(
                                        (review['rating'] as num).toDouble(),
                                      ),
                                    ],
                                  ),
                                  if (review['review']
                                      .toString()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        review['review'],
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),

      // ✅ FIXED: Send Request Button with all parameters
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: selectedSkill == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendRequestScreen(
                        mentorId: widget.mentorId,
                        mentorName: '$firstName $lastName'.trim(),
                        mentorEmail:
                            widget.mentorData['email']?.toString() ?? '',
                        skillName: selectedSkill!,
                        skillCategory: selectedSkillCategory ?? 'General',
                        mentorSkills: skills,
                      ),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Send Request',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
