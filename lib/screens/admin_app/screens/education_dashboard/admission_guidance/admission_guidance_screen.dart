// lib/screens/admin/education/admin_admissions_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminAdmissionsScreen extends StatefulWidget {
  @override
  _AdminAdmissionsScreenState createState() => _AdminAdmissionsScreenState();
}

class _AdminAdmissionsScreenState extends State<AdminAdmissionsScreen> with SingleTickerProviderStateMixin {
  final Color _primaryGreen = Color(0xFF4CAF50);
  final Color _darkGreen = Color(0xFF388E3C);
  
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
      _loadAdmissions();
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

  Future<void> _loadAdmissions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    final provider = Provider.of<EducationProvider>(context, listen: false);
    await provider.loadAdmissionsGuidance(adminView: true);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _permanentDeleteAdmissions(String id) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Permanent Delete'),
      content: const Text(
        'Are you sure you want to permanently delete this admissions guidance? This action cannot be undone.',
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
    final success = await provider.permanentDeleteAdmissionsGuidance(id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admissions guidance permanently deleted'),
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
                            'Manage Admissions Guidance',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 28 : (isSmallScreen ? 20 : 24),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            'Review, verify, and manage admissions consultants',
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
                                ? 'Search by consultant name, specialization, country...'
                                : 'Search consultants...',
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
                                  final count = provider.admissionsGuidance
                                      .where((a) => !a.isVerified && !a.isDeleted && a.isActive)
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
                                  final count = provider.admissionsGuidance
                                      .where((a) => a.isVerified && !a.isDeleted && a.isActive)
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
                                  final count = provider.admissionsGuidance
                                      .where((a) => a.isDeleted || !a.isActive)
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
            if (_isLoading && provider.admissionsGuidance.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: _primaryGreen),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildAdmissionsList(provider, 'pending'),
                _buildAdmissionsList(provider, 'active'),
                _buildAdmissionsList(provider, 'rejected'),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAdmissions,
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

  Widget _buildAdmissionsList(EducationProvider provider, String type) {
    List<AdmissionsGuidance> filteredList;
    
    switch (type) {
      case 'pending':
        filteredList = provider.admissionsGuidance
            .where((a) => !a.isVerified && !a.isDeleted && a.isActive)
            .toList();
        break;
      case 'active':
        filteredList = provider.admissionsGuidance
            .where((a) => a.isVerified && !a.isDeleted && a.isActive)
            .toList();
        break;
      case 'rejected':
        filteredList = provider.admissionsGuidance
            .where((a) => a.isDeleted || !a.isActive)
            .toList();
        break;
      default:
        filteredList = [];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((item) {
        return item.consultantName.toLowerCase().contains(_searchQuery) ||
               (item.organizationName?.toLowerCase().contains(_searchQuery) ?? false) ||
               item.email.toLowerCase().contains(_searchQuery) ||
               item.city.toLowerCase().contains(_searchQuery) ||
               item.state.toLowerCase().contains(_searchQuery) ||
               item.specializations.any((s) => s.toLowerCase().contains(_searchQuery)) ||
               item.countries.any((c) => c.toLowerCase().contains(_searchQuery)) ||
               item.description.toLowerCase().contains(_searchQuery);
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
        _searchQuery.isNotEmpty 
            ? 'No matching results found'
            : type == 'pending' 
                ? 'No pending admissions guidance' 
                : type == 'active' 
                    ? 'No active admissions guidance' 
                    : 'No rejected admissions guidance',
        _searchQuery.isNotEmpty ? Icons.search_off_rounded :
        type == 'pending' ? Icons.pending_actions_rounded :
        type == 'active' ? Icons.business_center_rounded : Icons.block_rounded,
        hasSearch: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdmissions,
      color: _primaryGreen,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          return _buildAdmissionsCard(filteredList[index], type);
        },
      ),
    );
  }

  Widget _buildAdmissionsCard(AdmissionsGuidance guidance, String type) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final imageBytes = guidance.profileImageBase64 != null && guidance.profileImageBase64!.isNotEmpty
        ? _base64ToImage(guidance.profileImageBase64!)
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
          border: guidance.rating >= 4.5 && type == 'active'
              ? Border.all(color: Colors.amber, width: 2)
              : null,
        ),
        child: InkWell(
          onTap: () => _showAdmissionsDetails(guidance, type),
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
                                    Icons.business_center_rounded,
                                    color: _getTypeColor(type),
                                    size: isSmallScreen ? 30 : 35,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.business_center_rounded,
                              color: _getTypeColor(type),
                              size: isSmallScreen ? 30 : 35,
                            ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    
                    // Consultant Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  guidance.consultantName,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (guidance.rating >= 4.5 && type == 'active')
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
                            guidance.organizationName ?? 'Independent Consultant',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: _primaryGreen,
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
                                guidance.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[800],
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '(${guidance.totalReviews} reviews)',
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
                      '${guidance.specializations.length} specializations',
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.public_rounded,
                      '${guidance.countries.length} countries',
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.attach_money_rounded,
                      guidance.formattedFee,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.location_on_rounded,
                      isSmallScreen ? guidance.city : '${guidance.city}, ${guidance.state}',
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
                            'Posted by: ${guidance.createdBy}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(guidance, type, isSmallScreen: isSmallScreen),
                  ],
                ),
                
                // Admin Actions based on type
                _buildActionButtons(guidance, type, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(AdmissionsGuidance guidance, String type, bool isSmallScreen) {
    if (type == 'pending') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVerificationDialog(guidance),
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
                  onPressed: () => _showRejectionDialog(guidance),
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
                  onPressed: () => _deactivateAdmissions(guidance),
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
                  onPressed: () => _deleteAdmissions(guidance),
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
                  onPressed: () => _restoreAdmissions(guidance),
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
                  onPressed: () => _permanentDeleteAdmissions(guidance.id!),
              
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

  Widget _buildStatusChip(AdmissionsGuidance guidance, String type, {required bool isSmallScreen}) {
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
        if (guidance.isDeleted) {
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

  void _showAdmissionsDetails(AdmissionsGuidance guidance, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AdminAdmissionsDetailsSheet(
        guidance: guidance,
        type: type,
        onStatusChanged: _loadAdmissions,
        primaryGreen: _primaryGreen,
      ),
    );
  }

  void _showVerificationDialog(AdmissionsGuidance guidance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Admissions Guidance'),
        content: Text('Are you sure you want to verify "${guidance.consultantName}"? This will make it visible to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyAdmissions(guidance);
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

  void _showRejectionDialog(AdmissionsGuidance guidance) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Admissions Guidance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${guidance.consultantName}"?'),
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
              _rejectAdmissions(guidance, reasonController.text);
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

  void _verifyAdmissions(AdmissionsGuidance guidance) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = AdmissionsGuidance(
      id: guidance.id,
      category: guidance.category,
      consultantName: guidance.consultantName,
      organizationName: guidance.organizationName,
      email: guidance.email,
      phone: guidance.phone,
      address: guidance.address,
      state: guidance.state,
      city: guidance.city,
      specializations: guidance.specializations,
      countries: guidance.countries,
      description: guidance.description,
      consultationFee: guidance.consultationFee,
      experience: guidance.experience,
      qualifications: guidance.qualifications,
      profileImageBase64: guidance.profileImageBase64,
      successStories: guidance.successStories,
      servicesOffered: guidance.servicesOffered,
      languagesSpoken: guidance.languagesSpoken,
      isVerified: true,
      isActive: true,
      isDeleted: false,
      rating: guidance.rating,
      totalReviews: guidance.totalReviews,
      totalLikes: guidance.totalLikes,
      likedByUsers: guidance.likedByUsers,
      createdBy: guidance.createdBy,
      createdAt: guidance.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?guidance.additionalInfo,
        'verifiedAt': DateTime.now().toIso8601String(),
        'verifiedBy': 'admin',
      },
      certifications: guidance.certifications,
      website: guidance.website,
      socialMediaLinks: guidance.socialMediaLinks,
      serviceAreas: guidance.serviceAreas,
    );

    final success = await provider.updateAdmissionsGuidance(guidance.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${guidance.consultantName} verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAdmissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify consultant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectAdmissions(AdmissionsGuidance guidance, String reason) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = AdmissionsGuidance(
      id: guidance.id,
      category: guidance.category,
      consultantName: guidance.consultantName,
      organizationName: guidance.organizationName,
      email: guidance.email,
      phone: guidance.phone,
      address: guidance.address,
      state: guidance.state,
      city: guidance.city,
      specializations: guidance.specializations,
      countries: guidance.countries,
      description: guidance.description,
      consultationFee: guidance.consultationFee,
      experience: guidance.experience,
      qualifications: guidance.qualifications,
      profileImageBase64: guidance.profileImageBase64,
      successStories: guidance.successStories,
      servicesOffered: guidance.servicesOffered,
      languagesSpoken: guidance.languagesSpoken,
      isVerified: false,
      isActive: false,
      isDeleted: true,
      rating: guidance.rating,
      totalReviews: guidance.totalReviews,
      totalLikes: guidance.totalLikes,
      likedByUsers: guidance.likedByUsers,
      createdBy: guidance.createdBy,
      createdAt: guidance.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?guidance.additionalInfo,
        'rejectionReason': reason,
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectedBy': 'admin',
      },
      certifications: guidance.certifications,
      website: guidance.website,
      socialMediaLinks: guidance.socialMediaLinks,
      serviceAreas: guidance.serviceAreas,
    );

    final success = await provider.updateAdmissionsGuidance(guidance.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${guidance.consultantName} rejected${reason.isNotEmpty ? ': $reason' : ''}'),
            backgroundColor: Colors.red,
          ),
        );
        _loadAdmissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject consultant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deactivateAdmissions(AdmissionsGuidance guidance) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = AdmissionsGuidance(
      id: guidance.id,
      category: guidance.category,
      consultantName: guidance.consultantName,
      organizationName: guidance.organizationName,
      email: guidance.email,
      phone: guidance.phone,
      address: guidance.address,
      state: guidance.state,
      city: guidance.city,
      specializations: guidance.specializations,
      countries: guidance.countries,
      description: guidance.description,
      consultationFee: guidance.consultationFee,
      experience: guidance.experience,
      qualifications: guidance.qualifications,
      profileImageBase64: guidance.profileImageBase64,
      successStories: guidance.successStories,
      servicesOffered: guidance.servicesOffered,
      languagesSpoken: guidance.languagesSpoken,
      isVerified: guidance.isVerified,
      isActive: false,
      isDeleted: false,
      rating: guidance.rating,
      totalReviews: guidance.totalReviews,
      totalLikes: guidance.totalLikes,
      likedByUsers: guidance.likedByUsers,
      createdBy: guidance.createdBy,
      createdAt: guidance.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?guidance.additionalInfo,
        'deactivatedAt': DateTime.now().toIso8601String(),
        'deactivatedBy': 'admin',
      },
      certifications: guidance.certifications,
      website: guidance.website,
      socialMediaLinks: guidance.socialMediaLinks,
      serviceAreas: guidance.serviceAreas,
    );

    final success = await provider.updateAdmissionsGuidance(guidance.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${guidance.consultantName} deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadAdmissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate consultant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteAdmissions(AdmissionsGuidance guidance) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = AdmissionsGuidance(
      id: guidance.id,
      category: guidance.category,
      consultantName: guidance.consultantName,
      organizationName: guidance.organizationName,
      email: guidance.email,
      phone: guidance.phone,
      address: guidance.address,
      state: guidance.state,
      city: guidance.city,
      specializations: guidance.specializations,
      countries: guidance.countries,
      description: guidance.description,
      consultationFee: guidance.consultationFee,
      experience: guidance.experience,
      qualifications: guidance.qualifications,
      profileImageBase64: guidance.profileImageBase64,
      successStories: guidance.successStories,
      servicesOffered: guidance.servicesOffered,
      languagesSpoken: guidance.languagesSpoken,
      isVerified: guidance.isVerified,
      isActive: false,
      isDeleted: true,
      rating: guidance.rating,
      totalReviews: guidance.totalReviews,
      totalLikes: guidance.totalLikes,
      likedByUsers: guidance.likedByUsers,
      createdBy: guidance.createdBy,
      createdAt: guidance.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?guidance.additionalInfo,
        'deletedAt': DateTime.now().toIso8601String(),
        'deletedBy': 'admin',
      },
      certifications: guidance.certifications,
      website: guidance.website,
      socialMediaLinks: guidance.socialMediaLinks,
      serviceAreas: guidance.serviceAreas,
    );

    final success = await provider.updateAdmissionsGuidance(guidance.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${guidance.consultantName} moved to rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _loadAdmissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete consultant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restoreAdmissions(AdmissionsGuidance guidance) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = AdmissionsGuidance(
      id: guidance.id,
      category: guidance.category,
      consultantName: guidance.consultantName,
      organizationName: guidance.organizationName,
      email: guidance.email,
      phone: guidance.phone,
      address: guidance.address,
      state: guidance.state,
      city: guidance.city,
      specializations: guidance.specializations,
      countries: guidance.countries,
      description: guidance.description,
      consultationFee: guidance.consultationFee,
      experience: guidance.experience,
      qualifications: guidance.qualifications,
      profileImageBase64: guidance.profileImageBase64,
      successStories: guidance.successStories,
      servicesOffered: guidance.servicesOffered,
      languagesSpoken: guidance.languagesSpoken,
      isVerified: false,
      isActive: true,
      isDeleted: false,
      rating: guidance.rating,
      totalReviews: guidance.totalReviews,
      totalLikes: guidance.totalLikes,
      likedByUsers: guidance.likedByUsers,
      createdBy: guidance.createdBy,
      createdAt: guidance.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?guidance.additionalInfo,
        'restoredAt': DateTime.now().toIso8601String(),
        'restoredBy': 'admin',
      },
      certifications: guidance.certifications,
      website: guidance.website,
      socialMediaLinks: guidance.socialMediaLinks,
      serviceAreas: guidance.serviceAreas,
    );

    final success = await provider.updateAdmissionsGuidance(guidance.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${guidance.consultantName} restored to pending'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAdmissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore consultant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

/*  void _permanentDeleteAdmissions(AdmissionsGuidance guidance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text(
          'Are you sure you want to permanently delete "${guidance.consultantName}"? '
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
    final success = await provider.permanentDeleteAdmissionsGuidance(guidance.id!);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consultant permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
        _loadAdmissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to permanently delete consultant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }  */
}

class AdminAdmissionsDetailsSheet extends StatelessWidget {
  final AdmissionsGuidance guidance;
  final String type;
  final VoidCallback onStatusChanged;
  final Color primaryGreen;

  const AdminAdmissionsDetailsSheet({
    Key? key,
    required this.guidance,
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
                        'Consultant Details',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
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
                            color: primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: guidance.profileImageBase64 != null && guidance.profileImageBase64!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _base64ToImage(guidance.profileImageBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.business_center_rounded,
                                        size: isTablet ? 50 : 40,
                                        color: primaryGreen,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.business_center_rounded,
                                  size: isTablet ? 50 : 40,
                                  color: primaryGreen,
                                ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        
                        // Consultant Name and Organization
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guidance.consultantName,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                guidance.organizationName ?? 'Independent Consultant',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildDetailStatusChip(isTablet: isTablet),
                                ],
                              ),
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
                          _buildStatItem(Icons.star_rounded, 'Rating', guidance.rating.toStringAsFixed(1), isTablet: isTablet),
                          _buildStatItem(Icons.reviews_rounded, 'Reviews', '${guidance.totalReviews}', isTablet: isTablet),
                          _buildStatItem(Icons.favorite_rounded, 'Likes', '${guidance.totalLikes}', isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 28 : 24),
                    
                    // Description
                    _buildSectionTitle('Description', Icons.description_rounded, Colors.blue, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        guidance.description,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Contact Information
                    _buildSectionTitle('Contact Information', Icons.contact_phone_rounded, primaryGreen, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildContactInfo(Icons.email_rounded, guidance.email, isLink: true, isTablet: isTablet),
                          const Divider(height: 16),
                          _buildContactInfo(Icons.phone_rounded, guidance.phone, isLink: true, isTablet: isTablet),
                          if (guidance.website != null && guidance.website!.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildContactInfo(Icons.language_rounded, guidance.website!, isLink: true, isTablet: isTablet),
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
                          Text(guidance.address, style: TextStyle(fontSize: isTablet ? 16 : 15)),
                          SizedBox(height: 4),
                          Text(
                            '${guidance.city}, ${guidance.state}',
                            style: TextStyle(fontSize: isTablet ? 16 : 15),
                          ),
                          if (guidance.serviceAreas.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              'Service Areas: ${guidance.serviceAreas.join(', ')}',
                              style: TextStyle(fontSize: isTablet ? 14 : 13, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Fee and Experience
                    _buildSectionTitle('Fee & Experience', Icons.attach_money_rounded, Colors.green, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow('Consultation Fee', guidance.formattedFee, isTablet: isTablet),
                          if (guidance.experience != null && guidance.experience!.isNotEmpty)
                            _buildInfoRow('Experience', guidance.experience!, isTablet: isTablet),
                          if (guidance.qualifications != null && guidance.qualifications!.isNotEmpty)
                            _buildInfoRow('Qualifications', guidance.qualifications!, isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    // Specializations
                    if (guidance.specializations.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Specializations', Icons.category_rounded, Colors.purple, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: guidance.specializations.map((spec) {
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
                                spec,
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
                    
                    // Countries Served
                    if (guidance.countries.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Countries Served', Icons.public_rounded, Colors.blue, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: guidance.countries.map((country) {
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
                                country,
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
                    
                    // Services Offered
                    if (guidance.servicesOffered.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Services Offered', Icons.checklist_rounded, Colors.green, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: guidance.servicesOffered.map((service) {
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
                                service,
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
                    
                    // Languages Spoken
                    if (guidance.languagesSpoken.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Languages Spoken', Icons.language_rounded, Colors.teal, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: guidance.languagesSpoken.map((language) {
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
                    
                    // Success Stories
                    if (guidance.successStories != null && guidance.successStories!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Success Stories', Icons.emoji_events_rounded, Colors.amber, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: guidance.successStories!.map((story) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.star_rounded, size: isTablet ? 16 : 14, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      story,
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
                    
                    // Certifications
                    if (guidance.certifications != null && guidance.certifications!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Certifications', Icons.verified_rounded, Colors.green, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: guidance.certifications!.map((cert) {
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
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Timestamps
                    _buildSectionTitle('Timestamps', Icons.access_time_rounded, Colors.grey, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow('Posted By', guidance.createdBy, isTablet: isTablet),
                          _buildInfoRow('Created', _formatDateTime(guidance.createdAt), isTablet: isTablet),
                          _buildInfoRow('Updated', _formatDateTime(guidance.updatedAt), isTablet: isTablet),
                          if (guidance.additionalInfo?['verifiedAt'] != null)
                            _buildInfoRow('Verified', _formatDateTime(DateTime.parse(guidance.additionalInfo!['verifiedAt'])), isTablet: isTablet),
                          if (guidance.additionalInfo?['rejectedAt'] != null)
                            _buildInfoRow('Rejected', _formatDateTime(DateTime.parse(guidance.additionalInfo!['rejectedAt'])), isTablet: isTablet),
                          if (guidance.additionalInfo?['deactivatedAt'] != null)
                            _buildInfoRow('Deactivated', _formatDateTime(DateTime.parse(guidance.additionalInfo!['deactivatedAt'])), isTablet: isTablet),
                          if (guidance.additionalInfo?['restoredAt'] != null)
                            _buildInfoRow('Restored', _formatDateTime(DateTime.parse(guidance.additionalInfo!['restoredAt'])), isTablet: isTablet),
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

    if (!guidance.isVerified && !guidance.isDeleted && guidance.isActive) {
      color = Colors.orange;
      text = 'Pending';
      icon = Icons.pending_rounded;
    } else if (guidance.isVerified && !guidance.isDeleted && guidance.isActive) {
      color = Colors.green;
      text = 'Verified';
      icon = Icons.verified_rounded;
    } else if (guidance.isDeleted) {
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

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }
}