import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MentorListScreen extends StatefulWidget {
  final String skill;

  const MentorListScreen({super.key, required this.skill});

  @override
  State<MentorListScreen> createState() => _MentorListScreenState();
}

class _MentorListScreenState extends State<MentorListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  
  bool isLoading = true;
  List<Map<String, dynamic>> mentors = [];
  String? userCity;

  @override
  void initState() {
    super.initState();
    fetchMentors();
  }

  Future<void> fetchMentors() async {
    try {
      // Get current user's city
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      userCity = userDoc['city'];

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      List<Map<String, dynamic>> results = [];

      for (var doc in usersSnapshot.docs) {
        // Skip current user
        if (doc.id == currentUserId) continue;

        // Only show users in same city
        if (doc['city'] != userCity) continue;

        // Check if this user offers the skill we're looking for
        final skillsOffered = List<Map<String, dynamic>>.from(
          doc['skillsOffered'] ?? [],
        );

        bool hasSkill = skillsOffered.any(
          (s) => s['name'].toString().toLowerCase() == widget.skill.toLowerCase(),
        );

        if (hasSkill) {
          results.add({
            'mentorId': doc.id,
            'firstName': doc['firstName'] ?? '',
            'lastName': doc['lastName'] ?? '',
            'email': doc['email'] ?? '',
            'rating': doc['rating'] ?? 0.0,
            'totalRatings': doc['totalRatings'] ?? 0,
            'completedSessions': doc['completedSessions'] ?? 0,
            'city': doc['city'] ?? '',
            'state': doc['state'] ?? '',
          });
        }
      }

      setState(() {
        mentors = results;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching mentors: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skill),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : mentors.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mentors.length,
                  itemBuilder: (context, index) {
                    return _MentorCard(
                      mentor: mentors[index],
                      skillName: widget.skill,
                    );
                  },
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No mentors found for "${widget.skill}"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            userCity != null ? 'in $userCity' : '',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ============================================
// MENTOR CARD
// ============================================
class _MentorCard extends StatelessWidget {
  final Map<String, dynamic> mentor;
  final String skillName;

  const _MentorCard({
    required this.mentor,
    required this.skillName,
  });

  @override
  Widget build(BuildContext context) {
    final rating = mentor['rating'] ?? 0.0;
    final totalRatings = mentor['totalRatings'] ?? 0;
    final completedSessions = mentor['completedSessions'] ?? 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MentorDetailScreen(
                mentorId: mentor['mentorId'],
                skillName: skillName,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      '${mentor['firstName'][0]}${mentor['lastName'][0]}'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${mentor['firstName']} ${mentor['lastName']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${mentor['city']}, ${mentor['state']}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  _StatChip(
                    icon: Icons.people,
                    label: '$totalRatings reviews',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.check_circle,
                    label: '$completedSessions sessions',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Request Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SendRequestScreen(
                          mentorId: mentor['mentorId'],
                          mentorName: '${mentor['firstName']} ${mentor['lastName']}',
                          mentorEmail: mentor['email'],
                          skillName: skillName,
                          skillCategory: '', // Get from skill data if needed
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send Request'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// STAT CHIP
// ============================================
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================
// IMPORT THIS IN YOUR MENTOR LIST SCREEN
// ============================================
class SendRequestScreen extends StatelessWidget {
  final String mentorId;
  final String mentorName;
  final String mentorEmail;
  final String skillName;
  final String skillCategory;

  const SendRequestScreen({
    super.key,
    required this.mentorId,
    required this.mentorName,
    required this.mentorEmail,
    required this.skillName,
    required this.skillCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Request')),
      body: const Center(child: Text('SendRequestScreen Implementation Here')),
    );
  }
}

// ============================================
// MENTOR DETAIL SCREEN (SEPARATE FILE)
// ============================================
class MentorDetailScreen extends StatelessWidget {
  final String mentorId;
  final String skillName;

  const MentorDetailScreen({
    super.key,
    required this.mentorId,
    required this.skillName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentor Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(mentorId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final skillsOffered = List<Map<String, dynamic>>.from(
            data['skillsOffered'] ?? [],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  child: Text(
                    '${data['firstName'][0]}${data['lastName'][0]}'.toUpperCase(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${data['firstName']} ${data['lastName']}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${data['rating'] ?? 0.0} (${data['totalRatings'] ?? 0} reviews)',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Skills Offered',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skillsOffered
                      .map(
                        (skill) => Chip(
                          label: Text(skill['name']),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SendRequestScreen(
                            mentorId: mentorId,
                            mentorName: '${data['firstName']} ${data['lastName']}',
                            mentorEmail: data['email'],
                            skillName: skillName,
                            skillCategory: '',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send Request'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}