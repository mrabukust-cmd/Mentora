import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mentora/services/chat_service.dart';
import 'package:mentora/screens/chat/chat_screen.dart';

class RequestDetailsScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;
  final bool isSentByMe;

  const RequestDetailsScreen({
    super.key,
    required this.requestId,
    required this.requestData,
    required this.isSentByMe,
  });

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final _sessionDateController = TextEditingController();
  final _sessionTimeController = TextEditingController();
  final _meetingLocationController = TextEditingController();
  final _reviewController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  double rating = 0;
  bool isLoading = false;

  @override
  void dispose() {
    _sessionDateController.dispose();
    _sessionTimeController.dispose();
    _meetingLocationController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Not specified';
    try {
      final DateTime date = (timestamp as Timestamp).toDate();
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
        _sessionDateController.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedTime = picked;
        final hour = picked.hourOfPeriod;
        final minute = picked.minute.toString().padLeft(2, '0');
        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
        _sessionTimeController.text =
            '${hour == 0 ? 12 : hour}:$minute $period';
      });
    }
  }

  Future<void> _acceptRequest() async {
    if (selectedDate == null) {
      _showError('Please select a session date');
      return;
    }

    if (selectedTime == null) {
      _showError('Please select a session time');
      return;
    }

    if (_meetingLocationController.text.trim().isEmpty) {
      _showError('Please enter a meeting location');
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final requestRef = FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId);
        final requestDoc = await transaction.get(requestRef);

        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }

        final data = requestDoc.data()!;

        if (data['mentorId'] != FirebaseAuth.instance.currentUser?.uid) {
          throw Exception('Unauthorized action');
        }

        if (data['status'] != 'pending') {
          throw Exception('Request is no longer pending');
        }

        transaction.update(requestRef, {
          'status': 'accepted',
          'sessionDate': Timestamp.fromDate(selectedDate!),
          'sessionTime': _sessionTimeController.text,
          'meetingLocation': _meetingLocationController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // ── Create chat conversation so both users can talk ──
      try {
        final reqSnap = await FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId)
            .get();
        final reqData = reqSnap.data()!;
        await ChatService().createConversationOnAccept(
          requestId: widget.requestId,
          mentorId: reqData['mentorId'],
          learnerId: reqData['requesterId'],
        );
      } catch (e) {
        debugPrint('Chat creation error (non-fatal): $e');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request accepted! Chat is now unlocked.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error accepting request: $e');
      _showError('Failed to accept request: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _rejectRequest() async {
    final confirmed = await _showConfirmationDialog(
      'Reject Request',
      'Are you sure you want to reject this request?',
      'Reject',
      Colors.red,
    );

    if (!confirmed) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      _showError('Failed to reject request: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _completeRequest() async {
    final confirmed = await _showConfirmationDialog(
      'Complete Session',
      'Mark this session as completed?',
      'Complete',
      Colors.green,
    );

    if (!confirmed) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1️⃣ READ FIRST: Get request document
        final requestRef = FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId);
        final requestDoc = await transaction.get(requestRef);

        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }

        final requestData = requestDoc.data()!;

        // Validate
        if (requestData['mentorId'] != FirebaseAuth.instance.currentUser?.uid) {
          throw Exception('Unauthorized action');
        }

        if (requestData['status'] != 'accepted') {
          throw Exception('Only accepted requests can be completed');
        }

        // 2️⃣ READ SECOND: Get mentor profile
        final mentorId = requestData['mentorId'];
        final mentorRef = FirebaseFirestore.instance
            .collection('users')
            .doc(mentorId);
        final mentorDoc = await transaction.get(mentorRef);

        // ✅ NOW DO WRITES

        // 3️⃣ WRITE: Update request status
        transaction.update(requestRef, {
          'status': 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 4️⃣ WRITE: Update mentor stats
        if (mentorDoc.exists) {
          transaction.update(mentorRef, {
            'completedSessions': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session marked as completed!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error completing request: $e');
      if (mounted) {
        _showError('Failed to complete request: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _submitReview() async {
    if (rating == 0) {
      _showError('Please select a rating');
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ FIX: Do all reads BEFORE any writes in the transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1️⃣ READ: Get the request document FIRST
        final requestRef = FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId);
        final requestDoc = await transaction.get(requestRef);

        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }

        final requestData = requestDoc.data()!;

        // Validate
        if (requestData['requesterId'] !=
            FirebaseAuth.instance.currentUser?.uid) {
          throw Exception('Unauthorized action');
        }

        if (requestData['status'] != 'completed') {
          throw Exception('Can only rate completed sessions');
        }

        if ((requestData['rating'] ?? 0.0) > 0) {
          throw Exception('You have already rated this session');
        }

        // 2️⃣ READ: Get mentor's profile data SECOND
        final mentorId = requestData['mentorId'];
        final mentorRef = FirebaseFirestore.instance
            .collection('users')
            .doc(mentorId);
        final mentorDoc = await transaction.get(mentorRef);

        // ✅ NOW DO ALL WRITES AFTER ALL READS ARE COMPLETE

        // 3️⃣ WRITE: Update the request with rating
        transaction.update(requestRef, {
          'rating': rating,
          'review': _reviewController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 4️⃣ WRITE: Update mentor's profile with new rating
        if (mentorDoc.exists) {
          final mentorData = mentorDoc.data()!;

          // Get current rating stats
          final currentRating = (mentorData['rating'] ?? 0.0) as double;
          final totalRatings = (mentorData['totalRatings'] ?? 0) as int;

          // Calculate new average rating
          final newTotalRatings = totalRatings + 1;
          final newRating =
              ((currentRating * totalRatings) + rating) / newTotalRatings;

          // Update mentor profile
          transaction.update(mentorRef, {
            'rating': newRating,
            'totalRatings': newTotalRatings,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error submitting review: $e');
      if (mounted) {
        _showError('Failed to submit review: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog(
    String title,
    String content,
    String actionText,
    Color actionColor,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionText),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.requestData['status'] ?? 'pending';
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';
    final isCompleted = status == 'completed';
    final hasReview = (widget.requestData['rating'] ?? 0.0) > 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Request Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _getStatusColor(status),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Request Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.person,
                            widget.isSentByMe ? 'Mentor' : 'Student',
                            widget.isSentByMe
                                ? widget.requestData['mentorName'] ?? 'Unknown'
                                : widget.requestData['requesterName'] ??
                                      'Unknown',
                          ),
                          _buildInfoRow(
                            Icons.school,
                            'Skill',
                            widget.requestData['skillName'] ?? 'Unknown',
                          ),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Preferred Date',
                            _formatTimestamp(
                              widget.requestData['preferredDate'],
                            ),
                          ),
                          _buildInfoRow(
                            Icons.access_time,
                            'Preferred Time',
                            widget.requestData['preferredTime'] ??
                                'Not specified',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Message
                  const Text(
                    'Message',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.requestData['message'] ?? 'No message',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Session Details (if accepted)
                  if (isAccepted || isCompleted) ...[
                    const Text(
                      'Session Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.green.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.event,
                              'Session Date',
                              _formatTimestamp(
                                widget.requestData['sessionDate'],
                              ),
                            ),
                            _buildInfoRow(
                              Icons.schedule,
                              'Session Time',
                              widget.requestData['sessionTime'] ??
                                  'Not specified',
                            ),
                            _buildInfoRow(
                              Icons.location_on,
                              'Meeting Location',
                              widget.requestData['meetingLocation'] ??
                                  'Not specified',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Accept Form (for mentor when pending)
                  if (!widget.isSentByMe && isPending) ...[
                    const Text(
                      'Accept Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _sessionDateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Session Date *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              onTap: _selectDate,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _sessionTimeController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Session Time *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              onTap: _selectTime,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _meetingLocationController,
                              decoration: const InputDecoration(
                                labelText: 'Meeting Location *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                                hintText: 'e.g., Library Room 3, Zoom link',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Review Form (for student when completed)
                  if (widget.isSentByMe && isCompleted && !hasReview) ...[
                    const Text(
                      'Leave a Review',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Rate your experience',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  icon: Icon(
                                    index < rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 36,
                                    color: Colors.amber,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => rating = (index + 1).toDouble(),
                                    );
                                  },
                                );
                              }),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _reviewController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Your Review (Optional)',
                                border: OutlineInputBorder(),
                                hintText: 'Share your experience...',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Show existing review
                  if (hasReview) ...[
                    const Text(
                      'Review',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.amber.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < (widget.requestData['rating'] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 28,
                                );
                              }),
                            ),
                            if (widget.requestData['review']
                                    ?.toString()
                                    .isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.requestData['review'],
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: isLoading
          ? null
          : Container(
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
              child: _buildBottomActions(status, hasReview),
            ),
    );
  }

  // Navigate to chat screen
  Future<void> _openChat() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final reqData = widget.requestData;

      setState(() => isLoading = true);

      // Step 1: Read conversationId directly from the request document
      // (avoids a collection query which Firestore rules block)
      final reqSnap = await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .get();
      String? conversationId = reqSnap.data()?['conversationId']?.toString();

      // Step 2: If still not set, create the conversation now
      if (conversationId == null || conversationId.isEmpty) {
        conversationId = await ChatService().createConversationOnAccept(
          requestId: widget.requestId,
          mentorId: reqData['mentorId'],
          learnerId: reqData['requesterId'],
        );
      }

      if (!mounted) return;
      setState(() => isLoading = false);

      final otherUserId = widget.isSentByMe
          ? reqData['mentorId'] as String
          : reqData['requesterId'] as String;
      final otherUserName = widget.isSentByMe
          ? reqData['mentorName']?.toString() ?? 'Mentor'
          : reqData['requesterName']?.toString() ?? 'Student';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId!,
            currentUserId: currentUser.uid,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserPhoto: reqData['otherUserPhoto']?.toString() ?? '',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showError('Could not open chat: ${e.toString()}');
      }
    }
  }

  Widget _buildBottomActions(String status, bool hasReview) {
    if (!widget.isSentByMe && status == 'pending') {
      // Mentor: Accept or Reject
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _rejectRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Reject', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _acceptRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Accept Request',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    // ── Accepted: Chat + Mark Complete (mentor) ───────────────
    if (!widget.isSentByMe && status == 'accepted') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text('Chat', style: TextStyle(fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF6C63FF),
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _completeRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Mark Completed',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ── Accepted: Chat button (student) ──────────────────────
    if (widget.isSentByMe && status == 'accepted') {
      return ElevatedButton.icon(
        onPressed: _openChat,
        icon: const Icon(Icons.chat_bubble_rounded, size: 18),
        label: const Text('Chat with Mentor', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    if (widget.isSentByMe && status == 'completed' && !hasReview) {
      // Student: Submit Review
      return ElevatedButton(
        onPressed: _submitReview,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Submit Review', style: TextStyle(fontSize: 16)),
      );
    }

    return const SizedBox.shrink();
  }
}