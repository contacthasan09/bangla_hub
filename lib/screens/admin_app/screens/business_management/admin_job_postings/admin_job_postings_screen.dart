// lib/screens/admin/entrepreneurship/admin_job_postings_screen.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminJobPostingsScreen extends StatefulWidget {
  @override
  _AdminJobPostingsScreenState createState() => _AdminJobPostingsScreenState();
}

class _AdminJobPostingsScreenState extends State<AdminJobPostingsScreen> with SingleTickerProviderStateMixin {
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
    });
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
    }
  }

  Future<void> _loadJobs() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    await provider.loadJobPostings(adminView: true, includeExpired: true);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: isSmallScreen ? 200 : (isTablet ? 260 : 220),
              floating: false,
              pinned: true,
              backgroundColor: _primaryGreen,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryGreen, _darkGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 20, 
                        vertical: isTablet ? 30 : 20
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Job Postings',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 28 : (isSmallScreen ? 20 : 24),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            'Review, verify, and manage job postings',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(isTablet ? 140 : 120),
                child: Container(
                  color: _primaryGreen,
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                          vertical: isTablet ? 12 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: isTablet 
                                ? 'Search jobs by title, company, location...'
                                : 'Search jobs...',
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isTablet ? 16 : 12,
                            ),
                          ),
                        ),
                      ),
                      
                      // Tab Bar
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 800 : double.infinity,
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white.withOpacity(0.7),
                          isScrollable: isSmallScreen,
                          tabs: [
                            Tab(
                              child: Consumer<EntrepreneurshipProvider>(
                                builder: (context, provider, child) {
                                  final count = provider.jobPostings
                                      .where((j) => !j.isVerified && !j.isDeleted && j.isActive)
                                      .length;
                                  return _buildTabContent(
                                    icon: Icons.pending_actions_rounded,
                                    label: isSmallScreen ? 'Pend' : 'Pending',
                                    count: count,
                                    color: Colors.orange,
                                    isSmallScreen: isSmallScreen,
                                  );
                                },
                              ),
                            ),
                            Tab(
                              child: Consumer<EntrepreneurshipProvider>(
                                builder: (context, provider, child) {
                                  final count = provider.jobPostings
                                      .where((j) => j.isVerified && !j.isDeleted && j.isActive && !j.isExpired)
                                      .length;
                                  return _buildTabContent(
                                    icon: Icons.check_circle_rounded,
                                    label: 'Active',
                                    count: count,
                                    color: Colors.green,
                                    isSmallScreen: isSmallScreen,
                                  );
                                },
                              ),
                            ),
                            Tab(
                              child: Consumer<EntrepreneurshipProvider>(
                                builder: (context, provider, child) {
                                  final count = provider.jobPostings
                                      .where((j) => j.isDeleted || !j.isActive || j.isExpired)
                                      .length;
                                  return _buildTabContent(
                                    icon: Icons.block_rounded,
                                    label: 'Rejected',
                                    count: count,
                                    color: Colors.red,
                                    isSmallScreen: isSmallScreen,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Consumer<EntrepreneurshipProvider>(
          builder: (context, provider, child) {
            if (_isLoading && provider.jobPostings.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: _primaryGreen),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildJobList(provider, 'pending'),
                _buildJobList(provider, 'active'),
                _buildJobList(provider, 'rejected'),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadJobs,
        backgroundColor: _primaryGreen,
        child: Icon(Icons.refresh_rounded),
      ),
    );
  }

  Widget _buildTabContent({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 8,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 16 : 18),
          SizedBox(width: isSmallScreen ? 4 : 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isSmallScreen ? 4 : 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 4 : 6, 
              vertical: 2
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList(EntrepreneurshipProvider provider, String type) {
    List<JobPosting> filteredJobs;
    
    switch (type) {
      case 'pending':
        filteredJobs = provider.jobPostings
            .where((j) => !j.isVerified && !j.isDeleted && j.isActive)
            .toList();
        break;
      case 'active':
        filteredJobs = provider.jobPostings
            .where((j) => j.isVerified && !j.isDeleted && j.isActive && !j.isExpired)
            .toList();
        break;
      case 'rejected':
        filteredJobs = provider.jobPostings
            .where((j) => j.isDeleted || !j.isActive || j.isExpired)
            .toList();
        break;
      default:
        filteredJobs = [];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredJobs = filteredJobs.where((job) {
        return job.jobTitle.toLowerCase().contains(_searchQuery) ||
               job.companyName.toLowerCase().contains(_searchQuery) ||
               job.description.toLowerCase().contains(_searchQuery) ||
               job.location.toLowerCase().contains(_searchQuery) ||
               job.city.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Sort by date (newest first) and urgent first
    filteredJobs.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    if (filteredJobs.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty 
            ? 'No matching results found'
            : type == 'pending' 
                ? 'No pending job postings' 
                : type == 'active' 
                    ? 'No active job postings' 
                    : 'No rejected job postings',
        type == 'pending' ? Icons.pending_actions_rounded :
        type == 'active' ? Icons.work_rounded : Icons.block_rounded,
        hasSearch: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      color: _primaryGreen,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredJobs.length,
        itemBuilder: (context, index) {
          return _buildJobCard(filteredJobs[index], type: type);
        },
      ),
    );
  }

  Widget _buildJobCard(JobPosting job, {required String type}) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final imageBytes = _base64ToImage(job.companyLogoBase64);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: job.isUrgent && type == 'pending'
              ? Border.all(color: Colors.red, width: 2)
              : job.isExpired && type == 'active'
                  ? Border.all(color: Colors.grey, width: 2)
                  : null,
        ),
        child: InkWell(
          onTap: () => _showJobDetails(job, type),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo/Icon
                    Container(
                      width: isSmallScreen ? 50 : 60,
                      height: isSmallScreen ? 50 : 60,
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: imageBytes != null && imageBytes.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    job.isUrgent
                                        ? Icons.priority_high_rounded
                                        : Icons.work_rounded,
                                    color: _getTypeColor(type),
                                    size: isSmallScreen ? 25 : 30,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              job.isUrgent
                                  ? Icons.priority_high_rounded
                                  : Icons.work_rounded,
                              color: _getTypeColor(type),
                              size: isSmallScreen ? 25 : 30,
                            ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    
                    // Job Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  job.jobTitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (job.isUrgent)
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'URGENT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 8 : 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (job.isExpired && type == 'active')
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'EXPIRED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 8 : 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            job.companyName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w500,
                              color: _primaryGreen,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Posted by: ${job.postedBy}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 8 : 12),
                
                // Info Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildInfoChip(
                      Icons.location_on_rounded,
                      isSmallScreen ? job.city : '${job.city}, ${job.state}',
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.work_rounded,
                      job.jobType.displayName,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.school_rounded,
                      job.experienceLevel.displayName,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.attach_money_rounded,
                      job.formattedSalary.length > (isSmallScreen ? 15 : 20) 
                          ? '${job.formattedSalary.substring(0, isSmallScreen ? 15 : 20)}...' 
                          : job.formattedSalary,
                      isSmallScreen: isSmallScreen,
                    ),
                    if (job.numberOfVacancies > 1)
                      _buildInfoChip(
                        Icons.people_rounded,
                        '${job.numberOfVacancies} openings',
                        isSmallScreen: isSmallScreen,
                      ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 8 : 12),
                
                // Status and Stats Row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildStatusChip(job, type, isSmallScreen: isSmallScreen),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: isSmallScreen ? 12 : 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            _formatDate(job.applicationDeadline),
                            style: TextStyle(fontSize: isSmallScreen ? 10 : 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Admin Actions based on type
                _buildActionButtons(job, type, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(JobPosting job, String type, bool isSmallScreen) {
    if (type == 'pending') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVerificationDialog(job),
                  icon: Icon(Icons.check_circle_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Verify',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectionDialog(job),
                  icon: Icon(Icons.block_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Reject',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (type == 'active') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deactivateJob(job),
                  icon: Icon(Icons.pause_circle_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Deactivate',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange),
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteJob(job),
                  icon: Icon(Icons.delete_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Delete',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (type == 'rejected') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _restoreJob(job),
                  icon: Icon(Icons.restore_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Restore',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
               //   onPressed: () => _permanentDeleteJob(job),
               onPressed: () {
                 
               },
                  icon: Icon(Icons.delete_forever_rounded, size: isSmallScreen ? 14 : 18),
                  label: Text(
                    'Delete\nPermanently',
                    style: TextStyle(fontSize: isSmallScreen ? 9 : 12),
                    textAlign: TextAlign.center,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildInfoChip(IconData icon, String label, {required bool isSmallScreen}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 12 : 14, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: isSmallScreen ? 10 : 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(JobPosting job, String type, {required bool isSmallScreen}) {
    Color color;
    String text;
    IconData icon;

    switch (type) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        icon = Icons.pending_rounded;
        break;
      case 'active':
        if (job.isExpired) {
          color = Colors.grey;
          text = 'Expired';
          icon = Icons.timer_off_rounded;
        } else {
          color = Colors.green;
          text = 'Verified';
          icon = Icons.verified_rounded;
        }
        break;
      case 'rejected':
        if (job.isExpired) {
          color = Colors.grey;
          text = 'Expired';
          icon = Icons.timer_off_rounded;
        } else if (job.isDeleted) {
          color = Colors.red;
          text = 'Deleted';
          icon = Icons.delete_rounded;
        } else {
          color = Colors.grey;
          text = 'Inactive';
          icon = Icons.block_rounded;
        }
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
        icon = Icons.help_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 12 : 14, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState(String message, IconData icon, {bool hasSearch = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (hasSearch) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: Text('Clear Search'),
            ),
          ] else ...[
            SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  Uint8List? _base64ToImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    try {
      String cleaned = base64String.trim();

      if (cleaned.contains('base64,')) {
        cleaned = cleaned.split('base64,').last;
      }

      cleaned = cleaned.replaceAll(RegExp(r'\s'), '');

      if (cleaned.length % 4 != 0) {
        cleaned = cleaned.padRight(
          cleaned.length + (4 - cleaned.length % 4),
          '=',
        );
      }

      return base64Decode(cleaned);
    } catch (e) {
      print('Error decoding base64: $e');
      return null;
    }
  }

  void _showJobDetails(JobPosting job, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AdminJobDetailsSheet(
        job: job,
        type: type,
        onStatusChanged: _loadJobs,
        primaryGreen: _primaryGreen,
      ),
    );
  }

  void _showVerificationDialog(JobPosting job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Job Posting'),
        content: Text('Are you sure you want to verify "${job.jobTitle}" at ${job.companyName}? This will make it visible to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyJob(job);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _verifyJob(JobPosting job) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedJob = JobPosting(
      id: job.id,
      jobTitle: job.jobTitle,
      companyName: job.companyName,
      description: job.description,
      requirements: job.requirements,
      responsibilities: job.responsibilities,
      jobType: job.jobType,
      experienceLevel: job.experienceLevel,
      location: job.location,
      state: job.state,
      city: job.city,
      salaryMin: job.salaryMin,
      salaryMax: job.salaryMax,
      salaryPeriod: job.salaryPeriod,
      benefits: job.benefits,
      skillsRequired: job.skillsRequired,
      contactEmail: job.contactEmail,
      contactPhone: job.contactPhone,
      applicationLink: job.applicationLink,
      applicationDeadline: job.applicationDeadline,
      numberOfVacancies: job.numberOfVacancies,
      isVerified: true,
      isActive: true,
      isDeleted: false,
      isUrgent: job.isUrgent,
      postedBy: job.postedBy,
      createdAt: job.createdAt,
      updatedAt: DateTime.now(),
      companyLogoBase64: job.companyLogoBase64,
      additionalDocumentsBase64: job.additionalDocumentsBase64,
      additionalInfo: {
        ...?job.additionalInfo,
        'verifiedAt': DateTime.now().toIso8601String(),
        'verifiedBy': 'admin',
      },
      preferredQualifications: job.preferredQualifications,
      category: job.category,
    );

    final success = await provider.updateJobPosting(job.id!, updatedJob);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job posting verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadJobs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify job posting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectionDialog(JobPosting job) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Job Posting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${job.jobTitle}" at ${job.companyName}?'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Rejection Reason (Optional)',
                hintText: 'Provide a reason for rejection',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectJob(job, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _rejectJob(JobPosting job, String reason) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedJob = JobPosting(
      id: job.id,
      jobTitle: job.jobTitle,
      companyName: job.companyName,
      description: job.description,
      requirements: job.requirements,
      responsibilities: job.responsibilities,
      jobType: job.jobType,
      experienceLevel: job.experienceLevel,
      location: job.location,
      state: job.state,
      city: job.city,
      salaryMin: job.salaryMin,
      salaryMax: job.salaryMax,
      salaryPeriod: job.salaryPeriod,
      benefits: job.benefits,
      skillsRequired: job.skillsRequired,
      contactEmail: job.contactEmail,
      contactPhone: job.contactPhone,
      applicationLink: job.applicationLink,
      applicationDeadline: job.applicationDeadline,
      numberOfVacancies: job.numberOfVacancies,
      isVerified: false,
      isActive: false,
      isDeleted: true,
      isUrgent: job.isUrgent,
      postedBy: job.postedBy,
      createdAt: job.createdAt,
      updatedAt: DateTime.now(),
      companyLogoBase64: job.companyLogoBase64,
      additionalDocumentsBase64: job.additionalDocumentsBase64,
      additionalInfo: {
        ...?job.additionalInfo,
        'rejectionReason': reason,
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectedBy': 'admin',
      },
      preferredQualifications: job.preferredQualifications,
      category: job.category,
    );

    final success = await provider.updateJobPosting(job.id!, updatedJob);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job posting rejected${reason.isNotEmpty ? ': $reason' : ''}'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadJobs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject job posting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deactivateJob(JobPosting job) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedJob = JobPosting(
      id: job.id,
      jobTitle: job.jobTitle,
      companyName: job.companyName,
      description: job.description,
      requirements: job.requirements,
      responsibilities: job.responsibilities,
      jobType: job.jobType,
      experienceLevel: job.experienceLevel,
      location: job.location,
      state: job.state,
      city: job.city,
      salaryMin: job.salaryMin,
      salaryMax: job.salaryMax,
      salaryPeriod: job.salaryPeriod,
      benefits: job.benefits,
      skillsRequired: job.skillsRequired,
      contactEmail: job.contactEmail,
      contactPhone: job.contactPhone,
      applicationLink: job.applicationLink,
      applicationDeadline: job.applicationDeadline,
      numberOfVacancies: job.numberOfVacancies,
      isVerified: job.isVerified,
      isActive: false,
      isDeleted: false,
      isUrgent: job.isUrgent,
      postedBy: job.postedBy,
      createdAt: job.createdAt,
      updatedAt: DateTime.now(),
      companyLogoBase64: job.companyLogoBase64,
      additionalDocumentsBase64: job.additionalDocumentsBase64,
      additionalInfo: {
        ...?job.additionalInfo,
        'deactivatedAt': DateTime.now().toIso8601String(),
        'deactivatedBy': 'admin',
      },
      preferredQualifications: job.preferredQualifications,
      category: job.category,
    );

    final success = await provider.updateJobPosting(job.id!, updatedJob);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job posting deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadJobs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate job posting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteJob(JobPosting job) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedJob = JobPosting(
      id: job.id,
      jobTitle: job.jobTitle,
      companyName: job.companyName,
      description: job.description,
      requirements: job.requirements,
      responsibilities: job.responsibilities,
      jobType: job.jobType,
      experienceLevel: job.experienceLevel,
      location: job.location,
      state: job.state,
      city: job.city,
      salaryMin: job.salaryMin,
      salaryMax: job.salaryMax,
      salaryPeriod: job.salaryPeriod,
      benefits: job.benefits,
      skillsRequired: job.skillsRequired,
      contactEmail: job.contactEmail,
      contactPhone: job.contactPhone,
      applicationLink: job.applicationLink,
      applicationDeadline: job.applicationDeadline,
      numberOfVacancies: job.numberOfVacancies,
      isVerified: job.isVerified,
      isActive: false,
      isDeleted: true,
      isUrgent: job.isUrgent,
      postedBy: job.postedBy,
      createdAt: job.createdAt,
      updatedAt: DateTime.now(),
      companyLogoBase64: job.companyLogoBase64,
      additionalDocumentsBase64: job.additionalDocumentsBase64,
      additionalInfo: {
        ...?job.additionalInfo,
        'deletedAt': DateTime.now().toIso8601String(),
        'deletedBy': 'admin',
      },
      preferredQualifications: job.preferredQualifications,
      category: job.category,
    );

    final success = await provider.updateJobPosting(job.id!, updatedJob);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job posting moved to rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _loadJobs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete job posting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restoreJob(JobPosting job) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedJob = JobPosting(
      id: job.id,
      jobTitle: job.jobTitle,
      companyName: job.companyName,
      description: job.description,
      requirements: job.requirements,
      responsibilities: job.responsibilities,
      jobType: job.jobType,
      experienceLevel: job.experienceLevel,
      location: job.location,
      state: job.state,
      city: job.city,
      salaryMin: job.salaryMin,
      salaryMax: job.salaryMax,
      salaryPeriod: job.salaryPeriod,
      benefits: job.benefits,
      skillsRequired: job.skillsRequired,
      contactEmail: job.contactEmail,
      contactPhone: job.contactPhone,
      applicationLink: job.applicationLink,
      applicationDeadline: job.applicationDeadline,
      numberOfVacancies: job.numberOfVacancies,
      isVerified: false,
      isActive: true,
      isDeleted: false,
      isUrgent: job.isUrgent,
      postedBy: job.postedBy,
      createdAt: job.createdAt,
      updatedAt: DateTime.now(),
      companyLogoBase64: job.companyLogoBase64,
      additionalDocumentsBase64: job.additionalDocumentsBase64,
      additionalInfo: {
        ...?job.additionalInfo,
        'restoredAt': DateTime.now().toIso8601String(),
        'restoredBy': 'admin',
      },
      preferredQualifications: job.preferredQualifications,
      category: job.category,
    );

    final success = await provider.updateJobPosting(job.id!, updatedJob);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job posting restored to pending'),
            backgroundColor: Colors.green,
          ),
        );
        _loadJobs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore job posting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

/*  void _permanentDeleteJob(JobPosting job) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text(
          'Are you sure you want to permanently delete "${job.jobTitle}" at ${job.companyName}? '
          'This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    // Implement permanent delete method in your provider
    final success = await provider.permanentDeleteJobPosting(job.id!);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job posting permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
        _loadJobs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to permanently delete job posting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }  */
}

class AdminJobDetailsSheet extends StatelessWidget {
  final JobPosting job;
  final String type;
  final VoidCallback onStatusChanged;
  final Color primaryGreen;

  const AdminJobDetailsSheet({
    Key? key,
    required this.job,
    required this.type,
    required this.onStatusChanged,
    required this.primaryGreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width >= 600;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        initialChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Job Details',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1, thickness: 1),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  children: [
                    // Company Header
                    Row(
                      children: [
                        // Company Logo
                        Container(
                          width: isTablet ? 80 : 70,
                          height: isTablet ? 80 : 70,
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: job.companyLogoBase64 != null && job.companyLogoBase64!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _base64ToImage(job.companyLogoBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.business_rounded,
                                        color: primaryGreen,
                                        size: isTablet ? 40 : 35,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.business_rounded,
                                  color: primaryGreen,
                                  size: isTablet ? 40 : 35,
                                ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        
                        // Title and Company
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.jobTitle,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 26 : 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                job.companyName,
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 16,
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Status Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusBadge(
                          job.isVerified ? 'Verified' : 'Unverified',
                          job.isVerified ? Colors.green : Colors.orange,
                          isTablet: isTablet,
                        ),
                        _buildStatusBadge(
                          job.isActive ? 'Active' : 'Inactive',
                          job.isActive ? Colors.green : Colors.grey,
                          isTablet: isTablet,
                        ),
                        _buildStatusBadge(
                          job.isDeleted ? 'Deleted' : 'Not Deleted',
                          job.isDeleted ? Colors.red : Colors.green,
                          isTablet: isTablet,
                        ),
                        if (job.isExpired)
                          _buildStatusBadge('Expired', Colors.grey, isTablet: isTablet),
                        if (job.isUrgent)
                          _buildStatusBadge('Urgent', Colors.red, isTablet: isTablet),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Quick Stats
                    Container(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(Icons.people_rounded, 'Openings', job.numberOfVacancies.toString(), isTablet: isTablet),
                          _buildStatItem(Icons.access_time_rounded, 'Posted', _formatTimeAgo(job.createdAt), isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 28 : 24),
                    
                    // Job Description
                    _buildSectionTitle('Job Description', Icons.description_rounded, primaryGreen, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        job.description,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Requirements
                    _buildSectionTitle('Requirements', Icons.list_alt_rounded, Colors.blue, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        job.requirements,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Responsibilities
                    _buildSectionTitle('Responsibilities', Icons.task_rounded, Colors.purple, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        job.responsibilities,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Job Details Grid
                    _buildSectionTitle('Job Details', Icons.info_rounded, primaryGreen, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.work_rounded, 'Job Type', job.jobType.displayName, isTablet: isTablet),
                          _buildDetailRow(Icons.school_rounded, 'Experience', job.experienceLevel.displayName, isTablet: isTablet),
                          _buildDetailRow(Icons.location_on_rounded, 'Location', '${job.location}, ${job.city}, ${job.state}', isTablet: isTablet),
                          _buildDetailRow(Icons.attach_money_rounded, 'Salary', job.formattedSalary, isTablet: isTablet),
                          _buildDetailRow(Icons.calendar_today_rounded, 'Deadline', _formatDate(job.applicationDeadline), isTablet: isTablet),
                          _buildDetailRow(Icons.person_rounded, 'Posted By', job.postedBy, isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    if (job.skillsRequired.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Skills Required', Icons.code_rounded, Colors.blue, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: job.skillsRequired.map((skill) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12, 
                                vertical: isTablet ? 8 : 6
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                skill,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: Colors.blue[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    if (job.preferredQualifications.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Preferred Qualifications', Icons.star_rounded, Colors.amber, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Column(
                          children: job.preferredQualifications.map((qual) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: isTablet ? 18 : 16, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      qual,
                                      style: TextStyle(fontSize: isTablet ? 15 : 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    if (job.benefits.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Benefits', Icons.card_giftcard_rounded, Colors.green, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: job.benefits.map((benefit) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12, 
                                vertical: isTablet ? 8 : 6
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                benefit,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: Colors.green[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Contact Information
                    _buildSectionTitle('Contact Information', Icons.contact_phone_rounded, primaryGreen, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildContactInfo(Icons.email_rounded, job.contactEmail, isLink: true, isTablet: isTablet),
                          Divider(height: 16),
                          _buildContactInfo(Icons.phone_rounded, job.contactPhone, isLink: true, isTablet: isTablet),
                          if (job.applicationLink != null && job.applicationLink!.isNotEmpty) ...[
                            Divider(height: 16),
                            _buildContactInfo(Icons.link_rounded, 'Apply Online', isLink: true, url: job.applicationLink, isTablet: isTablet),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Timestamps
                    _buildSectionTitle('Timestamps', Icons.access_time_rounded, Colors.grey, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.add_circle_rounded, 'Created', _formatDateTime(job.createdAt), isTablet: isTablet),
                          _buildInfoRow(Icons.update_rounded, 'Updated', _formatDateTime(job.updatedAt), isTablet: isTablet),
                          if (job.additionalInfo?['verifiedAt'] != null)
                            _buildInfoRow(Icons.verified_rounded, 'Verified', 
                                _formatDateTime(DateTime.parse(job.additionalInfo!['verifiedAt'])), isTablet: isTablet),
                          if (job.additionalInfo?['rejectedAt'] != null)
                            _buildInfoRow(Icons.cancel_rounded, 'Rejected', 
                                _formatDateTime(DateTime.parse(job.additionalInfo!['rejectedAt'])), isTablet: isTablet),
                          if (job.additionalInfo?['deactivatedAt'] != null)
                            _buildInfoRow(Icons.pause_circle_rounded, 'Deactivated', 
                                _formatDateTime(DateTime.parse(job.additionalInfo!['deactivatedAt'])), isTablet: isTablet),
                          if (job.additionalInfo?['restoredAt'] != null)
                            _buildInfoRow(Icons.restore_rounded, 'Restored', 
                                _formatDateTime(DateTime.parse(job.additionalInfo!['restoredAt'])), isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 28 : 24),
                    
                    // Admin Actions based on type
                    _buildDetailsActionButtons(context, isTablet),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailsActionButtons(BuildContext context, bool isTablet) {
    if (type == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger rejection
              },
              icon: Icon(Icons.block_rounded, size: isTablet ? 20 : 18),
              label: Text(
                'Reject',
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger verification
              },
              icon: Icon(Icons.check_circle_rounded, size: isTablet ? 20 : 18),
              label: Text(
                'Verify',
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (type == 'active') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger deactivation
              },
              icon: Icon(Icons.pause_circle_rounded, size: isTablet ? 20 : 18),
              label: Text(
                'Deactivate',
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger deletion
              },
              icon: Icon(Icons.delete_rounded, size: isTablet ? 20 : 18),
              label: Text(
                'Delete',
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (type == 'rejected') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger restore
              },
              icon: Icon(Icons.restore_rounded, size: isTablet ? 20 : 18),
              label: Text(
                'Restore',
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger permanent deletion
              },
              icon: Icon(Icons.delete_forever_rounded, size: isTablet ? 20 : 18),
              label: Text(
                'Delete\nPermanently',
                style: TextStyle(fontSize: isTablet ? 14 : 12),
                textAlign: TextAlign.center,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusBadge(String label, Color color, {required bool isTablet}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12, 
        vertical: isTablet ? 8 : 6
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle_rounded,
            size: isTablet ? 10 : 8,
            color: color,
          ),
          SizedBox(width: isTablet ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {required bool isTablet}) {
    return Column(
      children: [
        Icon(icon, color: primaryGreen, size: isTablet ? 26 : 22),
        SizedBox(height: isTablet ? 6 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 13 : 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color, {required bool isTablet}) {
    return Row(
      children: [
        Icon(icon, color: color, size: isTablet ? 24 : 20),
        SizedBox(width: isTablet ? 10 : 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {required bool isTablet}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isTablet ? 20 : 18, color: Colors.grey[600]),
          SizedBox(width: isTablet ? 14 : 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: isTablet ? 15 : 14,
                  ),
                ),
                SizedBox(width: isTablet ? 10 : 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: isTablet ? 15 : 14, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {required bool isTablet}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isTablet ? 18 : 16, color: Colors.grey[600]),
          SizedBox(width: isTablet ? 10 : 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: isTablet ? 14 : 13,
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: isTablet ? 14 : 13, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String value, {required bool isLink, String? url, required bool isTablet}) {
    return InkWell(
      onTap: isLink ? () => _launchUrl(url ?? value) : null,
      child: Row(
        children: [
          Icon(icon, size: isTablet ? 20 : 18, color: Colors.grey[600]),
          SizedBox(width: isTablet ? 14 : 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: isLink ? primaryGreen : Colors.grey[800],
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
          if (isLink)
            Icon(Icons.open_in_new_rounded, size: isTablet ? 18 : 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Uint8List _base64ToImage(String base64String) {
    try {
      String cleaned = base64String.trim();
      if (cleaned.contains('base64,')) {
        cleaned = cleaned.split('base64,').last;
      }
      cleaned = cleaned.replaceAll(RegExp(r'\s'), '');
      if (cleaned.length % 4 != 0) {
        cleaned = cleaned.padRight(cleaned.length + (4 - cleaned.length % 4), '=');
      }
      return base64Decode(cleaned);
    } catch (e) {
      print('Error decoding base64: $e');
      return Uint8List(0);
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  String _formatTimeAgo(DateTime date) {
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