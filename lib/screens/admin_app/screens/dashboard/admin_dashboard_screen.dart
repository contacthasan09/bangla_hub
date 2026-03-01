// screens/admin/dashboard/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Live data
  int _totalUsers = 0;
  int _activeEvents = 0;
  int _businessListings = 0;
  int _jobPostings = 0;
  int _serviceProviders = 0;
  int _communityServices = 0;
  
  // Active Users Filters
  String _activeUsersFilter = 'today';
  String _activeUsersDisplayName = 'Today';
  int _activeUsersCount = 0;
  bool _isLoadingActiveUsers = false;
  Map<String, int> _activeUsersStats = {
    'today': 0,
    'yesterday': 0,
    'last7days': 0,
    'last30days': 0,
    'allTime': 0,
  };
  
  // Recent activity
  List<Map<String, dynamic>> _recentUsers = [];
  List<Map<String, dynamic>> _recentEvents = [];
  List<Map<String, dynamic>> _recentServices = [];
  List<Map<String, dynamic>> _recentBusinesses = [];
  List<Map<String, dynamic>> _recentJobs = [];

  // Loading states
  bool _isLoading = true;

  // Color Palette
  final Color _primaryRed = Color(0xFFE03C32);
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF00432D);
  final Color _goldAccent = Color(0xFFFFD700);
  final Color _bgGradient1 = Color(0xFF0A2F1D);
  final Color _bgGradient2 = Color(0xFF004D38);
  final Color _cardColor = Color(0x1AFFFFFF);
  final Color _borderColor = Color(0x33FFFFFF);
  final Color _textWhite = Color(0xFFFFFFFF);
  final Color _textLight = Color(0xFFE0E0E0);
  final Color _textMuted = Color(0xFFAAAAAA);
  final Color _successGreen = Color(0xFF4CAF50);
  final Color _warningOrange = Color(0xFFFF9800);
  final Color _infoBlue = Color(0xFF2196F3);
  final Color _pink = Color(0xFFE91E63);
  final Color _teal = Color(0xFF009688);
  final Color _purple = Color(0xFF9C27B0);
  final Color _amber = Color(0xFFFFC107);
  final Color _deepPurple = Color(0xFF673AB7);
  final Color _cyan = Color(0xFF00BCD4);
  final Color _indigo = Color(0xFF3F51B5);

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _setupRealtimeListeners();
  }

  void _loadAllData() {
  //  _setupRealtimeListeners();
    _loadRecentActivity();
    _calculateActiveUsers();
  }

  void _setupRealtimeListeners() {
    // Real-time listeners for live data updates
    _firestore.collection('users').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _totalUsers = snapshot.docs.length;
        });
        _calculateActiveUsers();
      }
    });

    _firestore.collection('events')
      .where('status', isEqualTo: 'approved')
      .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
      .snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _activeEvents = snapshot.docs.length;
        });
      }
    });

    _firestore.collection('businesses')
      .where('isVerified', isEqualTo: true)
      .snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _businessListings = snapshot.docs.length;
        });
      }
    });

    _firestore.collection('jobs')
      .where('isActive', isEqualTo: true)
      .snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _jobPostings = snapshot.docs.length;
        });
      }
    });

    _firestore.collection('service_providers')
      .where('isDeleted', isEqualTo: false)
      .snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _serviceProviders = snapshot.docs.length;
        });
      }
    });
  }

  Future<void> _calculateActiveUsers() async {
    try {
      setState(() {
        _isLoadingActiveUsers = true;
      });

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayStart.subtract(Duration(days: 1));
      final weekAgo = now.subtract(Duration(days: 7));
      final monthAgo = now.subtract(Duration(days: 30));

      final usersSnapshot = await _firestore.collection('users').get();
      
      int todayCount = 0;
      int yesterdayCount = 0;
      int last7DaysCount = 0;
      int last30DaysCount = 0;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final lastActiveAt = data['lastActiveAt'] as Timestamp?;
        final createdAt = data['createdAt'] as Timestamp?;
        
        DateTime? userDate;
        if (lastActiveAt != null) {
          userDate = lastActiveAt.toDate();
        } else if (createdAt != null) {
          userDate = createdAt.toDate();
        }

        if (userDate != null) {
          if (userDate.isAfter(todayStart)) {
            todayCount++;
          }
          
          if (userDate.isAfter(yesterdayStart) && userDate.isBefore(todayStart)) {
            yesterdayCount++;
          }
          
          if (userDate.isAfter(weekAgo)) {
            last7DaysCount++;
          }
          
          if (userDate.isAfter(monthAgo)) {
            last30DaysCount++;
          }
        }
      }

      setState(() {
        _activeUsersStats = {
          'today': todayCount,
          'yesterday': yesterdayCount,
          'last7days': last7DaysCount,
          'last30days': last30DaysCount,
          'allTime': usersSnapshot.docs.length,
        };
        _activeUsersCount = _activeUsersStats[_activeUsersFilter] ?? 0;
        _isLoadingActiveUsers = false;
      });
    } catch (e) {
      print('Error calculating active users: $e');
      setState(() {
        _isLoadingActiveUsers = false;
      });
    }
  }

  void _updateActiveUsersFilter(String filter, String displayName) {
    setState(() {
      _activeUsersFilter = filter;
      _activeUsersDisplayName = displayName;
      _activeUsersCount = _activeUsersStats[filter] ?? 0;
    });
  }

  void _loadRecentActivity() async {
    try {
      // Load recent users
      final usersSnapshot = await _firestore.collection('users')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

      _recentUsers = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          'email': data['email'] ?? 'N/A',
          'time': _formatTimeAgo(data['createdAt']?.toDate()),
          'type': 'user',
        };
      }).toList();

      // Load recent events
      final eventsSnapshot = await _firestore.collection('events')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

      _recentEvents = eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'New Event',
          'organizer': data['organizer'] ?? 'Unknown',
          'time': _formatTimeAgo(data['createdAt']?.toDate()),
          'type': 'event',
        };
      }).toList();

      // Load recent services
      final servicesSnapshot = await _firestore.collection('service_providers')
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

      _recentServices = servicesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['fullName'] ?? 'New Service',
          'company': data['companyName'] ?? 'Unknown',
          'time': _formatTimeAgo(data['createdAt']?.toDate()),
          'type': 'service',
        };
      }).toList();

      // Load recent businesses
      final businessesSnapshot = await _firestore.collection('businesses')
        .where('isVerified', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

      _recentBusinesses = businessesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['businessName'] ?? 'New Business',
          'category': data['category'] ?? 'General',
          'time': _formatTimeAgo(data['createdAt']?.toDate()),
          'type': 'business',
        };
      }).toList();

      // Load recent jobs
      final jobsSnapshot = await _firestore.collection('jobs')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

      _recentJobs = jobsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['jobTitle'] ?? 'New Job',
          'company': data['companyName'] ?? 'Unknown',
          'time': _formatTimeAgo(data['createdAt']?.toDate()),
          'type': 'job',
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recent activity: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Recently';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}min ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return DateFormat('MMM d').format(date);
  }

  String _formatLargeNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) {
      double result = number / 1000;
      return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}K';
    }
    double result = number / 1000000;
    return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}M';
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required bool isTablet,
  }) {
    return Container(
      height: isTablet ? 120 : 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isTablet ? 50 : 44,
                  height: isTablet ? 50 : 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: color,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                ),
                Text(
                  _formatLargeNumber(value),
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 28 : 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveUsersSection(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isTablet ? 50 : 44,
                  height: isTablet ? 50 : 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_purple, _amber],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.timeline_rounded,
                      color: Colors.white,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Users Analytics',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 22 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Real-time user engagement metrics',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 14 : 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 24 : 20),

            // Active Users Stats Card
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_purple.withOpacity(0.05), _amber.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _purple.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activeUsersDisplayName,
                              style: GoogleFonts.inter(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (_isLoadingActiveUsers)
                              SizedBox(
                                height: isTablet ? 40 : 36,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _purple,
                                  ),
                                ),
                              )
                            else
                              Text(
                                _formatLargeNumber(_activeUsersCount),
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 36 : 32,
                                  fontWeight: FontWeight.w800,
                                  color: _purple,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: isTablet ? 120 : 100,
                        child: _buildTimeFilterDropdown(isTablet),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  
                  // Quick Stats Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTimeFilterButton(
                          label: 'Today',
                          count: _activeUsersStats['today'] ?? 0,
                          isActive: _activeUsersFilter == 'today',
                          color: _successGreen,
                          onTap: () => _updateActiveUsersFilter('today', 'Today'),
                        ),
                        SizedBox(width: 8),
                        _buildTimeFilterButton(
                          label: 'Yesterday',
                          count: _activeUsersStats['yesterday'] ?? 0,
                          isActive: _activeUsersFilter == 'yesterday',
                          color: _infoBlue,
                          onTap: () => _updateActiveUsersFilter('yesterday', 'Yesterday'),
                        ),
                        SizedBox(width: 8),
                        _buildTimeFilterButton(
                          label: 'Last 7 Days',
                          count: _activeUsersStats['last7days'] ?? 0,
                          isActive: _activeUsersFilter == 'last7days',
                          color: _amber,
                          onTap: () => _updateActiveUsersFilter('last7days', 'Last 7 Days'),
                        ),
                        SizedBox(width: 8),
                        _buildTimeFilterButton(
                          label: 'Last 30 Days',
                          count: _activeUsersStats['last30days'] ?? 0,
                          isActive: _activeUsersFilter == 'last30days',
                          color: _pink,
                          onTap: () => _updateActiveUsersFilter('last30days', 'Last 30 Days'),
                        ),
                        SizedBox(width: 8),
                        _buildTimeFilterButton(
                          label: 'All Time',
                          count: _activeUsersStats['allTime'] ?? 0,
                          isActive: _activeUsersFilter == 'allTime',
                          color: _teal,
                          onTap: () => _updateActiveUsersFilter('allTime', 'All Time'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            // Info Text
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _purple.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_rounded,
                    color: _purple,
                    size: isTablet ? 20 : 16,
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Expanded(
                    child: Text(
                      'Active users are calculated based on user activity within the selected timeframe.',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterDropdown(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _purple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _activeUsersFilter,
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: _purple,
              size: isTablet ? 24 : 20,
            ),
            isExpanded: true,
            style: TextStyle(
              color: _purple,
              fontSize: isTablet ? 14 : 13,
              fontWeight: FontWeight.w600,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(10),
            onChanged: (String? newValue) {
              if (newValue != null) {
                String displayName = '';
                switch (newValue) {
                  case 'today':
                    displayName = 'Today';
                    break;
                  case 'yesterday':
                    displayName = 'Yesterday';
                    break;
                  case 'last7days':
                    displayName = 'Last 7 Days';
                    break;
                  case 'last30days':
                    displayName = 'Last 30 Days';
                    break;
                  case 'allTime':
                    displayName = 'All Time';
                    break;
                }
                _updateActiveUsersFilter(newValue, displayName);
              }
            },
            items: [
              DropdownMenuItem<String>(
                value: 'today',
                child: Text('Today'),
              ),
              DropdownMenuItem<String>(
                value: 'yesterday',
                child: Text('Yesterday'),
              ),
              DropdownMenuItem<String>(
                value: 'last7days',
                child: Text('Last 7 Days'),
              ),
              DropdownMenuItem<String>(
                value: 'last30days',
                child: Text('Last 30 Days'),
              ),
              DropdownMenuItem<String>(
                value: 'allTime',
                child: Text('All Time'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilterButton({
    required String label,
    required int count,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? Colors.white : color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatLargeNumber(count),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isTablet) {
    final allActivities = [
      ..._recentUsers,
      ..._recentEvents,
      ..._recentServices,
      ..._recentBusinesses,
      ..._recentJobs,
    ]..sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));

    final recentActivities = allActivities.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isTablet ? 50 : 44,
                  height: isTablet ? 50 : 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryGreen, _primaryRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.history_rounded,
                      color: Colors.white,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 22 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Latest platform activities',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 14 : 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            
            if (recentActivities.isEmpty)
              Container(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: recentActivities.map((activity) {
                  return _buildActivityItem(activity, isTablet);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, bool isTablet) {
    final type = activity['type'];
    final title = activity['name'] ?? activity['title'] ?? '';
    final subtitle = activity['email'] ?? activity['organizer'] ?? 
                    activity['company'] ?? activity['category'] ?? '';
    final time = activity['time'] ?? 'Recently';
    
    Color color;
    IconData icon;
    
    switch (type) {
      case 'user':
        color = _infoBlue;
        icon = Icons.person_add_rounded;
        break;
      case 'event':
        color = _pink;
        icon = Icons.event_available_rounded;
        break;
      case 'service':
        color = _successGreen;
        icon = Icons.handyman_rounded;
        break;
      case 'business':
        color = _teal;
        icon = Icons.business_center_rounded;
        break;
      case 'job':
        color = _amber;
        icon = Icons.work_rounded;
        break;
      default:
        color = _purple;
        icon = Icons.notifications_rounded;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 13 : 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 12 : 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isSmallTablet = screenWidth >= 600 && screenWidth < 768;
    final isLargePhone = screenWidth >= 400 && screenWidth < 600;
    final isSmallPhone = screenWidth < 400;

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgGradient1, _bgGradient2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isTablet ? 80 : 60,
                height: isTablet ? 80 : 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed, _primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.dashboard_rounded,
                    color: Colors.white,
                    size: isTablet ? 40 : 32,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 28 : 24),
              Text(
                'Loading Dashboard...',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 28 : 22,
                  fontWeight: FontWeight.w800,
                  color: _primaryGreen,
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                'Gathering real-time platform data',
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18 : 16,
                  color: _textMuted,
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20),
              SizedBox(
                width: isTablet ? 40 : 30,
                height: isTablet ? 40 : 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: _bgGradient2.withOpacity(0.05),
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallPhone ? 16 : 
                   isLargePhone ? 20 : 
                   isSmallTablet ? 24 : 
                   isTablet ? 32 : 24,
          vertical: isTablet ? 24 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Title
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryGreen.withOpacity(0.9), _primaryRed.withOpacity(0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: isTablet ? 70 : 60,
                    height: isTablet ? 70 : 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryRed, _primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: isTablet ? 32 : 28,
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 20 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard Analytics',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 28 : 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete platform oversight & analytics',
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isTablet ? 32 : 28),
            
            // Platform Overview Grid
            Text(
              'Platform Overview',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 22 : 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard(
                  title: 'Total Users',
                  value: _totalUsers,
                  icon: Icons.people_alt_rounded,
                  color: _infoBlue,
                  isTablet: isTablet,
                ),
                _buildStatCard(
                  title: 'Active Events',
                  value: _activeEvents,
                  icon: Icons.event_available_rounded,
                  color: _pink,
                  isTablet: isTablet,
                ),
                _buildStatCard(
                  title: 'Business Listings',
                  value: _businessListings,
                  icon: Icons.business_center_rounded,
                  color: _teal,
                  isTablet: isTablet,
                ),
                _buildStatCard(
                  title: 'Job Postings',
                  value: _jobPostings,
                  icon: Icons.work_rounded,
                  color: _amber,
                  isTablet: isTablet,
                ),
                _buildStatCard(
                  title: 'Service Providers',
                  value: _serviceProviders,
                  icon: Icons.handyman_rounded,
                  color: _successGreen,
                  isTablet: isTablet,
                ),
                _buildStatCard(
                  title: 'Community Services',
                  value: _communityServices,
                  icon: Icons.diversity_3_rounded,
                  color: _deepPurple,
                  isTablet: isTablet,
                ),
              ],
            ),
            
            SizedBox(height: isTablet ? 32 : 28),
            
            // Active Users Analytics Section
            _buildActiveUsersSection(isTablet),
            
            SizedBox(height: isTablet ? 24 : 20),
            
            // Recent Activity Section
            _buildRecentActivitySection(isTablet),
            
            // Bottom padding for scrolling
            SizedBox(height: isTablet ? 40 : 32),
          ],
        ),
      ),
    );
  }
}