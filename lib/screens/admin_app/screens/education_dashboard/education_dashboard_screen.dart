// lib/screens/admin/education/admin_education_dashboard.dart

import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:bangla_hub/screens/admin_app/screens/education_dashboard/admission_guidance/admission_guidance_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/education_dashboard/bangla_and_culture/bangla_and_culture_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/education_dashboard/sports_club/sports_club_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/education_dashboard/tutoring/tutoring_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminEducationDashboard extends StatefulWidget {
  @override
  _AdminEducationDashboardState createState() => _AdminEducationDashboardState();
}

class _AdminEducationDashboardState extends State<AdminEducationDashboard> with SingleTickerProviderStateMixin {
  final Color _primaryBlue = Color(0xFF1976D2);
  final Color _darkBlue = Color(0xFF0D47A1);
  final Color _lightBlue = Color(0xFFE3F2FD);
  
  late TabController _tabController;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<EducationProvider>(context, listen: false);
    await Future.wait([
      provider.loadTutoringServices(adminView: true),
      provider.loadAdmissionsGuidance(adminView: true),
      provider.loadBanglaClasses(adminView: true),
      provider.loadSportsClubs(adminView: true),
    ]);
    setState(() {
      _lastRefreshTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBlue,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: _primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryBlue, _darkBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                  //    padding: EdgeInsets.all(20),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Education & Youth',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 25),
                      /*    Text(
                            'Admin Management Panel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),*/
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
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Dashboard'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pending_actions_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Pending Reviews'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboardTab(),
            _buildPendingReviewsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: _primaryBlue,
        child: Icon(Icons.refresh_rounded),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Consumer<EducationProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: _loadData,
          color: _primaryBlue,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Last refreshed
              if (_lastRefreshTime != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.update_rounded, size: 14, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        'Last updated: ${_formatTimeAgo(_lastRefreshTime!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              
              _buildStatsSection(provider),
              SizedBox(height: 24),
              
              _buildQuickActions(),
              SizedBox(height: 24),
              
              _buildSectionHeader('Education Management'),
              _buildMenuCard(
                icon: Icons.school_rounded,
                title: 'Tutoring Services',
                subtitle: 'Manage tutoring and homework help listings',
                route: AdminTutoringScreen(),
                color: Colors.blue,
                pendingCount: provider.tutoringServices
                    .where((t) => !t.isVerified && !t.isDeleted && t.isActive)
                    .length,
              ),
              SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.business_center_rounded,
                title: 'Admissions Guidance',
                subtitle: 'Manage school & college admissions consultants',
                route: AdminAdmissionsScreen(),
                color: Colors.green,
                pendingCount: provider.admissionsGuidance
                    .where((a) => !a.isVerified && !a.isDeleted && a.isActive)
                    .length,
              ),
              SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.language_rounded,
                title: 'Bangla Classes',
                subtitle: 'Manage Bangla language & culture classes',
                route: AdminBanglaClassesScreen(),
                color: Colors.orange,
                pendingCount: provider.banglaClasses
                    .where((b) => !b.isVerified && !b.isDeleted && b.isActive)
                    .length,
              ),
              SizedBox(height: 12),
              _buildMenuCard(
                icon: Icons.sports_rounded,
                title: 'Sports Clubs',
                subtitle: 'Manage local sports clubs',
                route: AdminSportsClubsScreen(),
                color: Colors.red,
                pendingCount: provider.sportsClubs
                    .where((s) => !s.isVerified && !s.isDeleted && s.isActive)
                    .length,
              ),
              
              SizedBox(height: 20),
              
              // System Status
              _buildSystemStatus(),
              
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingReviewsTab() {
    return Consumer<EducationProvider>(
      builder: (context, provider, child) {
        final pendingItems = _getPendingItems(provider);
        
        if (pendingItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 80, color: Colors.green[300]),
                SizedBox(height: 16),
                Text(
                  'All caught up!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.green[700]),
                ),
                SizedBox(height: 8),
                Text(
                  'No pending items to review',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: _primaryBlue,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: pendingItems.length,
            itemBuilder: (context, index) {
              final item = pendingItems[index];
              return _buildPendingItemCard(item);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(EducationProvider provider) {
    final totalTutoring = provider.tutoringServices.length;
    final totalAdmissions = provider.admissionsGuidance.length;
    final totalBangla = provider.banglaClasses.length;
    final totalSports = provider.sportsClubs.length;
    final total = totalTutoring + totalAdmissions + totalBangla + totalSports;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: _primaryBlue, size: 24),
              SizedBox(width: 8),
              Text(
                'Overview',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                icon: Icons.school_rounded,
                value: totalTutoring.toString(),
                label: 'Tutoring',
                color: Colors.blue,
                pending: provider.tutoringServices
                    .where((t) => !t.isVerified && !t.isDeleted && t.isActive)
                    .length,
              ),
              _buildStatCard(
                icon: Icons.business_center_rounded,
                value: totalAdmissions.toString(),
                label: 'Admissions',
                color: Colors.green,
                pending: provider.admissionsGuidance
                    .where((a) => !a.isVerified && !a.isDeleted && a.isActive)
                    .length,
              ),
              _buildStatCard(
                icon: Icons.language_rounded,
                value: totalBangla.toString(),
                label: 'Bangla',
                color: Colors.orange,
                pending: provider.banglaClasses
                    .where((b) => !b.isVerified && !b.isDeleted && b.isActive)
                    .length,
              ),
              _buildStatCard(
                icon: Icons.sports_rounded,
                value: totalSports.toString(),
                label: 'Sports',
                color: Colors.red,
                pending: provider.sportsClubs
                    .where((s) => !s.isVerified && !s.isDeleted && s.isActive)
                    .length,
              ),
            ],
          ),
          
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 8),
          
          // Engagement Stats
          Row(
            children: [
              Expanded(
                child: _buildEngagementStat(
                  icon: Icons.favorite_rounded,
                  value: _formatNumber(
                    provider.tutoringServices.fold<int>(0, (sum, t) => sum + t.totalLikes) +
                    provider.admissionsGuidance.fold<int>(0, (sum, a) => sum + a.totalLikes) +
                    provider.banglaClasses.fold<int>(0, (sum, b) => sum + b.totalLikes) +
                    provider.sportsClubs.fold<int>(0, (sum, s) => sum + s.totalLikes)
                  ),
                  label: 'Total Likes',
                  color: Colors.red,
                ),
              ),
              Expanded(
                child: _buildEngagementStat(
                  icon: Icons.visibility_rounded,
                  value: _formatNumber(
                    provider.tutoringServices.fold<int>(0, (sum, t) => sum + (t.totalReviews)) +
                    provider.admissionsGuidance.fold<int>(0, (sum, a) => sum + a.totalReviews) +
                    provider.banglaClasses.fold<int>(0, (sum, b) => sum + b.totalReviews) +
                    provider.sportsClubs.fold<int>(0, (sum, s) => sum + s.totalReviews)
                  ),
                  label: 'Total Reviews',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_rounded, size: 20, color: _primaryBlue),
              SizedBox(width: 8),
              Text(
                'Total Listings: $total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

/*  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    int pending = 0,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  if (pending > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pending.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }  */

Widget _buildStatCard({
  required IconData icon,
  required String value,
  required String label,
  required Color color,
  int pending = 0,
}) {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            if (pending > 0) ...[
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    pending.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 2),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}


  Widget _buildEngagementStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on_rounded, color: _primaryBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2,
            children: [
              _buildQuickActionButton(
                icon: Icons.school_rounded,
                label: 'Add Tutor',
                color: Colors.blue,
                onTap: () {
                  // Navigate to add tutor screen
                },
              ),
              _buildQuickActionButton(
                icon: Icons.business_center_rounded,
                label: 'Add Consultant',
                color: Colors.green,
                onTap: () {
                  // Navigate to add consultant screen
                },
              ),
              _buildQuickActionButton(
                icon: Icons.language_rounded,
                label: 'Add Class',
                color: Colors.orange,
                onTap: () {
                  // Navigate to add class screen
                },
              ),
              _buildQuickActionButton(
                icon: Icons.sports_rounded,
                label: 'Add Club',
                color: Colors.red,
                onTap: () {
                  // Navigate to add club screen
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItemCard(dynamic item) {
    String type;
    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (item is TutoringService) {
      type = 'Tutoring';
      color = Colors.blue;
      icon = Icons.school_rounded;
      title = item.tutorName;
      subtitle = '${item.subjects.length} subjects • ${item.city}';
    } else if (item is AdmissionsGuidance) {
      type = 'Admissions';
      color = Colors.green;
      icon = Icons.business_center_rounded;
      title = item.consultantName;
      subtitle = '${item.specializations.length} specializations';
    } else if (item is BanglaClass) {
      type = 'Bangla Class';
      color = Colors.orange;
      icon = Icons.language_rounded;
      title = item.instructorName;
      subtitle = '${item.classTypes.join(', ')}';
    } else if (item is SportsClub) {
      type = 'Sports Club';
      color = Colors.red;
      icon = Icons.sports_rounded;
      title = item.clubName;
      subtitle = item.sportType.displayName;
    } else {
      return SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to appropriate details screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getTimeAgo(item.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
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

  Widget _buildSystemStatus() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_rounded, color: _primaryBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'System Status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildStatusRow(
            label: 'Database Connection',
            status: 'Connected',
            color: Colors.green,
          ),
          _buildStatusRow(
            label: 'Storage Service',
            status: 'Operational',
            color: Colors.green,
          ),
          _buildStatusRow(
            label: 'Image Processing',
            status: 'Active',
            color: Colors.green,
          ),
          _buildStatusRow(
            label: 'Analytics',
            status: 'Collecting Data',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String status,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkBlue,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget route,
    required Color color,
    int pendingCount = 0,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => route),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (pendingCount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pendingCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> _getPendingItems(EducationProvider provider) {
    List<dynamic> pending = [];
    
    pending.addAll(provider.tutoringServices
        .where((t) => !t.isVerified && !t.isDeleted && t.isActive)
        .take(5)
        .toList());
    
    pending.addAll(provider.admissionsGuidance
        .where((a) => !a.isVerified && !a.isDeleted && a.isActive)
        .take(5)
        .toList());
    
    pending.addAll(provider.banglaClasses
        .where((b) => !b.isVerified && !b.isDeleted && b.isActive)
        .take(5)
        .toList());
    
    pending.addAll(provider.sportsClubs
        .where((s) => !s.isVerified && !s.isDeleted && s.isActive)
        .take(5)
        .toList());
    
    // Sort by date (newest first)
    pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return pending;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}