// lib/screens/admin/education/admin_bangla_classes_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminBanglaClassesScreen extends StatefulWidget {
  @override
  _AdminBanglaClassesScreenState createState() => _AdminBanglaClassesScreenState();
}

class _AdminBanglaClassesScreenState extends State<AdminBanglaClassesScreen> with SingleTickerProviderStateMixin {
  final Color _primaryOrange = Color(0xFFFF9800);
  final Color _darkOrange = Color(0xFFF57C00);
  
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
      _loadBanglaClasses();
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

  Future<void> _loadBanglaClasses() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    final provider = Provider.of<EducationProvider>(context, listen: false);
    await provider.loadBanglaClasses(adminView: true);
    
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
              backgroundColor: _primaryOrange,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryOrange, _darkOrange],
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
                            'Manage Bangla Classes',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 28 : (isSmallScreen ? 20 : 24),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            'Review, verify, and manage Bangla language classes',
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
                  color: _primaryOrange,
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
                                ? 'Search by instructor, organization, location, class types...'
                                : 'Search classes...',
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
                                  final count = provider.banglaClasses
                                      .where((c) => !c.isVerified && !c.isDeleted && c.isActive)
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
                                  final count = provider.banglaClasses
                                      .where((c) => c.isVerified && !c.isDeleted && c.isActive)
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
                                  final count = provider.banglaClasses
                                      .where((c) => c.isDeleted || !c.isActive)
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
            if (_isLoading && provider.banglaClasses.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: _primaryOrange),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildBanglaClassesList(provider, 'pending'),
                _buildBanglaClassesList(provider, 'active'),
                _buildBanglaClassesList(provider, 'rejected'),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadBanglaClasses,
        backgroundColor: _primaryOrange,
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

  Widget _buildBanglaClassesList(EducationProvider provider, String type) {
    List<BanglaClass> filteredList;
    
    switch (type) {
      case 'pending':
        filteredList = provider.banglaClasses
            .where((c) => !c.isVerified && !c.isDeleted && c.isActive)
            .toList();
        break;
      case 'active':
        filteredList = provider.banglaClasses
            .where((c) => c.isVerified && !c.isDeleted && c.isActive)
            .toList();
        break;
      case 'rejected':
        filteredList = provider.banglaClasses
            .where((c) => c.isDeleted || !c.isActive)
            .toList();
        break;
      default:
        filteredList = [];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((item) {
        return item.instructorName.toLowerCase().contains(_searchQuery) ||
               (item.organizationName?.toLowerCase().contains(_searchQuery) ?? false) ||
               item.email.toLowerCase().contains(_searchQuery) ||
               item.city.toLowerCase().contains(_searchQuery) ||
               item.state.toLowerCase().contains(_searchQuery) ||
               item.classTypes.any((t) => t.toLowerCase().contains(_searchQuery)) ||
               item.description.toLowerCase().contains(_searchQuery) ||
               item.culturalActivities.any((a) => a.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    // Sort by date (newest first) and rating
    filteredList.sort((a, b) {
      if (a.rating != b.rating) {
        return b.rating.compareTo(a.rating);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    if (filteredList.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty ? 'No matching Bangla classes found' :
        type == 'pending' ? 'No pending Bangla classes' :
        type == 'active' ? 'No active Bangla classes' : 'No rejected Bangla classes',
        _searchQuery.isNotEmpty ? Icons.search_off_rounded :
        type == 'pending' ? Icons.pending_actions_rounded :
        type == 'active' ? Icons.language_rounded : Icons.block_rounded,
        hasSearch: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBanglaClasses,
      color: _primaryOrange,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          return _buildClassCard(filteredList[index], type);
        },
      ),
    );
  }

  Widget _buildClassCard(BanglaClass banglaClass, String type) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isFull = banglaClass.enrolledStudents >= banglaClass.maxStudents;
    final spotsLeft = banglaClass.maxStudents - banglaClass.enrolledStudents;
    final imageBytes = banglaClass.profileImageBase64 != null && banglaClass.profileImageBase64!.isNotEmpty
        ? _base64ToImage(banglaClass.profileImageBase64!)
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
          border: banglaClass.rating >= 4.5 && type == 'active'
              ? Border.all(color: Colors.amber, width: 2)
              : null,
        ),
        child: InkWell(
          onTap: () => _showClassDetails(banglaClass, type),
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
                                    Icons.language_rounded,
                                    color: _getTypeColor(type),
                                    size: isSmallScreen ? 30 : 35,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.language_rounded,
                              color: _getTypeColor(type),
                              size: isSmallScreen ? 30 : 35,
                            ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    
                    // Instructor Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  banglaClass.instructorName,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (banglaClass.rating >= 4.5 && type == 'active')
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'TOP',
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
                            banglaClass.organizationName ?? 'Independent Instructor',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: _primaryOrange,
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
                                banglaClass.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[800],
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '(${banglaClass.totalReviews})',
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
                      Icons.category_rounded,
                      '${banglaClass.classTypes.length} types',
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.attach_money_rounded,
                      banglaClass.formattedFee,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.access_time_rounded,
                      banglaClass.formattedDuration,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.location_on_rounded,
                      isSmallScreen ? banglaClass.city : '${banglaClass.city}, ${banglaClass.state}',
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 6 : 8),
                
                // Enrollment Status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFull 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFull ? Icons.event_busy_rounded : Icons.event_available_rounded,
                        size: isSmallScreen ? 12 : 14,
                        color: isFull ? Colors.red : Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        isFull ? 'Class Full' : '$spotsLeft spots left',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11,
                          color: isFull ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
                            'Posted by: ${banglaClass.createdBy}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(banglaClass, type, isSmallScreen: isSmallScreen),
                  ],
                ),
                
                // Admin Actions based on type
                _buildActionButtons(banglaClass, type, isFull, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BanglaClass banglaClass, String type, bool isFull, bool isSmallScreen) {
    if (type == 'pending') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVerificationDialog(banglaClass),
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
                  onPressed: () => _showRejectionDialog(banglaClass),
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
                  onPressed: () => _deactivateClass(banglaClass),
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
                  onPressed: () => _deleteClass(banglaClass),
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
          if (isFull) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: isSmallScreen ? 14 : 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Class is full. Consider increasing capacity.',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                  onPressed: () => _restoreClass(banglaClass),
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
              //    onPressed: () => _permanentDeleteClass(banglaClass),
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

  Widget _buildStatusChip(BanglaClass banglaClass, String type, {required bool isSmallScreen}) {
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
        if (banglaClass.isDeleted) {
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

  void _showClassDetails(BanglaClass banglaClass, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AdminBanglaClassDetailsSheet(
        banglaClass: banglaClass,
        type: type,
        onStatusChanged: _loadBanglaClasses,
        primaryOrange: _primaryOrange,
      ),
    );
  }

  void _showVerificationDialog(BanglaClass banglaClass) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Bangla Class'),
        content: Text('Are you sure you want to verify "${banglaClass.instructorName}"? This will make it visible to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyClass(banglaClass);
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

  void _showRejectionDialog(BanglaClass banglaClass) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Bangla Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${banglaClass.instructorName}"?'),
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
              _rejectClass(banglaClass, reasonController.text);
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

  void _verifyClass(BanglaClass banglaClass) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = BanglaClass(
      id: banglaClass.id,
      category: banglaClass.category,
      instructorName: banglaClass.instructorName,
      organizationName: banglaClass.organizationName,
      email: banglaClass.email,
      phone: banglaClass.phone,
      address: banglaClass.address,
      state: banglaClass.state,
      city: banglaClass.city,
      classTypes: banglaClass.classTypes,
      teachingMethods: banglaClass.teachingMethods,
      description: banglaClass.description,
      classFee: banglaClass.classFee,
      schedule: banglaClass.schedule,
      classDuration: banglaClass.classDuration,
      maxStudents: banglaClass.maxStudents,
      qualifications: banglaClass.qualifications,
      profileImageBase64: banglaClass.profileImageBase64,
      galleryImagesBase64: banglaClass.galleryImagesBase64,
      languagesSpoken: banglaClass.languagesSpoken,
      isVerified: true,
      isActive: true,
      isDeleted: false,
      rating: banglaClass.rating,
      totalReviews: banglaClass.totalReviews,
      totalLikes: banglaClass.totalLikes,
      likedByUsers: banglaClass.likedByUsers,
      enrolledStudents: banglaClass.enrolledStudents,
      createdBy: banglaClass.createdBy,
      createdAt: banglaClass.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?banglaClass.additionalInfo,
        'verifiedAt': DateTime.now().toIso8601String(),
        'verifiedBy': 'admin',
      },
      certifications: banglaClass.certifications,
      website: banglaClass.website,
      socialMediaLinks: banglaClass.socialMediaLinks,
      serviceAreas: banglaClass.serviceAreas,
      culturalActivities: banglaClass.culturalActivities,
    );

    final success = await provider.updateBanglaClass(banglaClass.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${banglaClass.instructorName} verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBanglaClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify class'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectClass(BanglaClass banglaClass, String reason) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = BanglaClass(
      id: banglaClass.id,
      category: banglaClass.category,
      instructorName: banglaClass.instructorName,
      organizationName: banglaClass.organizationName,
      email: banglaClass.email,
      phone: banglaClass.phone,
      address: banglaClass.address,
      state: banglaClass.state,
      city: banglaClass.city,
      classTypes: banglaClass.classTypes,
      teachingMethods: banglaClass.teachingMethods,
      description: banglaClass.description,
      classFee: banglaClass.classFee,
      schedule: banglaClass.schedule,
      classDuration: banglaClass.classDuration,
      maxStudents: banglaClass.maxStudents,
      qualifications: banglaClass.qualifications,
      profileImageBase64: banglaClass.profileImageBase64,
      galleryImagesBase64: banglaClass.galleryImagesBase64,
      languagesSpoken: banglaClass.languagesSpoken,
      isVerified: false,
      isActive: false,
      isDeleted: true,
      rating: banglaClass.rating,
      totalReviews: banglaClass.totalReviews,
      totalLikes: banglaClass.totalLikes,
      likedByUsers: banglaClass.likedByUsers,
      enrolledStudents: banglaClass.enrolledStudents,
      createdBy: banglaClass.createdBy,
      createdAt: banglaClass.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?banglaClass.additionalInfo,
        'rejectionReason': reason,
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectedBy': 'admin',
      },
      certifications: banglaClass.certifications,
      website: banglaClass.website,
      socialMediaLinks: banglaClass.socialMediaLinks,
      serviceAreas: banglaClass.serviceAreas,
      culturalActivities: banglaClass.culturalActivities,
    );

    final success = await provider.updateBanglaClass(banglaClass.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${banglaClass.instructorName} rejected${reason.isNotEmpty ? ': $reason' : ''}'),
            backgroundColor: Colors.red,
          ),
        );
        _loadBanglaClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject class'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deactivateClass(BanglaClass banglaClass) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = BanglaClass(
      id: banglaClass.id,
      category: banglaClass.category,
      instructorName: banglaClass.instructorName,
      organizationName: banglaClass.organizationName,
      email: banglaClass.email,
      phone: banglaClass.phone,
      address: banglaClass.address,
      state: banglaClass.state,
      city: banglaClass.city,
      classTypes: banglaClass.classTypes,
      teachingMethods: banglaClass.teachingMethods,
      description: banglaClass.description,
      classFee: banglaClass.classFee,
      schedule: banglaClass.schedule,
      classDuration: banglaClass.classDuration,
      maxStudents: banglaClass.maxStudents,
      qualifications: banglaClass.qualifications,
      profileImageBase64: banglaClass.profileImageBase64,
      galleryImagesBase64: banglaClass.galleryImagesBase64,
      languagesSpoken: banglaClass.languagesSpoken,
      isVerified: banglaClass.isVerified,
      isActive: false,
      isDeleted: false,
      rating: banglaClass.rating,
      totalReviews: banglaClass.totalReviews,
      totalLikes: banglaClass.totalLikes,
      likedByUsers: banglaClass.likedByUsers,
      enrolledStudents: banglaClass.enrolledStudents,
      createdBy: banglaClass.createdBy,
      createdAt: banglaClass.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?banglaClass.additionalInfo,
        'deactivatedAt': DateTime.now().toIso8601String(),
        'deactivatedBy': 'admin',
      },
      certifications: banglaClass.certifications,
      website: banglaClass.website,
      socialMediaLinks: banglaClass.socialMediaLinks,
      serviceAreas: banglaClass.serviceAreas,
      culturalActivities: banglaClass.culturalActivities,
    );

    final success = await provider.updateBanglaClass(banglaClass.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${banglaClass.instructorName} deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadBanglaClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate class'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteClass(BanglaClass banglaClass) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = BanglaClass(
      id: banglaClass.id,
      category: banglaClass.category,
      instructorName: banglaClass.instructorName,
      organizationName: banglaClass.organizationName,
      email: banglaClass.email,
      phone: banglaClass.phone,
      address: banglaClass.address,
      state: banglaClass.state,
      city: banglaClass.city,
      classTypes: banglaClass.classTypes,
      teachingMethods: banglaClass.teachingMethods,
      description: banglaClass.description,
      classFee: banglaClass.classFee,
      schedule: banglaClass.schedule,
      classDuration: banglaClass.classDuration,
      maxStudents: banglaClass.maxStudents,
      qualifications: banglaClass.qualifications,
      profileImageBase64: banglaClass.profileImageBase64,
      galleryImagesBase64: banglaClass.galleryImagesBase64,
      languagesSpoken: banglaClass.languagesSpoken,
      isVerified: banglaClass.isVerified,
      isActive: false,
      isDeleted: true,
      rating: banglaClass.rating,
      totalReviews: banglaClass.totalReviews,
      totalLikes: banglaClass.totalLikes,
      likedByUsers: banglaClass.likedByUsers,
      enrolledStudents: banglaClass.enrolledStudents,
      createdBy: banglaClass.createdBy,
      createdAt: banglaClass.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?banglaClass.additionalInfo,
        'deletedAt': DateTime.now().toIso8601String(),
        'deletedBy': 'admin',
      },
      certifications: banglaClass.certifications,
      website: banglaClass.website,
      socialMediaLinks: banglaClass.socialMediaLinks,
      serviceAreas: banglaClass.serviceAreas,
      culturalActivities: banglaClass.culturalActivities,
    );

    final success = await provider.updateBanglaClass(banglaClass.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${banglaClass.instructorName} moved to rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _loadBanglaClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete class'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restoreClass(BanglaClass banglaClass) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = BanglaClass(
      id: banglaClass.id,
      category: banglaClass.category,
      instructorName: banglaClass.instructorName,
      organizationName: banglaClass.organizationName,
      email: banglaClass.email,
      phone: banglaClass.phone,
      address: banglaClass.address,
      state: banglaClass.state,
      city: banglaClass.city,
      classTypes: banglaClass.classTypes,
      teachingMethods: banglaClass.teachingMethods,
      description: banglaClass.description,
      classFee: banglaClass.classFee,
      schedule: banglaClass.schedule,
      classDuration: banglaClass.classDuration,
      maxStudents: banglaClass.maxStudents,
      qualifications: banglaClass.qualifications,
      profileImageBase64: banglaClass.profileImageBase64,
      galleryImagesBase64: banglaClass.galleryImagesBase64,
      languagesSpoken: banglaClass.languagesSpoken,
      isVerified: false,
      isActive: true,
      isDeleted: false,
      rating: banglaClass.rating,
      totalReviews: banglaClass.totalReviews,
      totalLikes: banglaClass.totalLikes,
      likedByUsers: banglaClass.likedByUsers,
      enrolledStudents: banglaClass.enrolledStudents,
      createdBy: banglaClass.createdBy,
      createdAt: banglaClass.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?banglaClass.additionalInfo,
        'restoredAt': DateTime.now().toIso8601String(),
        'restoredBy': 'admin',
      },
      certifications: banglaClass.certifications,
      website: banglaClass.website,
      socialMediaLinks: banglaClass.socialMediaLinks,
      serviceAreas: banglaClass.serviceAreas,
      culturalActivities: banglaClass.culturalActivities,
    );

    final success = await provider.updateBanglaClass(banglaClass.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${banglaClass.instructorName} restored to pending'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBanglaClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore class'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

 /* void _permanentDeleteClass(BanglaClass banglaClass) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text(
          'Are you sure you want to permanently delete the class taught by "${banglaClass.instructorName}"? '
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
    final success = await provider.permanentDeleteBanglaClass(banglaClass.id!);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
        _loadBanglaClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to permanently delete class'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }  */
}

class AdminBanglaClassDetailsSheet extends StatelessWidget {
  final BanglaClass banglaClass;
  final String type;
  final VoidCallback onStatusChanged;
  final Color primaryOrange;

  const AdminBanglaClassDetailsSheet({
    Key? key,
    required this.banglaClass,
    required this.type,
    required this.onStatusChanged,
    required this.primaryOrange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width >= 600;
    final isFull = banglaClass.enrolledStudents >= banglaClass.maxStudents;
    final spotsLeft = banglaClass.maxStudents - banglaClass.enrolledStudents;
    
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
                        'Class Details',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w600,
                          color: primaryOrange,
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
                            color: primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: banglaClass.profileImageBase64 != null && banglaClass.profileImageBase64!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _base64ToImage(banglaClass.profileImageBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.language_rounded,
                                        size: isTablet ? 50 : 40,
                                        color: primaryOrange,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.language_rounded,
                                  size: isTablet ? 50 : 40,
                                  color: primaryOrange,
                                ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        
                        // Instructor Name and Organization
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                banglaClass.instructorName,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                banglaClass.organizationName ?? 'Independent Instructor',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  color: primaryOrange,
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
                          _buildStatItem(Icons.star_rounded, 'Rating', banglaClass.rating.toStringAsFixed(1), isTablet: isTablet),
                          _buildStatItem(Icons.reviews_rounded, 'Reviews', '${banglaClass.totalReviews}', isTablet: isTablet),
                          _buildStatItem(Icons.favorite_rounded, 'Likes', '${banglaClass.totalLikes}', isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 28 : 24),
                    
                    // Description
                    _buildSectionTitle('Description', Icons.description_rounded, Colors.blue, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        banglaClass.description,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Contact Information
                    _buildSectionTitle('Contact Information', Icons.contact_phone_rounded, primaryOrange, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildContactInfo(Icons.email_rounded, banglaClass.email, isLink: true, isTablet: isTablet),
                          const Divider(height: 16),
                          _buildContactInfo(Icons.phone_rounded, banglaClass.phone, isLink: true, isTablet: isTablet),
                          if (banglaClass.website != null && banglaClass.website!.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildContactInfo(Icons.language_rounded, banglaClass.website!, isLink: true, isTablet: isTablet),
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
                          Text(banglaClass.address, style: TextStyle(fontSize: isTablet ? 16 : 15)),
                          SizedBox(height: 4),
                          Text(
                            '${banglaClass.city}, ${banglaClass.state}',
                            style: TextStyle(fontSize: isTablet ? 16 : 15),
                          ),
                          if (banglaClass.serviceAreas.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              'Service Areas: ${banglaClass.serviceAreas.join(', ')}',
                              style: TextStyle(fontSize: isTablet ? 14 : 13, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Class Details
                    _buildSectionTitle('Class Details', Icons.class_rounded, primaryOrange, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow('Class Fee', banglaClass.formattedFee, isTablet: isTablet),
                          _buildInfoRow('Duration', banglaClass.formattedDuration, isTablet: isTablet),
                          _buildInfoRow('Schedule', banglaClass.schedule ?? 'Flexible', isTablet: isTablet),
                          _buildInfoRow('Max Students', banglaClass.maxStudents.toString(), isTablet: isTablet),
                          _buildInfoRow('Enrolled', banglaClass.enrolledStudents.toString(), isTablet: isTablet),
                          _buildInfoRow('Availability', banglaClass.availabilityStatus, isTablet: isTablet),
                          if (banglaClass.qualifications != null && banglaClass.qualifications!.isNotEmpty)
                            _buildInfoRow('Qualifications', banglaClass.qualifications!, isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    // Class Types
                    if (banglaClass.classTypes.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Class Types', Icons.category_rounded, Colors.purple, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: banglaClass.classTypes.map((type) {
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
                                type,
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
                    
                    // Teaching Methods
                    if (banglaClass.teachingMethods.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Teaching Methods', Icons.school_rounded, Colors.blue, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: banglaClass.teachingMethods.map((method) {
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
                                method.displayName,
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
                    
                    // Languages Spoken
                    if (banglaClass.languagesSpoken.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Languages Spoken', Icons.language_rounded, Colors.teal, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: banglaClass.languagesSpoken.map((language) {
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
                    
                    // Cultural Activities
                    if (banglaClass.culturalActivities.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Cultural Activities', Icons.festival_rounded, Colors.amber, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: banglaClass.culturalActivities.map((activity) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12, 
                                vertical: isTablet ? 8 : 6
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                activity,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 13,
                                  color: Colors.amber[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Certifications
                    if (banglaClass.certifications != null && banglaClass.certifications!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Certifications', Icons.verified_rounded, Colors.green, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: banglaClass.certifications!.map((cert) {
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
                    
                    // Gallery Images
                    if (banglaClass.galleryImagesBase64 != null && banglaClass.galleryImagesBase64!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Gallery', Icons.image_rounded, Colors.purple, isTablet: isTablet),
                      SizedBox(height: 8),
                      SizedBox(
                        height: isTablet ? 120 : 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: banglaClass.galleryImagesBase64!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: isTablet ? 120 : 100,
                              height: isTablet ? 120 : 100,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: MemoryImage(
                                    _base64ToImage(banglaClass.galleryImagesBase64![index]),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    
                    // Enrollment Status Alert
                    if (isFull) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      Container(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red, size: isTablet ? 24 : 20),
                            SizedBox(width: isTablet ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Class is Full',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[800],
                                      fontSize: isTablet ? 16 : 14,
                                    ),
                                  ),
                                  Text(
                                    'Maximum capacity of ${banglaClass.maxStudents} students reached.',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: isTablet ? 14 : 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (spotsLeft <= 5) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      Container(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_rounded, color: Colors.orange, size: isTablet ? 24 : 20),
                            SizedBox(width: isTablet ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Limited Spots Available',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[800],
                                      fontSize: isTablet ? 16 : 14,
                                    ),
                                  ),
                                  Text(
                                    'Only $spotsLeft spots left out of ${banglaClass.maxStudents}.',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: isTablet ? 14 : 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                          _buildInfoRow('Posted By', banglaClass.createdBy, isTablet: isTablet),
                          _buildInfoRow('Created', _formatDateTime(banglaClass.createdAt), isTablet: isTablet),
                          _buildInfoRow('Updated', _formatDateTime(banglaClass.updatedAt), isTablet: isTablet),
                          if (banglaClass.additionalInfo?['verifiedAt'] != null)
                            _buildInfoRow('Verified', _formatDateTime(DateTime.parse(banglaClass.additionalInfo!['verifiedAt'])), isTablet: isTablet),
                          if (banglaClass.additionalInfo?['rejectedAt'] != null)
                            _buildInfoRow('Rejected', _formatDateTime(DateTime.parse(banglaClass.additionalInfo!['rejectedAt'])), isTablet: isTablet),
                          if (banglaClass.additionalInfo?['deactivatedAt'] != null)
                            _buildInfoRow('Deactivated', _formatDateTime(DateTime.parse(banglaClass.additionalInfo!['deactivatedAt'])), isTablet: isTablet),
                          if (banglaClass.additionalInfo?['restoredAt'] != null)
                            _buildInfoRow('Restored', _formatDateTime(DateTime.parse(banglaClass.additionalInfo!['restoredAt'])), isTablet: isTablet),
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

    if (!banglaClass.isVerified && !banglaClass.isDeleted && banglaClass.isActive) {
      color = Colors.orange;
      text = 'Pending';
      icon = Icons.pending_rounded;
    } else if (banglaClass.isVerified && !banglaClass.isDeleted && banglaClass.isActive) {
      color = Colors.green;
      text = 'Verified';
      icon = Icons.verified_rounded;
    } else if (banglaClass.isDeleted) {
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
        Icon(icon, color: primaryOrange, size: isTablet ? 26 : 22),
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
            width: isTablet ? 120 : 100,
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
              style: TextStyle(fontSize: isTablet ? 15 : 14, color: Colors.grey[800]),
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
                color: isLink ? primaryOrange : Colors.grey[800],
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