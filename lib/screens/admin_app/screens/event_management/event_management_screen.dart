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

class _AdminEventsScreenState extends State<AdminEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Premium Color Palette
  final Color _primaryRed = Color(0xFFE03C32);
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF00432D);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _deepRed = Color(0xFFC62828);
  final Color _bgGradient1 = Color(0xFF0A2F1D);
  final Color _bgGradient2 = Color(0xFF004D38);
  final Color _cardColor = Color(0x1AFFFFFF);
  final Color _borderColor = Color(0x33FFFFFF);
  final Color _textWhite = Color(0xFFFFFFFF);
  final Color _textLight = Color(0xFFE0E0E0);
  final Color _textMuted = Color(0xFFAAAAAA);
  final Color _offWhite = Color(0xFFF8F8F8);
  final Color _surfaceColor = Color(0xFFF5F7FA);
  final Color _purple = Color(0xFF9C27B0);
  final Color _blue = Color(0xFF2196F3);
  final Color _orange = Color(0xFFFF9800);

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
                  offset: Offset(0, 5),
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
                              SizedBox(height: 4),
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
                              offset: Offset(0, 3),
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
                            //    Icon(Icons.pending_actions_rounded, size: isTablet ? 20 : 16),
                                  Icon(Icons.pending_actions_rounded, size: isTablet ? 15 : 12),
                                SizedBox(width: 2),
                              //   SizedBox(width: 8),
                                Text('Pending'),
                              //  SizedBox(width: 8),
                                SizedBox(width: 2),
                                StreamBuilder<QuerySnapshot>(
                                  stream: _firestore.collection('events')
                                      .where('status', isEqualTo: 'pending')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data?.docs.length ?? 0;
                                    if (count > 0) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
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
                                    return SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_available_rounded, size: isTablet ? 20 : 16),
                                SizedBox(width: 8),
                                Text('Active'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: isTablet ? 20 : 16),
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
                  query: _firestore.collection('events')
                      .where('status', isEqualTo: 'pending')
                      .orderBy('createdAt', descending: true),
                  emptyMessage: 'No pending event requests',
                  emptyIcon: Icons.pending_actions_rounded,
                  isPending: true,
                  isTablet: isTablet,
                ),
                
                // Active Events Tab
                _buildPremiumEventsList(
                  query: _firestore.collection('events')
                      .where('status', isEqualTo: 'approved')
                      .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
                      .orderBy('eventDate'),
                  emptyMessage: 'No active events',
                  emptyIcon: Icons.event_available_rounded,
                  isPending: false,
                  isTablet: isTablet,
                ),
                
                // Past Events Tab
                _buildPremiumEventsList(
                  query: _firestore.collection('events')
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
                SizedBox(height: 20),
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
                      colors: [_primaryRed.withOpacity(0.1), _primaryGreen.withOpacity(0.1)],
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
                      colors: [_primaryGreen.withOpacity(0.1), _primaryRed.withOpacity(0.1)],
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
            final event = EventModel.fromMap(eventDoc.data() as Map<String, dynamic>, eventDoc.id);
            
            return _buildPremiumEventCard(event, isPending, isTablet);
          },
        );
      },
    );
  }

  Widget _buildPremiumEventCard(EventModel event, bool isPending, bool isTablet) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToEventDetails(context, event, isPending),
        borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
        child: Container(
          margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1.5,
            ),
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTablet ? 25 : 20),
                  topRight: Radius.circular(isTablet ? 25 : 20),
                ),
                child: Container(
                  height: isTablet ? 180 : 150,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      event.bannerImageWidget,
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
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
              
              Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and Status
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: event.isPast ? Colors.grey.withOpacity(0.1) : _primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                            border: Border.all(
                              color: event.isPast ? Colors.grey : _primaryRed,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            event.categoryText,
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: event.isPast ? Colors.grey : _primaryRed,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(event.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                            border: Border.all(
                              color: _getStatusColor(event.status),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _getStatusText(event.status).toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: FontWeight.w800,
                              color: _getStatusColor(event.status),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Spacer(),
                        if (isPending)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: isTablet ? 8 : 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryRed, _deepRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryRed.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded, 
                                  size: isTablet ? 14 : 12, 
                                  color: Colors.white
                                ),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  'Review Required',
                                  style: GoogleFonts.inter(
                                    fontSize: isTablet ? 12 : 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 20 : 16),
                    
                    // Event Title
                    Text(
                      event.title,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: isTablet ? 20 : 16),
                    
                    // Date and Location
                    Row(
                      children: [
                        Container(
                          width: isTablet ? 50 : 40,
                          height: isTablet ? 50 : 40,
                          decoration: BoxDecoration(
                            color: _primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: isTablet ? 22 : 18,
                              color: _primaryGreen,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date & Time',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                event.formattedDate,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 16 : 12),
                    
                    Row(
                      children: [
                        Container(
                          width: isTablet ? 50 : 40,
                          height: isTablet ? 50 : 40,
                          decoration: BoxDecoration(
                            color: _primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.location_on_rounded,
                              size: isTablet ? 22 : 18,
                              color: _primaryRed,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                event.location,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w600,
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
                    
                    SizedBox(height: isTablet ? 20 : 16),
                    
                    // Footer with Organizer and Stats
                    Row(
                      children: [
                        CircleAvatar(
                          radius: isTablet ? 18 : 14,
                          backgroundColor: _blue.withOpacity(0.1),
                          child: Icon(
                            Icons.person_rounded,
                            color: _blue,
                            size: isTablet ? 18 : 14,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Organizer',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 12 : 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                event.organizer,
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 16 : 14,
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
                            horizontal: isTablet ? 16 : 12,
                            vertical: isTablet ? 10 : 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_orange.withOpacity(0.1), _goldAccent.withOpacity(0.1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_rounded,
                                color: _orange,
                                size: isTablet ? 18 : 14,
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                              Text(
                                '${event.totalInterested}',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: _orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 16 : 12),
                    
                    // View Details Button
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 14 : 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryGreen, _darkGreen],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                      ),
                      child: Center(
                        child: Text(
                          'View Details',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
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