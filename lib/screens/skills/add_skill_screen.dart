import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skillNameController = TextEditingController();

  String skillType = 'offered'; // 'offered' or 'wanted'
  String? selectedCategory;
  String? selectedLevel;

  final List<String> categories = [
    'Programming',
    'Design',
    'Business',
    'Marketing',
    'Languages',
    'Music',
    'Sports',
    'Arts',
    'Science',
    'Mathematics',
    'Writing',
    'Other',
  ];

  final List<String> levels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];

  bool isLoading = false;

  @override
  void dispose() {
    _skillNameController.dispose();
    super.dispose();
  }

  Future<void> _addSkill() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a skill level')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final skillData = {
        'name': _skillNameController.text.trim(),
        'category': selectedCategory,
        'level': selectedLevel,
      };

      // Determine which field to update
      final fieldName = skillType == 'offered'
          ? 'skillsOffered'
          : 'skillsWanted';

      // Get current skills
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};
      final currentSkills = data[fieldName] as List<dynamic>? ?? [];

      // Check if skill already exists
      final skillExists = currentSkills.any(
        (skill) =>
            skill is Map &&
            skill['name']?.toString().toLowerCase() ==
                _skillNameController.text.trim().toLowerCase(),
      );

      if (skillExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This skill already exists in ${skillType == "offered" ? "offered" : "wanted"} skills',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      // Add new skill
      final updatedSkills = [...currentSkills, skillData];

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {fieldName: updatedSkills},
      );

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Skill ${skillType == "offered" ? "offered" : "wanted"} added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Return true to indicate skill was added
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error adding skill: $e");

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add skill: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Skill'), centerTitle: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skill Type Selection
                  const Text(
                    'Skill Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'offered',
                          groupValue: skillType,
                          onChanged: (value) {
                            setState(() => skillType = value!);
                          },
                          title: const Text('I Offer'),
                          subtitle: const Text('I can teach this'),
                          secondary: const Icon(
                            Icons.school,
                            color: Colors.blueAccent,
                          ),
                          activeColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: skillType == 'offered'
                                  ? Colors.blueAccent
                                  : Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'wanted',
                          groupValue: skillType,
                          onChanged: (value) {
                            setState(() => skillType = value!);
                          },
                          title: const Text('I Want'),
                          subtitle: const Text('I want to learn this'),
                          secondary: const Icon(
                            Icons.lightbulb,
                            color: Colors.orange,
                          ),
                          activeColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: skillType == 'wanted'
                                  ? Colors.orange
                                  : Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Skill Name
                  const Text(
                    'Skill Name *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _skillNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Flutter Development',
                      prefixIcon: Icon(Icons.text_fields),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a skill name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Category
                  const Text(
                    'Category *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCategory = value);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Skill Level
                  Text(
                    skillType == 'offered'
                        ? 'Your Skill Level *'
                        : 'Desired Learning Level *',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: skillType == 'offered'
                          ? 'Your current level'
                          : 'Level you want to reach',
                      prefixIcon: const Icon(Icons.trending_up),
                    ),
                    items: levels.map((level) {
                      return DropdownMenuItem(value: level, child: Text(level));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedLevel = value);
                    },
                  ),

                  const SizedBox(height: 32),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: skillType == 'offered'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: skillType == 'offered'
                            ? Colors.blueAccent.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: skillType == 'offered'
                              ? Colors.blueAccent
                              : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            skillType == 'offered'
                                ? 'This skill will be visible to students looking for mentors'
                                : 'This will help you find mentors who can teach this skill',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _addSkill,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: skillType == 'offered'
                            ? Colors.blueAccent
                            : Colors.orange,
                      ),
                      child: Text(
                        isLoading
                            ? 'Adding...'
                            : 'Add ${skillType == "offered" ? "Offered" : "Wanted"} Skill',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
