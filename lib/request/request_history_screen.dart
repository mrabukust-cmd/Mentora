// lib/screens/requests/request_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  
  // Filter options
  String selectedFilter = 'all'; // all, pending, accepted, rejected, completed
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8F9FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(isDark, isSmall),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildFilterChips(isDark, isSmall),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(true, isDark, isSmall), // Sent requests
                _buildRequestsList(false, isDark, isSmall), // Received requests
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark, bool isSmall) {
    return SliverAppBar(
      expandedHeight: isSmall ? 180 : 200,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: FadeTransition(
          opacity: _animationController,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF2D2D44), const Color(0xFF1F4068)]
                    : [const Color(0xFF6C63FF), const Color(0xFF00D4FF)],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isSmall ? 50 : 60),
                  Container(
                    padding: EdgeInsets.all(isSmall ? 14 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: isSmall ? 32 : 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isSmall ? 10 : 12),
                  Text(
                    'Request History',
                    style: TextStyle(
                      fontSize: isSmall ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isSmall ? 4 : 6),
                  Text(
                    'Track all your requests',
                    style: TextStyle(
                      fontSize: isSmall ? 13 : 15,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: TextStyle(
          fontSize: isSmall ? 14 : 16,
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.send), text: 'Sent'),
          Tab(icon: Icon(Icons.inbox), text: 'Received'),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark, bool isSmall) {
    final filters = [
      {'value': 'all', 'label': 'All', 'icon': Icons.view_list},
      {'value': 'pending', 'label': 'Pending', 'icon': Icons.pending},
      {'value': 'accepted', 'label': 'Accepted', 'icon': Icons.check_circle},
      {'value': 'completed', 'label': 'Completed', 'icon': Icons.verified},
      {'value': 'rejected', 'label': 'Rejected', 'icon': Icons.cancel},
    ];

    return Container(
      height: isSmall ? 50 : 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: isSmall ? 16 : 18,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(width: 6),
                  Text(filter['label'] as String),
                ],
              ),
              onSelected: (selected) {
                setState(() => selectedFilter = filter['value'] as String);
              },
              backgroundColor: isDark ? const Color(0xFF1F1F2E) : Colors.white,
              selectedColor: const Color(0xFF6C63FF),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: isSmall ? 12 : 14,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(bool isSent, bool isDark, bool isSmall) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getRequestsStream(isSent),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton(isDark, isSmall);
        }

        if (snapshot.hasError) {
          return _buildErrorState(isDark, isSmall);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(isSent, isDark, isSmall);
        }

        final requests = _filterRequests(snapshot.data!.docs);

        if (requests.isEmpty) {
          return _buildEmptyFilterState(isDark, isSmall);
        }

        return ListView.builder(
          padding: EdgeInsets.all(isSmall ? 14 : 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(requests[index], isSent, isDark, isSmall, index);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getRequestsStream(bool isSent) {
    final field = isSent ? 'requesterId' : 'mentorId';
    
    return FirebaseFirestore.instance
        .collection('requests')
        .where(field, isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterRequests(List<QueryDocumentSnapshot> docs) {
    if (selectedFilter == 'all') return docs;
    
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == selectedFilter;
    }).toList();
  }

  Widget _buildRequestCard(
    QueryDocumentSnapshot doc,
    bool isSent,
    bool isDark,
    bool isSmall,
    int index,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final otherPersonName = isSent ? data['mentorName'] : data['requesterName'];
    final skillName = data['skillName'] ?? 'Unknown Skill';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final rating = data['rating']?.toDouble() ?? 0.0;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.only(bottom: isSmall ? 10 : 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F2E) : Colors.white,
                borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
                border: Border.all(
                  color: _getStatusColor(status).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(status).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Navigate to request details
                  },
                  borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
                  child: Padding(
                    padding: EdgeInsets.all(isSmall ? 14 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmall ? 10 : 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getStatusColor(status),
                                    _getStatusColor(status).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getStatusIcon(status),
                                color: Colors.white,
                                size: isSmall ? 20 : 24,
                              ),
                            ),
                            SizedBox(width: isSmall ? 10 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    otherPersonName ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: isSmall ? 15 : 17,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF2D3142),
                                    ),
                                  ),
                                  SizedBox(height: isSmall ? 2 : 4),
                                  Text(
                                    skillName,
                                    style: TextStyle(
                                      fontSize: isSmall ? 12 : 14,
                                      color: isDark ? Colors.white60 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(status, isDark, isSmall),
                          ],
                        ),
                        SizedBox(height: isSmall ? 10 : 12),
                        Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]),
                        SizedBox(height: isSmall ? 8 : 10),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: isSmall ? 14 : 16,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                            SizedBox(width: isSmall ? 6 : 8),
                            Text(
                              createdAt != null
                                  ? DateFormat('MMM d, yyyy').format(createdAt)
                                  : 'Unknown date',
                              style: TextStyle(
                                fontSize: isSmall ? 12 : 14,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            if (status == 'completed' && rating > 0) ...[
                              Icon(Icons.star, size: isSmall ? 14 : 16, color: Colors.amber),
                              SizedBox(width: isSmall ? 4 : 6),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: isSmall ? 12 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (data['message']?.toString().isNotEmpty ?? false) ...[
                          SizedBox(height: isSmall ? 8 : 10),
                          Container(
                            padding: EdgeInsets.all(isSmall ? 10 : 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              data['message'],
                              style: TextStyle(
                                fontSize: isSmall ? 12 : 14,
                                color: isDark ? Colors.white70 : Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  Widget _buildStatusBadge(String status, bool isDark, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 10 : 12,
        vertical: isSmall ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(isDark ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFB800);
      case 'accepted':
        return const Color(0xFF00D4FF);
      case 'rejected':
        return const Color(0xFFFF5252);
      case 'completed':
        return const Color(0xFF1DD1A1);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.verified;
      default:
        return Icons.info;
    }
  }

  Widget _buildEmptyState(bool isSent, bool isDark, bool isSmall) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 20 : 24),
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
              isSent ? Icons.send_outlined : Icons.inbox_outlined,
              size: isSmall ? 50 : 60,
              color: isDark ? const Color(0xFF8B7FFF) : const Color(0xFF6C63FF),
            ),
          ),
          SizedBox(height: isSmall ? 16 : 20),
          Text(
            isSent ? 'No sent requests' : 'No received requests',
            style: TextStyle(
              fontSize: isSmall ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: isSmall ? 6 : 8),
          Text(
            isSent
                ? 'Start learning by sending requests to mentors'
                : 'No one has requested your mentorship yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 14 : 15,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState(bool isDark, bool isSmall) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: isSmall ? 50 : 60,
            color: isDark ? Colors.white30 : Colors.grey[400],
          ),
          SizedBox(height: isSmall ? 16 : 20),
          Text(
            'No requests found',
            style: TextStyle(
              fontSize: isSmall ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: isSmall ? 6 : 8),
          Text(
            'Try adjusting your filter',
            style: TextStyle(
              fontSize: isSmall ? 14 : 15,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark, bool isSmall) {
    return ListView.builder(
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          height: isSmall ? 120 : 140,
          margin: EdgeInsets.only(bottom: isSmall ? 10 : 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D44) : Colors.grey[200],
            borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(bool isDark, bool isSmall) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: isSmall ? 50 : 60,
            color: const Color(0xFFFF5252),
          ),
          SizedBox(height: isSmall ? 16 : 20),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: isSmall ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: isSmall ? 6 : 8),
          Text(
            'Please try again later',
            style: TextStyle(
              fontSize: isSmall ? 14 : 15,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper classes
class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  _StatData(this.label, this.value, this.icon, this.color);
}

class _ActionData {
  final IconData icon;
  final String label;
  final Color color;

  _ActionData(this.icon, this.label, this.color);
}