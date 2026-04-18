import 'package:bangla_hub/screens/admin_app/screens/event_management/admin_event_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bangla_hub/models/event_model.dart';
import 'package:intl/intl.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({Key? key}) : super(key: key);

  @override
  _AdminEventsScreenState createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Premium Color Palette
  final Color _primaryRed = const Color(0xFFE03C32);
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF00432D);
  final Color _goldAccent = const Color(0xFFFFD700);
  final Color _deepRed = const Color(0xFFC62828);
  final Color _bgGradient1 = const Color(0xFF0A2F1D);
  final Color _bgGradient2 = const Color(0xFF004D38);
  final Color _cardColor = const Color(0x1AFFFFFF);
  final Color _borderColor = const Color(0x33FFFFFF);
  final Color _textWhite = const Color(0xFFFFFFFF);
  final Color _textLight = const Color(0xFFE0E0E0);
  final Color _textMuted = const Color(0xFFAAAAAA);
  final Color _offWhite = const Color(0xFFF8F8F8);
  final Color _surfaceColor = const Color(0xFFF5F7FA);
  final Color _purple = const Color(0xFF9C27B0);
  final Color _blue = const Color(0xFF2196F3);
  final Color _orange = const Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Container(
      color: _surfaceColor,
      child: Column(
        children: [
          // Premium Tab Bar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryGreen, _darkGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
                child: Column(
                  children: [
                    SizedBox(height: isTablet ? 20 : 16),
                    // Header
                    Row(
                      children: [
                        /*  Container(
                          width: isTablet ? 50 : 40,
                          height: isTablet ? 50 : 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryRed, _primaryGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.event_available_rounded,
                              color: Colors.white,
                              size: isTablet ? 24 : 20,
                            ),
                          ),
                        ), */
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Management',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Review and manage all community events',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    // Tab Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryRed, _primaryGreen],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.7),
                        labelStyle: GoogleFonts.inter(
                          fontSize: isTablet ? 15 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.pending_actions_rounded,
                                    size: isTablet ? 15 : 12),
                                const SizedBox(width: 2),
                                const Text('Pending'),
                                const SizedBox(width: 2),
                                StreamBuilder<QuerySnapshot>(
                                  stream: _firestore
                                      .collection('events')
                                      .where('status', isEqualTo: 'pending')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data?.docs.length ?? 0;
                                    if (count > 0) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: GoogleFonts.inter(
                                            fontSize: isTablet ? 12 : 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_available_rounded,
                                    size: 20),
                                SizedBox(width: 8),
                                Text('Active'),
                              ],
                            ),
                          ),
                          const Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Past'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                  ],
                ),
              ),
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pending Events Tab
                _buildPremiumEventsList(
                  query: _firestore
                      .collection('events')
                      .where('status', isEqualTo: 'pending')
                      .orderBy('createdAt', descending: true),
                  emptyMessage: 'No pending event requests',
                  emptyIcon: Icons.pending_actions_rounded,
                  isPending: true,
                  isTablet: isTablet,
                ),
                // Active Events Tab
                _buildPremiumEventsList(
                  query: _firestore
                      .collection('events')
                      .where('status', isEqualTo: 'approved')
                      .where('eventDate',
                          isGreaterThanOrEqualTo: Timestamp.now())
                      .orderBy('eventDate'),
                  emptyMessage: 'No active events',
                  emptyIcon: Icons.event_available_rounded,
                  isPending: false,
                  isTablet: isTablet,
                ),
                // Past Events Tab
                _buildPremiumEventsList(
                  query: _firestore
                      .collection('events')
                      .where('status', isEqualTo: 'approved')
                      .where('eventDate', isLessThan: Timestamp.now())
                      .orderBy('eventDate', descending: true),
                  emptyMessage: 'No past events',
                  emptyIcon: Icons.history_rounded,
                  isPending: false,
                  isTablet: isTablet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEventsList({
    required Query query,
    required String emptyMessage,
    required IconData emptyIcon,
    required bool isPending,
    required bool isTablet,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: _primaryGreen,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading events...',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isTablet ? 120 : 80,
                  height: isTablet ? 120 : 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryRed.withOpacity(0.1),
                        _primaryGreen.withOpacity(0.1)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: _primaryRed,
                      size: isTablet ? 48 : 32,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 16),
                Text(
                  'Error loading events',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  'Please check your connection',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data?.docs ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isTablet ? 150 : 120,
                  height: isTablet ? 150 : 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryGreen.withOpacity(0.1),
                        _primaryRed.withOpacity(0.1)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      emptyIcon,
                      size: isTablet ? 60 : 48,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 28 : 24),
                Text(
                  emptyMessage,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isTablet ? 12 : 10),
                Text(
                  'Check back later for new activity',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final eventDoc = events[index];
            final event = EventModel.fromMap(
                eventDoc.data() as Map<String, dynamic>, eventDoc.id);

            return _buildMediumEventCard(event, isPending, isTablet);
          },
        );
      },
    );
  }

  // Medium-sized event card with balanced proportions
  Widget _buildMediumEventCard(EventModel event, bool isPending, bool isTablet) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToEventDetails(context, event, isPending),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        child: Container(
          margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image - Left side, medium size
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTablet ? 20 : 16),
                  bottomLeft: Radius.circular(isTablet ? 20 : 16),
                ),
                child: Container(
                  width: isTablet ? 140 : 110,
                  height: isTablet ? 180 : 150,
                  child: Stack(
                    children: [
                      event.bannerImageWidget,
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content - Right side
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category and Status Row
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 10 : 8,
                                vertical: isTablet ? 6 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: event.isPast
                                    ? Colors.grey.withOpacity(0.1)
                                    : _primaryRed.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 8 : 6),
                                border: Border.all(
                                  color: event.isPast ? Colors.grey : _primaryRed,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                event.categoryText,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 11 : 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      event.isPast ? Colors.grey : _primaryRed,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 10 : 8,
                                vertical: isTablet ? 6 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(event.status)
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 8 : 6),
                                border: Border.all(
                                  color: _getStatusColor(event.status),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getStatusText(event.status).toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 9 : 8,
                                  fontWeight: FontWeight.w800,
                                  color: _getStatusColor(event.status),
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (isPending) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 8 : 6,
                                vertical: isTablet ? 6 : 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryRed, _deepRed],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 8 : 6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: isTablet ? 12 : 10,
                                      color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Review',
                                    style: GoogleFonts.inter(
                                      fontSize: isTablet ? 10 : 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Event Title
                      Text(
                        event.title,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Date Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: isTablet ? 14 : 12, color: _primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date & Time',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 10 : 9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  event.formattedDate,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 12 : 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Location Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: isTablet ? 14 : 12, color: _primaryRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 10 : 9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  event.location,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 12 : 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Organizer and Interested Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: isTablet ? 12 : 10,
                            backgroundColor: _blue.withOpacity(0.1),
                            child: Icon(Icons.person_rounded,
                                color: _blue, size: isTablet ? 12 : 10),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Organizer',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 9 : 8,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  event.organizer,
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 12 : 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 10 : 8,
                              vertical: isTablet ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _orange.withOpacity(0.1),
                                  _goldAccent.withOpacity(0.1)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(isTablet ? 8 : 6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_rounded,
                                    color: _orange, size: isTablet ? 12 : 10),
                                const SizedBox(width: 4),
                                Text(
                                  '${event.totalInterested}',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 12 : 11,
                                    fontWeight: FontWeight.w700,
                                    color: _orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // View Details Button - Compact
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryGreen, _darkGreen],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                        ),
                        child: Center(
                          child: Text(
                            'View Details',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 12 : 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'suspended':
        return Colors.red;
      case 'deleted':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'suspended':
        return 'Suspended';
      case 'deleted':
        return 'Deleted';
      default:
        return status;
    }
  }

  void _navigateToEventDetails(BuildContext context, EventModel event, bool isPending) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEventDetailsScreen(
          event: event,
          isPending: isPending,
        ),
      ),
    );
  }
}