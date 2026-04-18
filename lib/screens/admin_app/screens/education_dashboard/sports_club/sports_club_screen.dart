// lib/screens/admin/education/admin_sports_clubs_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:bangla_hub/models/education_models.dart';
import 'package:bangla_hub/providers/education_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminSportsClubsScreen extends StatefulWidget {
  @override
  _AdminSportsClubsScreenState createState() => _AdminSportsClubsScreenState();
}

class _AdminSportsClubsScreenState extends State<AdminSportsClubsScreen> with SingleTickerProviderStateMixin {
  final Color _primaryRed = Color(0xFFF44336);
  final Color _darkRed = Color(0xFFD32F2F);
  
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
      _loadSportsClubs();
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

  Future<void> _loadSportsClubs() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    final provider = Provider.of<EducationProvider>(context, listen: false);
    await provider.loadSportsClubs(adminView: true);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

  }

  Future<void> _permanentDeleteClub(String id) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Permanent Delete'),
      content: const Text(
        'Are you sure you want to permanently delete this sports club? This action cannot be undone.',
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
    final success = await provider.permanentDeleteSportsClub(id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sports club permanently deleted'),
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
              backgroundColor: _primaryRed,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryRed, _darkRed],
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
                            'Manage Sports Clubs',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 28 : (isSmallScreen ? 20 : 24),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            'Review, verify, and manage sports clubs',
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
                  color: _primaryRed,
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
                                ? 'Search by club name, sport, coach, location...'
                                : 'Search clubs...',
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
                                  final count = provider.sportsClubs
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
                                  final count = provider.sportsClubs
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
                                  final count = provider.sportsClubs
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
            if (_isLoading && provider.sportsClubs.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: _primaryRed),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildSportsClubsList(provider, 'pending'),
                _buildSportsClubsList(provider, 'active'),
                _buildSportsClubsList(provider, 'rejected'),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSportsClubs,
        backgroundColor: _primaryRed,
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

  Widget _buildSportsClubsList(EducationProvider provider, String type) {
    List<SportsClub> filteredList;
    
    switch (type) {
      case 'pending':
        filteredList = provider.sportsClubs
            .where((c) => !c.isVerified && !c.isDeleted && c.isActive)
            .toList();
        break;
      case 'active':
        filteredList = provider.sportsClubs
            .where((c) => c.isVerified && !c.isDeleted && c.isActive)
            .toList();
        break;
      case 'rejected':
        filteredList = provider.sportsClubs
            .where((c) => c.isDeleted || !c.isActive)
            .toList();
        break;
      default:
        filteredList = [];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((club) {
        return club.clubName.toLowerCase().contains(_searchQuery) ||
               club.sportType.displayName.toLowerCase().contains(_searchQuery) ||
               (club.coachName?.toLowerCase().contains(_searchQuery) ?? false) ||
               club.email.toLowerCase().contains(_searchQuery) ||
               club.city.toLowerCase().contains(_searchQuery) ||
               club.state.toLowerCase().contains(_searchQuery) ||
               club.venue.toLowerCase().contains(_searchQuery) ||
               club.description.toLowerCase().contains(_searchQuery) ||
               club.ageGroups.any((a) => a.toLowerCase().contains(_searchQuery)) ||
               club.skillLevels.any((s) => s.toLowerCase().contains(_searchQuery));
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
        _searchQuery.isNotEmpty ? 'No matching sports clubs found' :
        type == 'pending' ? 'No pending sports clubs' :
        type == 'active' ? 'No active sports clubs' : 'No rejected sports clubs',
        _searchQuery.isNotEmpty ? Icons.search_off_rounded :
        type == 'pending' ? Icons.pending_actions_rounded :
        type == 'active' ? Icons.sports_rounded : Icons.block_rounded,
        hasSearch: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSportsClubs,
      color: _primaryRed,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          return _buildClubCard(filteredList[index], type);
        },
      ),
    );
  }

  Widget _buildClubCard(SportsClub club, String type) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isFull = club.currentMembers >= club.maxMembers;
    final spotsLeft = club.maxMembers - club.currentMembers;
    final imageBytes = club.logoImageBase64 != null && club.logoImageBase64!.isNotEmpty
        ? _base64ToImage(club.logoImageBase64!)
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
          border: club.rating >= 4.5 && type == 'active'
              ? Border.all(color: Colors.amber, width: 2)
              : null,
        ),
        child: InkWell(
          onTap: () => _showClubDetails(club, type),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
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
                                    Icons.sports_rounded,
                                    color: _getTypeColor(type),
                                    size: isSmallScreen ? 30 : 35,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.sports_rounded,
                              color: _getTypeColor(type),
                              size: isSmallScreen ? 30 : 35,
                            ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    
                    // Club Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  club.clubName,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (club.rating >= 4.5 && type == 'active')
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
                            club.sportType.displayName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: _primaryRed,
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
                                club.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[800],
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 8),
                              Text(
                                '${club.totalReviews} reviews',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9 : 11,
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
                      Icons.attach_money_rounded,
                      club.formattedFee,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.people_rounded,
                      '${club.currentMembers}/${club.maxMembers}',
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.location_on_rounded,
                      isSmallScreen ? club.city : '${club.city}, ${club.state}',
                      isSmallScreen: isSmallScreen,
                    ),
                    if (club.coachName != null && club.coachName!.isNotEmpty)
                      _buildInfoChip(
                        Icons.person_rounded,
                        club.coachName!,
                        isSmallScreen: isSmallScreen,
                      ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 6 : 8),
                
                // Membership Status and Posted By
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFull 
                            ? Colors.red.withOpacity(0.1)
                            : spotsLeft <= 5
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFull ? Icons.event_busy_rounded : Icons.event_available_rounded,
                            size: isSmallScreen ? 12 : 14,
                            color: isFull ? Colors.red : spotsLeft <= 5 ? Colors.orange : Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isFull ? 'Full' : '$spotsLeft spots',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 11,
                              color: isFull ? Colors.red : spotsLeft <= 5 ? Colors.orange : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
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
                            'Posted by: ${club.createdBy}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 10,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    _buildStatusChip(club, type, isSmallScreen: isSmallScreen),
                  ],
                ),
                
                // Admin Actions based on type
                _buildActionButtons(club, type, isSmallScreen, isFull, spotsLeft),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(SportsClub club, String type, bool isSmallScreen, bool isFull, int spotsLeft) {
    if (type == 'pending') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVerificationDialog(club),
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
                  onPressed: () => _showRejectionDialog(club),
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
                  onPressed: () => _deactivateClub(club),
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
                  onPressed: () => _deleteClub(club),
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
                      'Club is at full capacity.',
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
                  onPressed: () => _restoreClub(club),
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
                  onPressed: () => _permanentDeleteClub(club.id!),
                
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

  Widget _buildStatusChip(SportsClub club, String type, {required bool isSmallScreen}) {
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
        if (club.isDeleted) {
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

  void _showClubDetails(SportsClub club, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AdminSportsClubDetailsSheet(
        club: club,
        type: type,
        onStatusChanged: _loadSportsClubs,
        primaryRed: _primaryRed,
      ),
    );
  }

  void _showVerificationDialog(SportsClub club) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Sports Club'),
        content: Text('Are you sure you want to verify "${club.clubName}"? This will make it visible to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyClub(club);
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

  void _showRejectionDialog(SportsClub club) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Sports Club'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${club.clubName}"?'),
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
              _rejectClub(club, reasonController.text);
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

  void _verifyClub(SportsClub club) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = SportsClub(
      id: club.id,
      category: club.category,
      clubName: club.clubName,
      sportType: club.sportType,
      coachName: club.coachName,
      email: club.email,
      phone: club.phone,
      address: club.address,
      state: club.state,
      city: club.city,
      venue: club.venue,
      description: club.description,
      ageGroups: club.ageGroups,
      skillLevels: club.skillLevels,
      membershipFee: club.membershipFee,
      schedule: club.schedule,
      equipmentProvided: club.equipmentProvided,
      coachQualifications: club.coachQualifications,
      logoImageBase64: club.logoImageBase64,
      galleryImagesBase64: club.galleryImagesBase64,
      amenities: club.amenities,
      isVerified: true,
      isActive: true,
      isDeleted: false,
      rating: club.rating,
      totalReviews: club.totalReviews,
      totalLikes: club.totalLikes,
      likedByUsers: club.likedByUsers,
      currentMembers: club.currentMembers,
      maxMembers: club.maxMembers,
      createdBy: club.createdBy,
      createdAt: club.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?club.additionalInfo,
        'verifiedAt': DateTime.now().toIso8601String(),
        'verifiedBy': 'admin',
      },
      achievements: club.achievements,
      website: club.website,
      socialMediaLinks: club.socialMediaLinks,
      tournaments: club.tournaments,
    );

    final success = await provider.updateSportsClub(club.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${club.clubName} verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSportsClubs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify club'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectClub(SportsClub club, String reason) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = SportsClub(
      id: club.id,
      category: club.category,
      clubName: club.clubName,
      sportType: club.sportType,
      coachName: club.coachName,
      email: club.email,
      phone: club.phone,
      address: club.address,
      state: club.state,
      city: club.city,
      venue: club.venue,
      description: club.description,
      ageGroups: club.ageGroups,
      skillLevels: club.skillLevels,
      membershipFee: club.membershipFee,
      schedule: club.schedule,
      equipmentProvided: club.equipmentProvided,
      coachQualifications: club.coachQualifications,
      logoImageBase64: club.logoImageBase64,
      galleryImagesBase64: club.galleryImagesBase64,
      amenities: club.amenities,
      isVerified: false,
      isActive: false,
      isDeleted: true,
      rating: club.rating,
      totalReviews: club.totalReviews,
      totalLikes: club.totalLikes,
      likedByUsers: club.likedByUsers,
      currentMembers: club.currentMembers,
      maxMembers: club.maxMembers,
      createdBy: club.createdBy,
      createdAt: club.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?club.additionalInfo,
        'rejectionReason': reason,
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectedBy': 'admin',
      },
      achievements: club.achievements,
      website: club.website,
      socialMediaLinks: club.socialMediaLinks,
      tournaments: club.tournaments,
    );

    final success = await provider.updateSportsClub(club.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${club.clubName} rejected${reason.isNotEmpty ? ': $reason' : ''}'),
            backgroundColor: Colors.red,
          ),
        );
        _loadSportsClubs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject club'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deactivateClub(SportsClub club) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = SportsClub(
      id: club.id,
      category: club.category,
      clubName: club.clubName,
      sportType: club.sportType,
      coachName: club.coachName,
      email: club.email,
      phone: club.phone,
      address: club.address,
      state: club.state,
      city: club.city,
      venue: club.venue,
      description: club.description,
      ageGroups: club.ageGroups,
      skillLevels: club.skillLevels,
      membershipFee: club.membershipFee,
      schedule: club.schedule,
      equipmentProvided: club.equipmentProvided,
      coachQualifications: club.coachQualifications,
      logoImageBase64: club.logoImageBase64,
      galleryImagesBase64: club.galleryImagesBase64,
      amenities: club.amenities,
      isVerified: club.isVerified,
      isActive: false,
      isDeleted: false,
      rating: club.rating,
      totalReviews: club.totalReviews,
      totalLikes: club.totalLikes,
      likedByUsers: club.likedByUsers,
      currentMembers: club.currentMembers,
      maxMembers: club.maxMembers,
      createdBy: club.createdBy,
      createdAt: club.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?club.additionalInfo,
        'deactivatedAt': DateTime.now().toIso8601String(),
        'deactivatedBy': 'admin',
      },
      achievements: club.achievements,
      website: club.website,
      socialMediaLinks: club.socialMediaLinks,
      tournaments: club.tournaments,
    );

    final success = await provider.updateSportsClub(club.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${club.clubName} deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadSportsClubs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate club'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteClub(SportsClub club) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = SportsClub(
      id: club.id,
      category: club.category,
      clubName: club.clubName,
      sportType: club.sportType,
      coachName: club.coachName,
      email: club.email,
      phone: club.phone,
      address: club.address,
      state: club.state,
      city: club.city,
      venue: club.venue,
      description: club.description,
      ageGroups: club.ageGroups,
      skillLevels: club.skillLevels,
      membershipFee: club.membershipFee,
      schedule: club.schedule,
      equipmentProvided: club.equipmentProvided,
      coachQualifications: club.coachQualifications,
      logoImageBase64: club.logoImageBase64,
      galleryImagesBase64: club.galleryImagesBase64,
      amenities: club.amenities,
      isVerified: club.isVerified,
      isActive: false,
      isDeleted: true,
      rating: club.rating,
      totalReviews: club.totalReviews,
      totalLikes: club.totalLikes,
      likedByUsers: club.likedByUsers,
      currentMembers: club.currentMembers,
      maxMembers: club.maxMembers,
      createdBy: club.createdBy,
      createdAt: club.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?club.additionalInfo,
        'deletedAt': DateTime.now().toIso8601String(),
        'deletedBy': 'admin',
      },
      achievements: club.achievements,
      website: club.website,
      socialMediaLinks: club.socialMediaLinks,
      tournaments: club.tournaments,
    );

    final success = await provider.updateSportsClub(club.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${club.clubName} moved to rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _loadSportsClubs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete club'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restoreClub(SportsClub club) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EducationProvider>(context, listen: false);
    
    final updated = SportsClub(
      id: club.id,
      category: club.category,
      clubName: club.clubName,
      sportType: club.sportType,
      coachName: club.coachName,
      email: club.email,
      phone: club.phone,
      address: club.address,
      state: club.state,
      city: club.city,
      venue: club.venue,
      description: club.description,
      ageGroups: club.ageGroups,
      skillLevels: club.skillLevels,
      membershipFee: club.membershipFee,
      schedule: club.schedule,
      equipmentProvided: club.equipmentProvided,
      coachQualifications: club.coachQualifications,
      logoImageBase64: club.logoImageBase64,
      galleryImagesBase64: club.galleryImagesBase64,
      amenities: club.amenities,
      isVerified: false,
      isActive: true,
      isDeleted: false,
      rating: club.rating,
      totalReviews: club.totalReviews,
      totalLikes: club.totalLikes,
      likedByUsers: club.likedByUsers,
      currentMembers: club.currentMembers,
      maxMembers: club.maxMembers,
      createdBy: club.createdBy,
      createdAt: club.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?club.additionalInfo,
        'restoredAt': DateTime.now().toIso8601String(),
        'restoredBy': 'admin',
      },
      achievements: club.achievements,
      website: club.website,
      socialMediaLinks: club.socialMediaLinks,
      tournaments: club.tournaments,
    );

    final success = await provider.updateSportsClub(club.id!, updated);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${club.clubName} restored to pending'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSportsClubs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore club'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

/*  void _permanentDeleteClub(SportsClub club) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text(
          'Are you sure you want to permanently delete "${club.clubName}"? '
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
    final success = await provider.permanentDeleteSportsClub(club.id!);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Club permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
        _loadSportsClubs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to permanently delete club'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }  */
}

class AdminSportsClubDetailsSheet extends StatelessWidget {
  final SportsClub club;
  final String type;
  final VoidCallback onStatusChanged;
  final Color primaryRed;

  const AdminSportsClubDetailsSheet({
    Key? key,
    required this.club,
    required this.type,
    required this.onStatusChanged,
    required this.primaryRed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width >= 600;
    final isFull = club.currentMembers >= club.maxMembers;
    final spotsLeft = club.maxMembers - club.currentMembers;
    
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
                        'Club Details',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.w600,
                          color: primaryRed,
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
                    // Header with logo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Container(
                          width: isTablet ? 100 : 80,
                          height: isTablet ? 100 : 80,
                          decoration: BoxDecoration(
                            color: primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: club.logoImageBase64 != null && club.logoImageBase64!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _base64ToImage(club.logoImageBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.sports_rounded,
                                        size: isTablet ? 50 : 40,
                                        color: primaryRed,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.sports_rounded,
                                  size: isTablet ? 50 : 40,
                                  color: primaryRed,
                                ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        
                        // Club Name and Sport
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                club.clubName,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                club.sportType.displayName,
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  color: primaryRed,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildDetailStatusChip(isTablet: isTablet),
                                  if (club.rating >= 4.5)
                                    _buildTopRatedChip(isTablet: isTablet),
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
                          _buildStatItem(Icons.star_rounded, 'Rating', club.rating.toStringAsFixed(1), isTablet: isTablet),
                          _buildStatItem(Icons.reviews_rounded, 'Reviews', '${club.totalReviews}', isTablet: isTablet),
                          _buildStatItem(Icons.favorite_rounded, 'Likes', '${club.totalLikes}', isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 28 : 24),
                    
                    // Description
                    _buildSectionTitle('Description', Icons.description_rounded, Colors.blue, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        club.description,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Contact Information
                    _buildSectionTitle('Contact Information', Icons.contact_phone_rounded, primaryRed, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildContactInfo(Icons.email_rounded, club.email, isLink: true, isTablet: isTablet),
                          const Divider(height: 16),
                          _buildContactInfo(Icons.phone_rounded, club.phone, isLink: true, isTablet: isTablet),
                          if (club.website != null && club.website!.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildContactInfo(Icons.language_rounded, club.website!, isLink: true, isTablet: isTablet),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Location & Venue
                    _buildSectionTitle('Location & Venue', Icons.location_on_rounded, Colors.red, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Venue: ${club.venue}', style: TextStyle(fontSize: isTablet ? 16 : 15)),
                          SizedBox(height: 4),
                          Text(club.address, style: TextStyle(fontSize: isTablet ? 16 : 15)),
                          SizedBox(height: 4),
                          Text('${club.city}, ${club.state}', style: TextStyle(fontSize: isTablet ? 16 : 15)),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Club Details
                    _buildSectionTitle('Club Details', Icons.info_rounded, primaryRed, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          if (club.coachName != null && club.coachName!.isNotEmpty)
                            _buildInfoRow('Coach', club.coachName!, isTablet: isTablet),
                          _buildInfoRow('Membership Fee', club.formattedFee, isTablet: isTablet),
                          _buildInfoRow('Members', '${club.currentMembers}/${club.maxMembers}', isTablet: isTablet),
                          _buildInfoRow('Schedule', club.schedule ?? 'Flexible', isTablet: isTablet),
                          if (club.coachQualifications != null && club.coachQualifications!.isNotEmpty)
                            _buildInfoRow('Coach Qualifications', club.coachQualifications!, isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    // Age Groups
                    if (club.ageGroups.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Age Groups', Icons.people_rounded, Colors.orange, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: club.ageGroups.map((ageGroup) {
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
                                ageGroup,
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
                    
                    // Skill Levels
                    if (club.skillLevels.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Skill Levels', Icons.trending_up_rounded, Colors.blue, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: club.skillLevels.map((level) {
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
                                level,
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
                    
                    // Equipment Provided
                    if (club.equipmentProvided.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Equipment Provided', Icons.sports_tennis_rounded, Colors.purple, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: club.equipmentProvided.map((equipment) {
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
                                equipment,
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
                    
                    // Amenities
                    if (club.amenities.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Amenities', Icons.room_service_rounded, Colors.teal, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: club.amenities.map((amenity) {
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
                                amenity,
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
                    
                    // Tournaments
                    if (club.tournaments.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Tournaments', Icons.emoji_events_rounded, Colors.amber, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: club.tournaments.map((tournament) {
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
                                tournament,
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
                    
                    // Achievements
                    if (club.achievements != null && club.achievements!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Achievements', Icons.emoji_events_rounded, Colors.green, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: club.achievements!.map((achievement) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.emoji_events_rounded, size: isTablet ? 16 : 14, color: Colors.green),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      achievement,
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
                    
                    // Gallery Images
                    if (club.galleryImagesBase64 != null && club.galleryImagesBase64!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Gallery', Icons.image_rounded, Colors.purple, isTablet: isTablet),
                      SizedBox(height: 8),
                      SizedBox(
                        height: isTablet ? 120 : 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: club.galleryImagesBase64!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: isTablet ? 120 : 100,
                              height: isTablet ? 120 : 100,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: MemoryImage(
                                    _base64ToImage(club.galleryImagesBase64![index]),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    
                    // Membership Status Alert
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
                                    'Club is Full',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[800],
                                      fontSize: isTablet ? 16 : 14,
                                    ),
                                  ),
                                  Text(
                                    'Maximum capacity of ${club.maxMembers} members reached.',
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
                                    'Only $spotsLeft spots left out of ${club.maxMembers}.',
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
                          _buildInfoRow('Posted By', club.createdBy, isTablet: isTablet),
                          _buildInfoRow('Created', _formatDateTime(club.createdAt), isTablet: isTablet),
                          _buildInfoRow('Updated', _formatDateTime(club.updatedAt), isTablet: isTablet),
                          if (club.additionalInfo?['verifiedAt'] != null)
                            _buildInfoRow('Verified', _formatDateTime(DateTime.parse(club.additionalInfo!['verifiedAt'])), isTablet: isTablet),
                          if (club.additionalInfo?['rejectedAt'] != null)
                            _buildInfoRow('Rejected', _formatDateTime(DateTime.parse(club.additionalInfo!['rejectedAt'])), isTablet: isTablet),
                          if (club.additionalInfo?['deactivatedAt'] != null)
                            _buildInfoRow('Deactivated', _formatDateTime(DateTime.parse(club.additionalInfo!['deactivatedAt'])), isTablet: isTablet),
                          if (club.additionalInfo?['restoredAt'] != null)
                            _buildInfoRow('Restored', _formatDateTime(DateTime.parse(club.additionalInfo!['restoredAt'])), isTablet: isTablet),
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

    if (!club.isVerified && !club.isDeleted && club.isActive) {
      color = Colors.orange;
      text = 'Pending';
      icon = Icons.pending_rounded;
    } else if (club.isVerified && !club.isDeleted && club.isActive) {
      color = Colors.green;
      text = 'Verified';
      icon = Icons.verified_rounded;
    } else if (club.isDeleted) {
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

  Widget _buildTopRatedChip({required bool isTablet}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12, 
        vertical: isTablet ? 8 : 6
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: isTablet ? 16 : 14, color: Colors.amber),
          SizedBox(width: isTablet ? 6 : 4),
          Text(
            'Top Rated',
            style: TextStyle(
              color: Colors.amber,
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
        Icon(icon, color: primaryRed, size: isTablet ? 26 : 22),
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
            width: isTablet ? 140 : 120,
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
                color: isLink ? primaryRed : Colors.grey[800],
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