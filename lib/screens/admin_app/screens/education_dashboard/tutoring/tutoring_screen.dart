// lib/screens/admin/education/admin_tutoring_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminTutoringScreen extends StatefulWidget {
  @override
  _AdminTutoringScreenState createState() => _AdminTutoringScreenState();
}

class _AdminTutoringScreenState extends State<AdminTutoringScreen> with SingleTickerProviderStateMixin {
  final Color _primaryBlue = Color(0xFF2196F3);
  final Color _darkBlue = Color(0xFF1976D2);
  
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
      _loadTutoringServices();
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

  Future<void> _loadTutoringServices() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    final provider = Provider.of<EducationProvider>(context, listen: false);
    await provider.loadTutoringServices(adminView: true);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // In _AdminTutoringScreenState
Future<void> _permanentDeleteTutoring(String id) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Permanent Delete'),
      content: const Text(
        'Are you sure you want to permanently delete this tutoring service? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete Permanently'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final provider = Provider.of<EducationProvider>(context, listen: false);
    final success = await provider.permanentDeleteTutoringService(id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tutoring service permanently deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 20, 
                        vertical: isTablet ? 30 : 20
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Tutoring Services',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 28 : (isSmallScreen ? 20 : 24),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            'Review, verify, and manage tutoring listings',
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
                  color: _primaryBlue,
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
                                ? 'Search by tutor name, subject, location...'
                                : 'Search tutors...',
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
                      
                      // Tab Bar with Count Badges
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
                              child: Consumer<EducationProvider>(
                                builder: (context, provider, child) {
                                  final count = provider.tutoringServices
                                      .where((s) => !s.isVerified && !s.isDeleted && s.isActive)
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
                              child: Consumer<EducationProvider>(
                                builder: (context, provider, child) {
                                  final count = provider.tutoringServices
                                      .where((s) => s.isVerified && !s.isDeleted && s.isActive)
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
                              child: Consumer<EducationProvider>(
                                builder: (context, provider, child) {
                                  final count = provider.tutoringServices
                                      .where((s) => s.isDeleted || !s.isActive)
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
        body: Consumer<EducationProvider>(
          builder: (context, provider, child) {
            if (_isLoading && provider.tutoringServices.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: _primaryBlue),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildTutoringList(provider, 'pending'),
                _buildTutoringList(provider, 'active'),
                _buildTutoringList(provider, 'rejected'),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTutoringServices,
        backgroundColor: _primaryBlue,
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

  Widget _buildTutoringList(EducationProvider provider, String type) {
    List<TutoringService> filteredServices;
    
    switch (type) {
      case 'pending':
        filteredServices = provider.tutoringServices
            .where((s) => !s.isVerified && !s.isDeleted && s.isActive)
            .toList();
        break;
      case 'active':
        filteredServices = provider.tutoringServices
            .where((s) => s.isVerified && !s.isDeleted && s.isActive)
            .toList();
        break;
      case 'rejected':
        filteredServices = provider.tutoringServices
            .where((s) => s.isDeleted || !s.isActive)
            .toList();
        break;
      default:
        filteredServices = [];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredServices = filteredServices.where((service) {
        return service.tutorName.toLowerCase().contains(_searchQuery) ||
               (service.organizationName?.toLowerCase().contains(_searchQuery) ?? false) ||
               service.email.toLowerCase().contains(_searchQuery) ||
               service.city.toLowerCase().contains(_searchQuery) ||
               service.state.toLowerCase().contains(_searchQuery) ||
               service.subjects.any((s) => s.displayName.toLowerCase().contains(_searchQuery)) ||
               service.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Sort by date (newest first) and rating
    filteredServices.sort((a, b) {
      if (a.rating != b.rating) {
        return b.rating.compareTo(a.rating);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    if (filteredServices.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty ? 'No matching tutoring services found' :
        type == 'pending' ? 'No pending tutoring services' :
        type == 'active' ? 'No active tutoring services' : 'No rejected tutoring services',
        _searchQuery.isNotEmpty ? Icons.search_off_rounded :
        type == 'pending' ? Icons.pending_actions_rounded :
        type == 'active' ? Icons.school_rounded : Icons.block_rounded,
        hasSearch: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTutoringServices,
      color: _primaryBlue,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredServices.length,
        itemBuilder: (context, index) {
          return _buildTutoringCard(filteredServices[index], type);
        },
      ),
    );
  }

  Widget _buildTutoringCard(TutoringService service, String type) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final imageBytes = service.profileImageBase64 != null && service.profileImageBase64!.isNotEmpty
        ? _base64ToImage(service.profileImageBase64!)
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: service.rating >= 4.5 && type == 'active'
              ? Border.all(color: Colors.amber, width: 2)
              : null,
        ),
        child: InkWell(
          onTap: () => _showTutoringDetails(service, type),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image
                    Container(
                      width: isSmallScreen ? 60 : 70,
                      height: isSmallScreen ? 60 : 70,
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
                                    Icons.school_rounded,
                                    color: _getTypeColor(type),
                                    size: isSmallScreen ? 30 : 35,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.school_rounded,
                              color: _getTypeColor(type),
                              size: isSmallScreen ? 30 : 35,
                            ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    
                    // Tutor Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service.tutorName,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (service.rating >= 4.5 && type == 'active')
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'TOP RATED',
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
                            service.organizationName ?? 'Independent Tutor',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: _primaryBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: isSmallScreen ? 12 : 14, color: Colors.amber),
                              SizedBox(width: 2),
                              Text(
                                service.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[800],
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 8),
                              Text(
                                '${service.totalReviews} reviews',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
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
                      Icons.subject_rounded,
                      '${service.subjects.length} subjects',
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.location_on_rounded,
                      isSmallScreen ? service.city : '${service.city}, ${service.state}',
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.attach_money_rounded,
                      service.formattedRate,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.school_rounded,
                      service.levels.map((l) => l.displayName).join(', '),
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 6 : 8),
                
                // Posted By and Status Row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_rounded, size: isSmallScreen ? 10 : 12, color: Colors.blue[700]),
                          SizedBox(width: 4),
                          Text(
                            'Posted by: ${service.createdBy}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(service, type, isSmallScreen: isSmallScreen),
                  ],
                ),
                
                // Admin Actions based on type
                _buildActionButtons(service, type, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(TutoringService service, String type, bool isSmallScreen) {
    if (type == 'pending') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVerificationDialog(service),
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
                  onPressed: () => _showRejectionDialog(service),
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
                  onPressed: () => _deactivateTutoring(service),
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
                  onPressed: () => _deleteTutoring(service),
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
                  onPressed: () => _restoreTutoring(service),
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
                  onPressed: () => _permanentDeleteTutoring(service.id!),
                
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
          Icon(icon, size: isSmallScreen ? 10 : 12, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: isSmallScreen ? 9 : 11, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TutoringService service, String type, {required bool isSmallScreen}) {
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
        color = Colors.green;
        text = 'Verified';
        icon = Icons.verified_rounded;
        break;
      case 'rejected':
        if (service.isDeleted) {
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
          Icon(icon, size: isSmallScreen ? 10 : 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isSmallScreen ? 9 : 11,
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

  void _showTutoringDetails(TutoringService service, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AdminTutoringDetailsSheet(
        service: service,
        type: type,
        onStatusChanged: _loadTutoringServices,
        primaryBlue: _primaryBlue,
      ),
    );
  }

  void _showVerificationDialog(TutoringService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Tutoring Service'),
        content: Text('Are you sure you want to verify "${service.tutorName}"? This will make it visible to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyTutoring(service);
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

  void _showRejectionDialog(TutoringService service) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Tutoring Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${service.tutorName}"?'),
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
              _rejectTutoring(service, reasonController.text);
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

  void _verifyTutoring(TutoringService service) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updatedService = TutoringService(
      id: service.id,
      category: service.category,
      tutorName: service.tutorName,
      organizationName: service.organizationName,
      email: service.email,
      phone: service.phone,
      address: service.address,
      state: service.state,
      city: service.city,
      subjects: service.subjects,
      levels: service.levels,
      teachingMethods: service.teachingMethods,
      description: service.description,
      hourlyRate: service.hourlyRate,
      experience: service.experience,
      qualifications: service.qualifications,
      profileImageBase64: service.profileImageBase64,
      galleryImagesBase64: service.galleryImagesBase64,
      availableDays: service.availableDays,
      availableTimes: service.availableTimes,
      languagesSpoken: service.languagesSpoken,
      isVerified: true,
      isActive: true,
      isDeleted: false,
      rating: service.rating,
      totalReviews: service.totalReviews,
      totalLikes: service.totalLikes,
      likedByUsers: service.likedByUsers,
      createdBy: service.createdBy,
      createdAt: service.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?service.additionalInfo,
        'verifiedAt': DateTime.now().toIso8601String(),
        'verifiedBy': 'admin',
      },
      certifications: service.certifications,
      website: service.website,
      socialMediaLinks: service.socialMediaLinks,
      serviceAreas: service.serviceAreas,
    );

    final success = await provider.updateTutoringService(service.id!, updatedService);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${service.tutorName} verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTutoringServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify tutoring service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectTutoring(TutoringService service, String reason) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updatedService = TutoringService(
      id: service.id,
      category: service.category,
      tutorName: service.tutorName,
      organizationName: service.organizationName,
      email: service.email,
      phone: service.phone,
      address: service.address,
      state: service.state,
      city: service.city,
      subjects: service.subjects,
      levels: service.levels,
      teachingMethods: service.teachingMethods,
      description: service.description,
      hourlyRate: service.hourlyRate,
      experience: service.experience,
      qualifications: service.qualifications,
      profileImageBase64: service.profileImageBase64,
      galleryImagesBase64: service.galleryImagesBase64,
      availableDays: service.availableDays,
      availableTimes: service.availableTimes,
      languagesSpoken: service.languagesSpoken,
      isVerified: false,
      isActive: false,
      isDeleted: true,
      rating: service.rating,
      totalReviews: service.totalReviews,
      totalLikes: service.totalLikes,
      likedByUsers: service.likedByUsers,
      createdBy: service.createdBy,
      createdAt: service.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?service.additionalInfo,
        'rejectionReason': reason,
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectedBy': 'admin',
      },
      certifications: service.certifications,
      website: service.website,
      socialMediaLinks: service.socialMediaLinks,
      serviceAreas: service.serviceAreas,
    );

    final success = await provider.updateTutoringService(service.id!, updatedService);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${service.tutorName} rejected${reason.isNotEmpty ? ': $reason' : ''}'),
            backgroundColor: Colors.red,
          ),
        );
        _loadTutoringServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject tutoring service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deactivateTutoring(TutoringService service) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updatedService = TutoringService(
      id: service.id,
      category: service.category,
      tutorName: service.tutorName,
      organizationName: service.organizationName,
      email: service.email,
      phone: service.phone,
      address: service.address,
      state: service.state,
      city: service.city,
      subjects: service.subjects,
      levels: service.levels,
      teachingMethods: service.teachingMethods,
      description: service.description,
      hourlyRate: service.hourlyRate,
      experience: service.experience,
      qualifications: service.qualifications,
      profileImageBase64: service.profileImageBase64,
      galleryImagesBase64: service.galleryImagesBase64,
      availableDays: service.availableDays,
      availableTimes: service.availableTimes,
      languagesSpoken: service.languagesSpoken,
      isVerified: service.isVerified,
      isActive: false,
      isDeleted: false,
      rating: service.rating,
      totalReviews: service.totalReviews,
      totalLikes: service.totalLikes,
      likedByUsers: service.likedByUsers,
      createdBy: service.createdBy,
      createdAt: service.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?service.additionalInfo,
        'deactivatedAt': DateTime.now().toIso8601String(),
        'deactivatedBy': 'admin',
      },
      certifications: service.certifications,
      website: service.website,
      socialMediaLinks: service.socialMediaLinks,
      serviceAreas: service.serviceAreas,
    );

    final success = await provider.updateTutoringService(service.id!, updatedService);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${service.tutorName} deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadTutoringServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate tutoring service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteTutoring(TutoringService service) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updatedService = TutoringService(
      id: service.id,
      category: service.category,
      tutorName: service.tutorName,
      organizationName: service.organizationName,
      email: service.email,
      phone: service.phone,
      address: service.address,
      state: service.state,
      city: service.city,
      subjects: service.subjects,
      levels: service.levels,
      teachingMethods: service.teachingMethods,
      description: service.description,
      hourlyRate: service.hourlyRate,
      experience: service.experience,
      qualifications: service.qualifications,
      profileImageBase64: service.profileImageBase64,
      galleryImagesBase64: service.galleryImagesBase64,
      availableDays: service.availableDays,
      availableTimes: service.availableTimes,
      languagesSpoken: service.languagesSpoken,
      isVerified: service.isVerified,
      isActive: false,
      isDeleted: true,
      rating: service.rating,
      totalReviews: service.totalReviews,
      totalLikes: service.totalLikes,
      likedByUsers: service.likedByUsers,
      createdBy: service.createdBy,
      createdAt: service.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?service.additionalInfo,
        'deletedAt': DateTime.now().toIso8601String(),
        'deletedBy': 'admin',
      },
      certifications: service.certifications,
      website: service.website,
      socialMediaLinks: service.socialMediaLinks,
      serviceAreas: service.serviceAreas,
    );

    final success = await provider.updateTutoringService(service.id!, updatedService);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${service.tutorName} moved to rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _loadTutoringServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete tutoring service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restoreTutoring(TutoringService service) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updatedService = TutoringService(
      id: service.id,
      category: service.category,
      tutorName: service.tutorName,
      organizationName: service.organizationName,
      email: service.email,
      phone: service.phone,
      address: service.address,
      state: service.state,
      city: service.city,
      subjects: service.subjects,
      levels: service.levels,
      teachingMethods: service.teachingMethods,
      description: service.description,
      hourlyRate: service.hourlyRate,
      experience: service.experience,
      qualifications: service.qualifications,
      profileImageBase64: service.profileImageBase64,
      galleryImagesBase64: service.galleryImagesBase64,
      availableDays: service.availableDays,
      availableTimes: service.availableTimes,
      languagesSpoken: service.languagesSpoken,
      isVerified: false,
      isActive: true,
      isDeleted: false,
      rating: service.rating,
      totalReviews: service.totalReviews,
      totalLikes: service.totalLikes,
      likedByUsers: service.likedByUsers,
      createdBy: service.createdBy,
      createdAt: service.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?service.additionalInfo,
        'restoredAt': DateTime.now().toIso8601String(),
        'restoredBy': 'admin',
      },
      certifications: service.certifications,
      website: service.website,
      socialMediaLinks: service.socialMediaLinks,
      serviceAreas: service.serviceAreas,
    );

    final success = await provider.updateTutoringService(service.id!, updatedService);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${service.tutorName} restored to pending'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTutoringServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore tutoring service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

 /* void _permanentDeleteTutoring(TutoringService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text(
          'Are you sure you want to permanently delete "${service.tutorName}"? '
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

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    // Implement permanent delete method in your provider
    final success = await provider.permanentDeleteTutoringService(service.id!);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tutoring service permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
        _loadTutoringServices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to permanently delete tutoring service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }  */
}

class AdminTutoringDetailsSheet extends StatelessWidget {
  final TutoringService service;
  final String type;
  final VoidCallback onStatusChanged;
  final Color primaryBlue;

  const AdminTutoringDetailsSheet({
    Key? key,
    required this.service,
    required this.type,
    required this.onStatusChanged,
    required this.primaryBlue,
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
                        'Tutor Details',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1, thickness: 1),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  children: [
                    // Header with profile info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Image
                        Container(
                          width: isTablet ? 100 : 80,
                          height: isTablet ? 100 : 80,
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: service.profileImageBase64 != null && service.profileImageBase64!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _base64ToImage(service.profileImageBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.school_rounded,
                                        size: isTablet ? 50 : 40,
                                        color: primaryBlue,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.school_rounded,
                                  size: isTablet ? 50 : 40,
                                  color: primaryBlue,
                                ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        
                        // Tutor Name and Organization
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.tutorName,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                service.organizationName ?? 'Independent Tutor',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildDetailStatusChip(isTablet: isTablet),
                            ],
                          ),
                        ),
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
                          _buildStatItem(Icons.star_rounded, 'Rating', service.rating.toStringAsFixed(1), isTablet: isTablet),
                          _buildStatItem(Icons.reviews_rounded, 'Reviews', '${service.totalReviews}', isTablet: isTablet),
                          _buildStatItem(Icons.favorite_rounded, 'Likes', '${service.totalLikes}', isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 28 : 24),
                    
                    // Description
                    _buildSectionTitle('Description', Icons.description_rounded, Colors.blue, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        service.description,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Contact Information
                    _buildSectionTitle('Contact Information', Icons.contact_phone_rounded, primaryBlue, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildContactInfo(Icons.email_rounded, service.email, isLink: true, isTablet: isTablet),
                          const Divider(height: 16),
                          _buildContactInfo(Icons.phone_rounded, service.phone, isLink: true, isTablet: isTablet),
                          if (service.website != null && service.website!.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildContactInfo(Icons.language_rounded, service.website!, isLink: true, isTablet: isTablet),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Location
                    _buildSectionTitle('Location', Icons.location_on_rounded, Colors.red, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.address, style: TextStyle(fontSize: isTablet ? 16 : 15)),
                          SizedBox(height: 4),
                          Text(
                            '${service.city}, ${service.state}',
                            style: TextStyle(fontSize: isTablet ? 16 : 15),
                          ),
                          if (service.serviceAreas.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              'Service Areas: ${service.serviceAreas.join(', ')}',
                              style: TextStyle(fontSize: isTablet ? 14 : 13, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Rate and Experience
                    _buildSectionTitle('Rate & Experience', Icons.attach_money_rounded, Colors.green, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow('Hourly Rate', service.formattedRate, isTablet: isTablet),
                          if (service.experience != null && service.experience!.isNotEmpty)
                            _buildInfoRow('Experience', service.experience!, isTablet: isTablet),
                          if (service.qualifications != null && service.qualifications!.isNotEmpty)
                            _buildInfoRow('Qualifications', service.qualifications!, isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    // Subjects
                    if (service.subjects.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Subjects', Icons.subject_rounded, Colors.purple, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: service.subjects.map((subject) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12, 
                                vertical: isTablet ? 8 : 6
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                subject.displayName,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: Colors.purple[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Education Levels
                    if (service.levels.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Education Levels', Icons.school_rounded, Colors.green, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: service.levels.map((level) {
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
                                level.displayName,
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
                    
                    // Teaching Methods
                    if (service.teachingMethods.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Teaching Methods', Icons.school_rounded, Colors.orange, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: service.teachingMethods.map((method) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12, 
                                vertical: isTablet ? 8 : 6
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                method.displayName,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: Colors.orange[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Languages Spoken
                    if (service.languagesSpoken.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Languages Spoken', Icons.language_rounded, Colors.teal, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: service.languagesSpoken.map((language) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12, 
                                vertical: isTablet ? 8 : 6
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                language,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: Colors.teal[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Certifications
                    if (service.certifications != null && service.certifications!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Certifications', Icons.verified_rounded, Colors.green, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: service.certifications!.map((cert) {
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
                                cert,
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
                    
                    // Availability
                    if (service.availableDays.isNotEmpty || service.availableTimes.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Availability', Icons.schedule_rounded, Colors.blue, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (service.availableDays.isNotEmpty)
                              Text(
                                'Days: ${service.availableDays.join(', ')}',
                                style: TextStyle(fontSize: isTablet ? 15 : 14),
                              ),
                            if (service.availableTimes.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                'Times: ${service.availableTimes.join(', ')}',
                                style: TextStyle(fontSize: isTablet ? 15 : 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    
                    // Gallery Images
                    if (service.galleryImagesBase64 != null && service.galleryImagesBase64!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Gallery', Icons.image_rounded, Colors.purple, isTablet: isTablet),
                      SizedBox(height: 8),
                      SizedBox(
                        height: isTablet ? 120 : 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: service.galleryImagesBase64!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: isTablet ? 120 : 100,
                              height: isTablet ? 120 : 100,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: MemoryImage(
                                    _base64ToImage(service.galleryImagesBase64![index]),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Timestamps
                    _buildSectionTitle('Timestamps', Icons.access_time_rounded, Colors.grey, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow('Posted By', service.createdBy, isTablet: isTablet),
                          _buildInfoRow('Created', _formatDateTime(service.createdAt), isTablet: isTablet),
                          _buildInfoRow('Updated', _formatDateTime(service.updatedAt), isTablet: isTablet),
                          if (service.additionalInfo?['verifiedAt'] != null)
                            _buildInfoRow('Verified', _formatDateTime(DateTime.parse(service.additionalInfo!['verifiedAt'])), isTablet: isTablet),
                          if (service.additionalInfo?['rejectedAt'] != null)
                            _buildInfoRow('Rejected', _formatDateTime(DateTime.parse(service.additionalInfo!['rejectedAt'])), isTablet: isTablet),
                          if (service.additionalInfo?['deactivatedAt'] != null)
                            _buildInfoRow('Deactivated', _formatDateTime(DateTime.parse(service.additionalInfo!['deactivatedAt'])), isTablet: isTablet),
                          if (service.additionalInfo?['restoredAt'] != null)
                            _buildInfoRow('Restored', _formatDateTime(DateTime.parse(service.additionalInfo!['restoredAt'])), isTablet: isTablet),
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
                // Trigger rejection from parent
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
                // Trigger verification from parent
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
                // Trigger deactivation from parent
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
                // Trigger deletion from parent
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
                // Trigger restore from parent
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
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDetailStatusChip({required bool isTablet}) {
    Color color;
    String text;
    IconData icon;

    if (!service.isVerified && !service.isDeleted && service.isActive) {
      color = Colors.orange;
      text = 'Pending';
      icon = Icons.pending_rounded;
    } else if (service.isVerified && !service.isDeleted && service.isActive) {
      color = Colors.green;
      text = 'Verified';
      icon = Icons.verified_rounded;
    } else if (service.isDeleted) {
      color = Colors.red;
      text = 'Deleted';
      icon = Icons.delete_rounded;
    } else {
      color = Colors.grey;
      text = 'Inactive';
      icon = Icons.block_rounded;
    }

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
          Icon(icon, size: isTablet ? 16 : 14, color: color),
          SizedBox(width: isTablet ? 6 : 4),
          Text(
            text,
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
        Icon(icon, color: primaryBlue, size: isTablet ? 26 : 22),
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

  Widget _buildInfoRow(String label, String value, {required bool isTablet}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 110 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: isTablet ? 14 : 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 15 : 14, 
                color: Colors.grey[800]
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String value, {bool isLink = false, required bool isTablet}) {
    return InkWell(
      onTap: isLink ? () => _launchUrl(value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: isTablet ? 20 : 18, color: Colors.grey[600]),
          SizedBox(width: isTablet ? 14 : 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: isLink ? primaryBlue : Colors.grey[800],
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

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }
}