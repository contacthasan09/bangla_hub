// lib/screens/admin/entrepreneurship/admin_networking_partners_screen.dart

import 'dart:typed_data';
import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class AdminNetworkingPartnersScreen extends StatefulWidget {
  @override
  _AdminNetworkingPartnersScreenState createState() => _AdminNetworkingPartnersScreenState();
}

class _AdminNetworkingPartnersScreenState extends State<AdminNetworkingPartnersScreen> with SingleTickerProviderStateMixin {
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
      _loadPartners();
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

  Future<void> _loadPartners() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    await provider.loadBusinessPartners(adminView: true);
    
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
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: isSmallScreen ? 180 : (isTablet ? 220 : 200),
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
                        padding: EdgeInsets.only(
                          left: isTablet ? 32 : 20,
                          right: isTablet ? 32 : 20,
                          top: isTablet ? 30 : 20,
                          bottom: 10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Business Partners',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 28 : (isSmallScreen ? 20 : 24),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            Text(
                              'Review, verify, and manage business partner listings',
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
                  preferredSize: Size.fromHeight(isTablet ? 120 : 100),
                  child: Container(
                    color: _primaryGreen,
                    child: Column(
                      children: [
                        // Search Bar - Separated from TabBar
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
                                  ? 'Search by business name, owner, industry, location...'
                                  : 'Search partners...',
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
                                    final count = provider.businessPartners
                                        .where((p) => !p.isVerified && !p.isDeleted && p.isActive)
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
                                    final count = provider.businessPartners
                                        .where((p) => p.isVerified && !p.isDeleted && p.isActive)
                                        .length;
                                    return _buildTabContent(
                                      icon: Icons.check_circle_rounded,
                                      label: 'Verified',
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
                                    final count = provider.businessPartners
                                        .where((p) => p.isDeleted || !p.isActive)
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
              if (_isLoading && provider.businessPartners.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: _primaryGreen),
                );
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildPartnerList(provider, 'pending'),
                  _buildPartnerList(provider, 'verified'),
                  _buildPartnerList(provider, 'rejected'),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPartners,
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

  Widget _buildPartnerList(EntrepreneurshipProvider provider, String type) {
    List<NetworkingBusinessPartner> filteredPartners;
    
    switch (type) {
      case 'pending':
        filteredPartners = provider.businessPartners
            .where((p) => !p.isVerified && !p.isDeleted && p.isActive)
            .toList();
        break;
      case 'verified':
        filteredPartners = provider.businessPartners
            .where((p) => p.isVerified && !p.isDeleted && p.isActive)
            .toList();
        break;
      case 'rejected':
        filteredPartners = provider.businessPartners
            .where((p) => p.isDeleted || !p.isActive)
            .toList();
        break;
      default:
        filteredPartners = [];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredPartners = filteredPartners.where((partner) {
        return partner.businessName.toLowerCase().contains(_searchQuery) ||
               partner.ownerName.toLowerCase().contains(_searchQuery) ||
               partner.industry.toLowerCase().contains(_searchQuery) ||
               partner.city.toLowerCase().contains(_searchQuery) ||
               partner.state.toLowerCase().contains(_searchQuery) ||
               (partner.email?.toLowerCase().contains(_searchQuery) ?? false) ||
               (partner.phone?.contains(_searchQuery) ?? false);
      }).toList();
    }

    // Sort by date (newest first)
    filteredPartners.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (filteredPartners.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty 
            ? 'No matching results found'
            : type == 'pending' 
                ? 'No pending business partners' 
                : type == 'verified' 
                    ? 'No verified business partners' 
                    : 'No rejected business partners',
        type == 'pending' ? Icons.pending_actions_rounded :
        type == 'verified' ? Icons.check_circle_rounded : Icons.block_rounded,
        hasSearch: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPartners,
      color: _primaryGreen,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredPartners.length,
        itemBuilder: (context, index) {
          return _buildPartnerCard(filteredPartners[index], type);
        },
      ),
    );
  }

  Widget _buildPartnerCard(NetworkingBusinessPartner partner, String type) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showPartnerDetails(partner, type),
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
                    child: partner.logoImageBase64 != null && partner.logoImageBase64!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _base64ToImage(partner.logoImageBase64!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.broken_image_rounded,
                                  color: _getTypeColor(type),
                                  size: 30,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.store_rounded,
                            color: _getTypeColor(type),
                            size: isSmallScreen ? 30 : 35,
                          ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  
                  // Business Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.businessName,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          partner.ownerName,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: _primaryGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          partner.industry,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
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
              
              // Info Chips - Wrap for responsive
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildInfoChip(
                    Icons.location_on_rounded, 
                    isSmallScreen ? partner.city : '${partner.city}, ${partner.state}',
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildInfoChip(
                    Icons.star_rounded, 
                    partner.rating.toStringAsFixed(1),
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildInfoChip(
                    Icons.favorite_rounded, 
                    '${partner.totalLikes} likes',
                    isSmallScreen: isSmallScreen,
                  ),
                  _buildInfoChip(
                    Icons.reviews_rounded, 
                    '${partner.totalReviews} reviews',
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
              
              SizedBox(height: isSmallScreen ? 6 : 8),
              
              // Posted By and Status Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_rounded, size: 12, color: Colors.blue[700]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Posted by: ${partner.createdBy}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  _buildStatusChip(partner, type),
                ],
              ),
              
              // Admin Actions based on type
              _buildActionButtons(partner, type, isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(NetworkingBusinessPartner partner, String type, bool isSmallScreen) {
    if (type == 'pending') {
      return Column(
        children: [
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVerificationDialog(partner),
                  icon: Icon(Icons.check_circle_rounded, size: isSmallScreen ? 16 : 18),
                  label: Text(
                    'Verify',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
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
                  onPressed: () => _showRejectionDialog(partner),
                  icon: Icon(Icons.block_rounded, size: isSmallScreen ? 16 : 18),
                  label: Text(
                    'Reject',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
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
    } else if (type == 'verified') {
      return Column(
        children: [
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deactivatePartner(partner),
                  icon: Icon(Icons.pause_circle_rounded, size: isSmallScreen ? 16 : 18),
                  label: Text(
                    'Deactivate',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
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
                  onPressed: () => _deletePartner(partner),
                  icon: Icon(Icons.delete_rounded, size: isSmallScreen ? 16 : 18),
                  label: Text(
                    'Delete',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
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
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _restorePartner(partner),
                  icon: Icon(Icons.restore_rounded, size: isSmallScreen ? 16 : 18),
                  label: Text(
                    'Restore',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
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
               //   onPressed: () => _permanentDeletePartner(partner),
               onPressed: () {
                 
               },
                  icon: Icon(Icons.delete_forever_rounded, size: isSmallScreen ? 16 : 18),
                  label: Text(
                    'Delete\nPermanently',
                    style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
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

  Widget _buildStatusChip(NetworkingBusinessPartner partner, String type) {
    Color color;
    String text;
    IconData icon;

    switch (type) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        icon = Icons.pending_rounded;
        break;
      case 'verified':
        color = Colors.green;
        text = 'Verified';
        icon = Icons.verified_rounded;
        break;
      case 'rejected':
        if (partner.isDeleted) {
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
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
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
      case 'verified':
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

  void _showPartnerDetails(NetworkingBusinessPartner partner, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AdminPartnerDetailsSheet(
        partner: partner,
        type: type,
        onStatusChanged: _loadPartners,
        primaryGreen: _primaryGreen,
      ),
    );
  }

  void _showVerificationDialog(NetworkingBusinessPartner partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Business Partner'),
        content: Text('Are you sure you want to verify "${partner.businessName}"? This will make it visible to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyPartner(partner);
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

  void _showRejectionDialog(NetworkingBusinessPartner partner) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Business Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${partner.businessName}"?'),
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
              _rejectPartner(partner, reasonController.text);
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

  void _verifyPartner(NetworkingBusinessPartner partner) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedPartner = NetworkingBusinessPartner(
      id: partner.id,
      businessName: partner.businessName,
      ownerName: partner.ownerName,
      email: partner.email,
      phone: partner.phone,
      address: partner.address,
      state: partner.state,
      city: partner.city,
      businessType: partner.businessType,
      industry: partner.industry,
      description: partner.description,
      website: partner.website,
      licenseNumber: partner.licenseNumber,
      taxId: partner.taxId,
      yearsInBusiness: partner.yearsInBusiness,
      servicesOffered: partner.servicesOffered,
      targetMarkets: partner.targetMarkets,
      logoImageBase64: partner.logoImageBase64,
      galleryImagesBase64: partner.galleryImagesBase64,
      businessHours: partner.businessHours,
      languagesSpoken: partner.languagesSpoken,
      isVerified: true,
      isActive: true,
      isDeleted: false,
      rating: partner.rating,
      totalReviews: partner.totalReviews,
      totalLikes: partner.totalLikes,
      likedByUsers: partner.likedByUsers,
      createdBy: partner.createdBy,
      createdAt: partner.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?partner.additionalInfo,
        'verifiedAt': DateTime.now().toIso8601String(),
        'verifiedBy': 'admin',
      },
      certifications: partner.certifications,
      socialMediaLinks: partner.socialMediaLinks,
    );

    final success = await provider.updateBusinessPartner(partner.id!, updatedPartner);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${partner.businessName} verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPartners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify partner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectPartner(NetworkingBusinessPartner partner, String reason) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedPartner = NetworkingBusinessPartner(
      id: partner.id,
      businessName: partner.businessName,
      ownerName: partner.ownerName,
      email: partner.email,
      phone: partner.phone,
      address: partner.address,
      state: partner.state,
      city: partner.city,
      businessType: partner.businessType,
      industry: partner.industry,
      description: partner.description,
      website: partner.website,
      licenseNumber: partner.licenseNumber,
      taxId: partner.taxId,
      yearsInBusiness: partner.yearsInBusiness,
      servicesOffered: partner.servicesOffered,
      targetMarkets: partner.targetMarkets,
      logoImageBase64: partner.logoImageBase64,
      galleryImagesBase64: partner.galleryImagesBase64,
      businessHours: partner.businessHours,
      languagesSpoken: partner.languagesSpoken,
      isVerified: false,
      isActive: false,
      isDeleted: true,
      rating: partner.rating,
      totalReviews: partner.totalReviews,
      totalLikes: partner.totalLikes,
      likedByUsers: partner.likedByUsers,
      createdBy: partner.createdBy,
      createdAt: partner.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?partner.additionalInfo,
        'rejectionReason': reason,
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectedBy': 'admin',
      },
      certifications: partner.certifications,
      socialMediaLinks: partner.socialMediaLinks,
    );

    final success = await provider.updateBusinessPartner(partner.id!, updatedPartner);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${partner.businessName} rejected${reason.isNotEmpty ? ': $reason' : ''}'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPartners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject partner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deactivatePartner(NetworkingBusinessPartner partner) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedPartner = NetworkingBusinessPartner(
      id: partner.id,
      businessName: partner.businessName,
      ownerName: partner.ownerName,
      email: partner.email,
      phone: partner.phone,
      address: partner.address,
      state: partner.state,
      city: partner.city,
      businessType: partner.businessType,
      industry: partner.industry,
      description: partner.description,
      website: partner.website,
      licenseNumber: partner.licenseNumber,
      taxId: partner.taxId,
      yearsInBusiness: partner.yearsInBusiness,
      servicesOffered: partner.servicesOffered,
      targetMarkets: partner.targetMarkets,
      logoImageBase64: partner.logoImageBase64,
      galleryImagesBase64: partner.galleryImagesBase64,
      businessHours: partner.businessHours,
      languagesSpoken: partner.languagesSpoken,
      isVerified: partner.isVerified,
      isActive: false,
      isDeleted: false,
      rating: partner.rating,
      totalReviews: partner.totalReviews,
      totalLikes: partner.totalLikes,
      likedByUsers: partner.likedByUsers,
      createdBy: partner.createdBy,
      createdAt: partner.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?partner.additionalInfo,
        'deactivatedAt': DateTime.now().toIso8601String(),
        'deactivatedBy': 'admin',
      },
      certifications: partner.certifications,
      socialMediaLinks: partner.socialMediaLinks,
    );

    final success = await provider.updateBusinessPartner(partner.id!, updatedPartner);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${partner.businessName} deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPartners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate partner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deletePartner(NetworkingBusinessPartner partner) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedPartner = NetworkingBusinessPartner(
      id: partner.id,
      businessName: partner.businessName,
      ownerName: partner.ownerName,
      email: partner.email,
      phone: partner.phone,
      address: partner.address,
      state: partner.state,
      city: partner.city,
      businessType: partner.businessType,
      industry: partner.industry,
      description: partner.description,
      website: partner.website,
      licenseNumber: partner.licenseNumber,
      taxId: partner.taxId,
      yearsInBusiness: partner.yearsInBusiness,
      servicesOffered: partner.servicesOffered,
      targetMarkets: partner.targetMarkets,
      logoImageBase64: partner.logoImageBase64,
      galleryImagesBase64: partner.galleryImagesBase64,
      businessHours: partner.businessHours,
      languagesSpoken: partner.languagesSpoken,
      isVerified: partner.isVerified,
      isActive: false,
      isDeleted: true,
      rating: partner.rating,
      totalReviews: partner.totalReviews,
      totalLikes: partner.totalLikes,
      likedByUsers: partner.likedByUsers,
      createdBy: partner.createdBy,
      createdAt: partner.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?partner.additionalInfo,
        'deletedAt': DateTime.now().toIso8601String(),
        'deletedBy': 'admin',
      },
      certifications: partner.certifications,
      socialMediaLinks: partner.socialMediaLinks,
    );

    final success = await provider.updateBusinessPartner(partner.id!, updatedPartner);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${partner.businessName} moved to rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPartners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete partner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restorePartner(NetworkingBusinessPartner partner) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedPartner = NetworkingBusinessPartner(
      id: partner.id,
      businessName: partner.businessName,
      ownerName: partner.ownerName,
      email: partner.email,
      phone: partner.phone,
      address: partner.address,
      state: partner.state,
      city: partner.city,
      businessType: partner.businessType,
      industry: partner.industry,
      description: partner.description,
      website: partner.website,
      licenseNumber: partner.licenseNumber,
      taxId: partner.taxId,
      yearsInBusiness: partner.yearsInBusiness,
      servicesOffered: partner.servicesOffered,
      targetMarkets: partner.targetMarkets,
      logoImageBase64: partner.logoImageBase64,
      galleryImagesBase64: partner.galleryImagesBase64,
      businessHours: partner.businessHours,
      languagesSpoken: partner.languagesSpoken,
      isVerified: false,
      isActive: true,
      isDeleted: false,
      rating: partner.rating,
      totalReviews: partner.totalReviews,
      totalLikes: partner.totalLikes,
      likedByUsers: partner.likedByUsers,
      createdBy: partner.createdBy,
      createdAt: partner.createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: {
        ...?partner.additionalInfo,
        'restoredAt': DateTime.now().toIso8601String(),
        'restoredBy': 'admin',
      },
      certifications: partner.certifications,
      socialMediaLinks: partner.socialMediaLinks,
    );

    final success = await provider.updateBusinessPartner(partner.id!, updatedPartner);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${partner.businessName} restored to pending'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPartners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore partner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

/*  void _permanentDeletePartner(NetworkingBusinessPartner partner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text(
          'Are you sure you want to permanently delete "${partner.businessName}"? '
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
    final success = await provider.permanentDeleteBusinessPartner(partner.id!);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${partner.businessName} permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPartners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to permanently delete partner'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } */
}

class AdminPartnerDetailsSheet extends StatelessWidget {
  final NetworkingBusinessPartner partner;
  final String type;
  final VoidCallback onStatusChanged;
  final Color primaryGreen;

  const AdminPartnerDetailsSheet({
    Key? key,
    required this.partner,
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
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
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
                        'Business Details',
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
                    // Header with business info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Container(
                          width: isTablet ? 100 : 80,
                          height: isTablet ? 100 : 80,
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: partner.logoImageBase64 != null && partner.logoImageBase64!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _base64ToImage(partner.logoImageBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.broken_image_rounded,
                                        size: 40,
                                        color: primaryGreen,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.store_rounded,
                                  size: isTablet ? 50 : 40,
                                  color: primaryGreen,
                                ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        
                        // Business Name and Owner
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                partner.businessName,
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                partner.ownerName,
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailStatusChip(),
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
                          _buildStatItem(
                            Icons.star_rounded, 
                            'Rating', 
                            partner.rating.toStringAsFixed(1),
                            isTablet: isTablet,
                          ),
                          _buildStatItem(
                            Icons.reviews_rounded, 
                            'Reviews', 
                            '${partner.totalReviews}',
                            isTablet: isTablet,
                          ),
                          _buildStatItem(
                            Icons.favorite_rounded, 
                            'Likes', 
                            '${partner.totalLikes}',
                            isTablet: isTablet,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 28 : 24),
                    
                    // Business Information
                    _buildSectionTitle('Business Information', Icons.business_rounded, primaryGreen, isTablet: isTablet),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Industry', partner.industry, isTablet: isTablet),
                          _buildInfoRow('Business Type', partner.businessType.displayName, isTablet: isTablet),
                          _buildInfoRow('Years in Business', '${partner.yearsInBusiness} years', isTablet: isTablet),
                          if (partner.licenseNumber != null && partner.licenseNumber!.isNotEmpty)
                            _buildInfoRow('License #', partner.licenseNumber!, isTablet: isTablet),
                          if (partner.taxId != null && partner.taxId!.isNotEmpty)
                            _buildInfoRow('Tax ID', partner.taxId!, isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Description
                    _buildSectionTitle('Description', Icons.description_rounded, Colors.blue, isTablet: isTablet),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        partner.description,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 15, 
                          height: 1.5,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Location
                    _buildSectionTitle('Location', Icons.location_on_rounded, Colors.red, isTablet: isTablet),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(partner.address, style: TextStyle(fontSize: isTablet ? 16 : 15)),
                          const SizedBox(height: 4),
                          Text(
                            '${partner.city}, ${partner.state}',
                            style: TextStyle(fontSize: isTablet ? 16 : 15),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Contact Information
                    _buildSectionTitle('Contact Information', Icons.contact_phone_rounded, primaryGreen, isTablet: isTablet),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildContactInfo(Icons.phone_rounded, partner.phone, isLink: true, isTablet: isTablet),
                          const Divider(height: 16),
                          _buildContactInfo(Icons.email_rounded, partner.email, isLink: true, isTablet: isTablet),
                          if (partner.website != null && partner.website!.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildContactInfo(Icons.language_rounded, partner.website!, isLink: true, isTablet: isTablet),
                          ],
                        ],
                      ),
                    ),
                    
                    // Services Offered
                    if (partner.servicesOffered.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Services Offered', Icons.checklist_rounded, Colors.purple, isTablet: isTablet),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: partner.servicesOffered.map((service) {
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
                                service,
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
                    
                    // Target Markets
                    if (partner.targetMarkets.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Target Markets', Icons.people_rounded, Colors.blue, isTablet: isTablet),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: partner.targetMarkets.map((market) {
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
                                market,
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
                    
                    // Business Hours
                    if (partner.businessHours.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Business Hours', Icons.schedule_rounded, Colors.orange, isTablet: isTablet),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: partner.businessHours.map((hour) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: isTablet ? 16 : 14, color: Colors.orange[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      hour,
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
                    
                    // Languages Spoken
                    if (partner.languagesSpoken.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Languages Spoken', Icons.language_rounded, Colors.teal, isTablet: isTablet),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: partner.languagesSpoken.map((language) {
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
                    if (partner.certifications != null && partner.certifications!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Certifications', Icons.verified_rounded, Colors.green, isTablet: isTablet),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: partner.certifications!.map((cert) {
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
                    
                    // Social Media Links
                    if (partner.socialMediaLinks != null && partner.socialMediaLinks!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Social Media', Icons.link_rounded, Colors.blue, isTablet: isTablet),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: partner.socialMediaLinks!.map((link) {
                            return InkWell(
                              onTap: () => _launchUrl(link),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12, 
                                  vertical: isTablet ? 8 : 6
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.open_in_new_rounded, size: isTablet ? 14 : 12, color: Colors.blue[800]),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getDisplayUrl(link),
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontSize: isTablet ? 13 : 12,
                                      ),
                                    ),
                                  ],
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
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow('Posted By', partner.createdBy, isTablet: isTablet),
                          _buildInfoRow('Created', _formatDateTime(partner.createdAt), isTablet: isTablet),
                          _buildInfoRow('Updated', _formatDateTime(partner.updatedAt), isTablet: isTablet),
                          if (partner.additionalInfo?['verifiedAt'] != null)
                            _buildInfoRow('Verified', _formatDateTime(DateTime.parse(partner.additionalInfo!['verifiedAt'])), isTablet: isTablet),
                          if (partner.additionalInfo?['rejectedAt'] != null)
                            _buildInfoRow('Rejected', _formatDateTime(DateTime.parse(partner.additionalInfo!['rejectedAt'])), isTablet: isTablet),
                          if (partner.additionalInfo?['deactivatedAt'] != null)
                            _buildInfoRow('Deactivated', _formatDateTime(DateTime.parse(partner.additionalInfo!['deactivatedAt'])), isTablet: isTablet),
                          if (partner.additionalInfo?['restoredAt'] != null)
                            _buildInfoRow('Restored', _formatDateTime(DateTime.parse(partner.additionalInfo!['restoredAt'])), isTablet: isTablet),
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
    } else if (type == 'verified') {
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

  Widget _buildDetailStatusChip() {
    Color color;
    String text;
    IconData icon;

    if (!partner.isVerified && !partner.isDeleted && partner.isActive) {
      color = Colors.orange;
      text = 'Pending';
      icon = Icons.pending_rounded;
    } else if (partner.isVerified && !partner.isDeleted && partner.isActive) {
      color = Colors.green;
      text = 'Verified';
      icon = Icons.verified_rounded;
    } else if (partner.isDeleted) {
      color = Colors.red;
      text = 'Deleted';
      icon = Icons.delete_rounded;
    } else {
      color = Colors.grey;
      text = 'Inactive';
      icon = Icons.block_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
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
            width: isTablet ? 130 : 110,
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

  Widget _buildContactInfo(IconData icon, String value, {required bool isLink, required bool isTablet}) {
    return InkWell(
      onTap: isLink ? () => _launchUrl(value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: isTablet ? 22 : 18, color: Colors.grey[600]),
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

  String _getDisplayUrl(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceAll('www.', '');
    } catch (e) {
      return url;
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