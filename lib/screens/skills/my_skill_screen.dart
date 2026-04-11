import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentora/screens/skills/add_skill_screen.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key});

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch offered skills from Firestore
  Stream<List<Map<String, dynamic>>> _getOfferedSkills() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return [];

          final data = snapshot.data();
          final skillsData = data?['skillsOffered'];

          if (skillsData == null) return [];

          List<Map<String, dynamic>> skills = [];
          if (skillsData is List) {
            for (var skill in skillsData) {
              if (skill is Map<String, dynamic>) {
                skills.add(skill);
              }
            }
          }

          return skills;
        });
  }

  // Fetch wanted skills from Firestore
  Stream<List<Map<String, dynamic>>> _getWantedSkills() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return [];

          final data = snapshot.data();
          final skillsData = data?['skillsWanted'];

          if (skillsData == null) return [];

          List<Map<String, dynamic>> skills = [];
          if (skillsData is List) {
            for (var skill in skillsData) {
              if (skill is Map<String, dynamic>) {
                skills.add(skill);
              }
            }
          }

          return skills;
        });
  }

  // Delete a skill
  Future<void> _deleteSkill(String skillName, bool isOffered) async {
    try {
      final fieldName = isOffered ? 'skillsOffered' : 'skillsWanted';

      // Get current skills
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      final data = doc.data();
      final currentSkills = data?[fieldName] as List<dynamic>? ?? [];

      // Remove the skill
      final updatedSkills = currentSkills
          .where((skill) => skill['name'] != skillName)
          .toList();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({fieldName: updatedSkills});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skill deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting skill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build skill card
  Widget _buildSkillCard(Map<String, dynamic> skill, bool isOffered) {
    final skillName = skill['name']?.toString() ?? 'Unknown';
    final category = skill['category']?.toString() ?? '';
    final level = skill['level']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOffered
                    ? Colors.blueAccent.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOffered ? Icons.school : Icons.lightbulb,
                color: isOffered ? Colors.blueAccent : Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Skill details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skillName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (category.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                      if (level.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOffered
                                ? Colors.blueAccent.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            level,
                            style: TextStyle(
                              fontSize: 12,
                              color: isOffered
                                  ? Colors.blueAccent
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Skill'),
                    content: Text('Delete "$skillName"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _deleteSkill(skillName, isOffered);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build skills list
  Widget _buildSkillsList(
    Stream<List<Map<String, dynamic>>> stream,
    bool isOffered,
  ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final skills = snapshot.data ?? [];

        if (skills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOffered ? Icons.school : Icons.lightbulb,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  isOffered ? 'No skills offered yet' : 'No skills wanted yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add a skill',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: skills.length,
          itemBuilder: (context, index) {
            return _buildSkillCard(skills[index], isOffered);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Skills'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Offered'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Wanted'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Offered Skills Tab
          _buildSkillsList(_getOfferedSkills(), true),

          // Wanted Skills Tab
          _buildSkillsList(_getWantedSkills(), false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSkillScreen()),
          );

          // Refresh if skill was added
          if (result == true && mounted) {
            setState(() {}); // This will trigger a rebuild
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Skill'),
      ),
    );
  }
}
