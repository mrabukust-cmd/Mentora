import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mentora/services/matching_service.dart';

class SendRequestScreen extends StatefulWidget {
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
    required List mentorSkills,
  });

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final MatchingService _matchingService = MatchingService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _isCheckingMatch = true;

  // Mutual match info
  MutualMatchResult? _matchResult;

  @override
  void initState() {
    super.initState();
    _checkMutualMatch();
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkMutualMatch() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final result = await _matchingService.checkMutualMatch(
        currentUserId: currentUser.uid,
        otherUserId: widget.mentorId,
      );

      if (mounted) {
        setState(() {
          _matchResult = result;
          _isCheckingMatch = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking mutual match: $e');
      if (mounted) setState(() => _isCheckingMatch = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.mentorId == FirebaseAuth.instance.currentUser?.uid) {
      _showErrorDialog('You cannot send a request to yourself');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Not logged in');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) throw Exception('User profile not found');

      final userData = userDoc.data()!;
      final requesterName =
          '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();

      // Check for duplicate pending/accepted requests
      final existingRequests = await FirebaseFirestore.instance
          .collection('requests')
          .where('requesterId', isEqualTo: currentUser.uid)
          .where('mentorId', isEqualTo: widget.mentorId)
          .where('skillName', isEqualTo: widget.skillName)
          .where('status', whereIn: ['pending', 'accepted']).get();

      if (existingRequests.docs.isNotEmpty) {
        throw Exception(
            'You already have an active request for this skill with this mentor');
      }

      // Build the offer skills string for storage (skills I offer in return)
      final mySkillsForThem =
          _matchResult?.skillsYouOffer.join(', ') ?? '';

      // Create request document
      final requestRef =
          await FirebaseFirestore.instance.collection('requests').add({
        'requesterId': currentUser.uid,
        'requesterName': requesterName,
        'requesterEmail': currentUser.email ?? '',
        'mentorId': widget.mentorId,
        'mentorName': widget.mentorName,
        'mentorEmail': widget.mentorEmail,
        'skillName': widget.skillName,
        'skillCategory': widget.skillCategory,
        'message': _messageController.text.trim(),
        'preferredDate':
            _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'preferredTime':
            _selectedTime != null ? _formatTime(_selectedTime!) : null,
        'status': 'pending',
        'rating': 0.0,
        'review': '',
        'sessionDate': null,
        'sessionTime': null,
        'meetingLocation': null,
        // Mutual match metadata
        'isMutualMatch': _matchResult?.isMutualMatch ?? false,
        'requesterOffersInReturn': mySkillsForThem,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await requestRef.update({'requestId': requestRef.id});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Request sent successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error: ${e.code} - ${e.message}');
      _showErrorDialog(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Error: $e');
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to send this request.';
      case 'not-found':
        return 'Mentor profile not found.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      default:
        return 'Failed to send request: ${e.message ?? "Unknown error"}';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Send Request'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Mentor info card ───────────────────────────
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sending request to:',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.1),
                            child: Text(
                              widget.mentorName.isNotEmpty
                                  ? widget.mentorName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.mentorName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.skillName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Mutual match banner ────────────────────────
              if (_isCheckingMatch)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Checking skill compatibility...',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                )
              else if (_matchResult != null) ...[
                if (_matchResult!.isMutualMatch)
                  _buildMutualMatchBanner()
                else
                  _buildNoMutualMatchBanner(),
              ],

              const SizedBox(height: 20),

              // ── Message field ──────────────────────────────
              const Text(
                'Your Message *',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText:
                      'Explain what you need help with and what you hope to learn...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF1F1F2E) : Colors.white,
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  if (value.trim().length < 10) {
                    return 'Message should be at least 10 characters';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${_messageController.text.length}/500',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Preferred date ─────────────────────────────
              const Text('Preferred Date (Optional)',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildDateTimePicker(
                icon: Icons.calendar_today,
                text: _selectedDate == null
                    ? 'Select a preferred date'
                    : DateFormat('EEE, MMM d, yyyy').format(_selectedDate!),
                hasValue: _selectedDate != null,
                onTap: _selectDate,
                onClear: () => setState(() => _selectedDate = null),
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // ── Preferred time ─────────────────────────────
              const Text('Preferred Time (Optional)',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildDateTimePicker(
                icon: Icons.access_time,
                text: _selectedTime == null
                    ? 'Select a preferred time'
                    : _formatTime(_selectedTime!),
                hasValue: _selectedTime != null,
                onTap: _selectTime,
                onClear: () => setState(() => _selectedTime = null),
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // ── Info box ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.blue.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue[700], size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'The mentor will review your request and can accept or suggest a different time.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Send button ────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendRequest,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white)),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 20),
                            SizedBox(width: 8),
                            Text('Send Request',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mutual match found banner ────────────────────────────
  Widget _buildMutualMatchBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.12),
            const Color(0xFF00D4FF).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Mutual Skill Exchange Match! 🎉',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF6C63FF)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // They teach me
          _buildExchangeInfoRow(
            icon: Icons.school_rounded,
            color: const Color(0xFF6C63FF),
            label: 'They can teach you:',
            skills: _matchResult!.skillsTheyOffer,
          ),
          const SizedBox(height: 8),
          // I teach them
          _buildExchangeInfoRow(
            icon: Icons.handshake_rounded,
            color: const Color(0xFF1DD1A1),
            label: 'You can teach them:',
            skills: _matchResult!.skillsYouOffer,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'This is a mutual exchange — both of you benefit!',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── No mutual match banner ───────────────────────────────
  Widget _buildNoMutualMatchBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.orange.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'One-way request',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'This mentor does not currently want any skills you offer. '
                  'You can still send a request, but consider adding more skills '
                  'to your profile to find mutual matches.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeInfoRow({
    required IconData icon,
    required Color color,
    required String label,
    required List<String> skills,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: skills
                .take(4)
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        s[0].toUpperCase() + s.substring(1),
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required IconData icon,
    required String text,
    required bool hasValue,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F2E) : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 16,
                    color: hasValue ? null : Colors.grey),
              ),
            ),
            if (hasValue)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}