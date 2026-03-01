// lib/screens/admin/entrepreneurship/admin_business_partner_requests_screen.dart

import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminBusinessPartnerRequestsScreen extends StatefulWidget {
  @override
  _AdminBusinessPartnerRequestsScreenState createState() => _AdminBusinessPartnerRequestsScreenState();
}

class _AdminBusinessPartnerRequestsScreenState extends State<AdminBusinessPartnerRequestsScreen> with SingleTickerProviderStateMixin {
  final Color _primaryGreen = Color(0xFF006A4E);
  final Color _darkGreen = Color(0xFF004D38);
  late TabController _tabController;
  
  // Search controllers for each tab
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
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

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    await provider.loadPartnerRequests(adminView: true);
    
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
                            'Manage Partner Requests',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 28 : (isSmallScreen ? 20 : 24),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                            'Review, verify, and manage business partner requests',
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
                                ? 'Search requests by title, contact, industry, location...'
                                : 'Search requests...',
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
                                  final count = provider.partnerRequests
                                      .where((r) => !r.isVerified && !r.isDeleted && r.isActive)
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
                                  final count = provider.partnerRequests
                                      .where((r) => r.isVerified && !r.isDeleted && r.isActive)
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
                                  final count = provider.partnerRequests
                                      .where((r) => r.isDeleted || !r.isActive)
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
            if (_isLoading && provider.partnerRequests.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: _primaryGreen),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(provider, 'pending'),
                _buildRequestList(provider, 'active'),
                _buildRequestList(provider, 'rejected'),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRequests,
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

  Widget _buildRequestList(EntrepreneurshipProvider provider, String type) {
    List<BusinessPartnerRequest> filteredRequests;
    
    switch (type) {
      case 'pending':
        filteredRequests = provider.partnerRequests
            .where((r) => !r.isVerified && !r.isDeleted && r.isActive)
            .toList();
        break;
      case 'active':
        filteredRequests = provider.partnerRequests
            .where((r) => r.isVerified && !r.isDeleted && r.isActive)
            .toList();
        break;
      case 'rejected':
        filteredRequests = provider.partnerRequests
            .where((r) => r.isDeleted || !r.isActive)
            .toList();
        break;
      default:
        filteredRequests = [];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredRequests = filteredRequests.where((request) {
        return request.title.toLowerCase().contains(_searchQuery) ||
               request.description.toLowerCase().contains(_searchQuery) ||
               request.contactName.toLowerCase().contains(_searchQuery) ||
               request.industry.toLowerCase().contains(_searchQuery) ||
               request.city.toLowerCase().contains(_searchQuery) ||
               request.location.toLowerCase().contains(_searchQuery) ||
               (request.contactEmail?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Sort by date (newest first) and urgent first
    filteredRequests.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    if (filteredRequests.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty 
            ? 'No matching results found'
            : type == 'pending' 
                ? 'No pending requests' 
                : type == 'active' 
                    ? 'No active requests' 
                    : 'No rejected requests',
        type == 'pending' ? Icons.pending_actions_rounded :
        type == 'active' ? Icons.check_circle_rounded : Icons.block_rounded,
        hasSearch: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: _primaryGreen,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(filteredRequests[index], type);
        },
      ),
    );
  }

  Widget _buildRequestCard(BusinessPartnerRequest request, String type) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: request.isUrgent && type == 'pending'
              ? Border.all(color: Colors.red, width: 2)
              : null,
        ),
        child: InkWell(
          onTap: () => _showRequestDetails(request, type),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isSmallScreen ? 50 : 60,
                      height: isSmallScreen ? 50 : 60,
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        request.isUrgent ? Icons.priority_high_rounded : Icons.people_rounded,
                        color: _getTypeColor(type),
                        size: isSmallScreen ? 25 : 30,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  request.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (request.isUrgent)
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
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            request.contactName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            request.industry,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: _primaryGreen,
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
                      isSmallScreen ? request.city : '${request.city}, ${request.state}',
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.attach_money_rounded,
                      request.formattedBudget,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.schedule_rounded,
                      request.investmentDuration,
                      isSmallScreen: isSmallScreen,
                    ),
                    _buildInfoChip(
                      Icons.person_rounded,
                      request.partnerType.displayName,
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
                    _buildStatusChip(request, type, isSmallScreen: isSmallScreen),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_rounded, size: isSmallScreen ? 12 : 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            '${request.totalViews}',
                            style: TextStyle(fontSize: isSmallScreen ? 10 : 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.message_rounded, size: isSmallScreen ? 12 : 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            '${request.totalResponses}',
                            style: TextStyle(fontSize: isSmallScreen ? 10 : 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Admin Actions based on type
                _buildActionButtons(request, type, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BusinessPartnerRequest request, String type, bool isSmallScreen) {
    if (type == 'pending') {
      return Column(
        children: [
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVerificationDialog(request),
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
                  onPressed: () => _showRejectionDialog(request),
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
                  onPressed: () => _deactivateRequest(request),
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
                  onPressed: () => _deleteRequest(request),
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
                  onPressed: () => _restoreRequest(request),
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
                //  onPressed: () => _permanentDeleteRequest(request),
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

  Widget _buildStatusChip(BusinessPartnerRequest request, String type, {required bool isSmallScreen}) {
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
        if (request.isDeleted) {
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

  void _showRequestDetails(BusinessPartnerRequest request, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AdminRequestDetailsSheet(
        request: request,
        type: type,
        onStatusChanged: _loadRequests,
        primaryGreen: _primaryGreen,
      ),
    );
  }

  void _showVerificationDialog(BusinessPartnerRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Partner Request'),
        content: Text('Are you sure you want to verify "${request.title}"? This will make it visible to all users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyRequest(request);
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

  void _verifyRequest(BusinessPartnerRequest request) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedRequest = BusinessPartnerRequest(
      id: request.id,
      title: request.title,
      description: request.description,
      partnerType: request.partnerType,
      businessType: request.businessType,
      industry: request.industry,
      location: request.location,
      state: request.state,
      city: request.city,
      budgetMin: request.budgetMin,
      budgetMax: request.budgetMax,
      investmentDuration: request.investmentDuration,
      skillsRequired: request.skillsRequired,
      responsibilities: request.responsibilities,
      contactName: request.contactName,
      contactEmail: request.contactEmail,
      contactPhone: request.contactPhone,
      preferredMeetingMethod: request.preferredMeetingMethod,
      additionalDocumentsBase64: request.additionalDocumentsBase64,
      isVerified: true,
      isActive: true,
      isDeleted: false,
      isUrgent: request.isUrgent,
      totalViews: request.totalViews,
      totalResponses: request.totalResponses,
      createdBy: request.createdBy,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
      category: request.category,
      tags: request.tags,
      additionalInfo: {
        ...?request.additionalInfo,
        'verifiedAt': DateTime.now().toIso8601String(),
        'verifiedBy': 'admin',
      },
    );

    final success = await provider.updatePartnerRequest(request.id!, updatedRequest);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partner request verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectionDialog(BusinessPartnerRequest request) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Partner Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject "${request.title}"?'),
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
              _rejectRequest(request, reasonController.text);
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

  void _rejectRequest(BusinessPartnerRequest request, String reason) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedRequest = BusinessPartnerRequest(
      id: request.id,
      title: request.title,
      description: request.description,
      partnerType: request.partnerType,
      businessType: request.businessType,
      industry: request.industry,
      location: request.location,
      state: request.state,
      city: request.city,
      budgetMin: request.budgetMin,
      budgetMax: request.budgetMax,
      investmentDuration: request.investmentDuration,
      skillsRequired: request.skillsRequired,
      responsibilities: request.responsibilities,
      contactName: request.contactName,
      contactEmail: request.contactEmail,
      contactPhone: request.contactPhone,
      preferredMeetingMethod: request.preferredMeetingMethod,
      additionalDocumentsBase64: request.additionalDocumentsBase64,
      isVerified: false,
      isActive: false,
      isDeleted: true,
      isUrgent: request.isUrgent,
      totalViews: request.totalViews,
      totalResponses: request.totalResponses,
      createdBy: request.createdBy,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
      category: request.category,
      tags: request.tags,
      additionalInfo: {
        ...?request.additionalInfo,
        'rejectionReason': reason,
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectedBy': 'admin',
      },
    );

    final success = await provider.updatePartnerRequest(request.id!, updatedRequest);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partner request rejected${reason.isNotEmpty ? ': $reason' : ''}'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deactivateRequest(BusinessPartnerRequest request) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedRequest = BusinessPartnerRequest(
      id: request.id,
      title: request.title,
      description: request.description,
      partnerType: request.partnerType,
      businessType: request.businessType,
      industry: request.industry,
      location: request.location,
      state: request.state,
      city: request.city,
      budgetMin: request.budgetMin,
      budgetMax: request.budgetMax,
      investmentDuration: request.investmentDuration,
      skillsRequired: request.skillsRequired,
      responsibilities: request.responsibilities,
      contactName: request.contactName,
      contactEmail: request.contactEmail,
      contactPhone: request.contactPhone,
      preferredMeetingMethod: request.preferredMeetingMethod,
      additionalDocumentsBase64: request.additionalDocumentsBase64,
      isVerified: request.isVerified,
      isActive: false,
      isDeleted: false,
      isUrgent: request.isUrgent,
      totalViews: request.totalViews,
      totalResponses: request.totalResponses,
      createdBy: request.createdBy,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
      category: request.category,
      tags: request.tags,
      additionalInfo: {
        ...?request.additionalInfo,
        'deactivatedAt': DateTime.now().toIso8601String(),
        'deactivatedBy': 'admin',
      },
    );

    final success = await provider.updatePartnerRequest(request.id!, updatedRequest);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request deactivated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteRequest(BusinessPartnerRequest request) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedRequest = BusinessPartnerRequest(
      id: request.id,
      title: request.title,
      description: request.description,
      partnerType: request.partnerType,
      businessType: request.businessType,
      industry: request.industry,
      location: request.location,
      state: request.state,
      city: request.city,
      budgetMin: request.budgetMin,
      budgetMax: request.budgetMax,
      investmentDuration: request.investmentDuration,
      skillsRequired: request.skillsRequired,
      responsibilities: request.responsibilities,
      contactName: request.contactName,
      contactEmail: request.contactEmail,
      contactPhone: request.contactPhone,
      preferredMeetingMethod: request.preferredMeetingMethod,
      additionalDocumentsBase64: request.additionalDocumentsBase64,
      isVerified: request.isVerified,
      isActive: false,
      isDeleted: true,
      isUrgent: request.isUrgent,
      totalViews: request.totalViews,
      totalResponses: request.totalResponses,
      createdBy: request.createdBy,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
      category: request.category,
      tags: request.tags,
      additionalInfo: {
        ...?request.additionalInfo,
        'deletedAt': DateTime.now().toIso8601String(),
        'deletedBy': 'admin',
      },
    );

    final success = await provider.updatePartnerRequest(request.id!, updatedRequest);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request moved to rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _loadRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restoreRequest(BusinessPartnerRequest request) async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
    
    final updatedRequest = BusinessPartnerRequest(
      id: request.id,
      title: request.title,
      description: request.description,
      partnerType: request.partnerType,
      businessType: request.businessType,
      industry: request.industry,
      location: request.location,
      state: request.state,
      city: request.city,
      budgetMin: request.budgetMin,
      budgetMax: request.budgetMax,
      investmentDuration: request.investmentDuration,
      skillsRequired: request.skillsRequired,
      responsibilities: request.responsibilities,
      contactName: request.contactName,
      contactEmail: request.contactEmail,
      contactPhone: request.contactPhone,
      preferredMeetingMethod: request.preferredMeetingMethod,
      additionalDocumentsBase64: request.additionalDocumentsBase64,
      isVerified: false,
      isActive: true,
      isDeleted: false,
      isUrgent: request.isUrgent,
      totalViews: request.totalViews,
      totalResponses: request.totalResponses,
      createdBy: request.createdBy,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
      category: request.category,
      tags: request.tags,
      additionalInfo: {
        ...?request.additionalInfo,
        'restoredAt': DateTime.now().toIso8601String(),
        'restoredBy': 'admin',
      },
    );

    final success = await provider.updatePartnerRequest(request.id!, updatedRequest);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request restored to pending'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

 /* void _permanentDeleteRequest(BusinessPartnerRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text(
          'Are you sure you want to permanently delete "${request.title}"? '
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
    final success = await provider.permanentDeletePartnerRequest(request.id!);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
        _loadRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to permanently delete request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } */
}

class AdminRequestDetailsSheet extends StatelessWidget {
  final BusinessPartnerRequest request;
  final String type;
  final VoidCallback onStatusChanged;
  final Color primaryGreen;

  const AdminRequestDetailsSheet({
    Key? key,
    required this.request,
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
                        'Request Details',
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
                    // Title and Urgency
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.title,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 26 : 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (request.isUrgent)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 14 : 12, 
                              vertical: isTablet ? 8 : 6
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 20 : 16),
                    
                    // Status Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusBadge(
                          request.isVerified ? 'Verified' : 'Unverified',
                          request.isVerified ? Colors.green : Colors.orange,
                          isTablet: isTablet,
                        ),
                        _buildStatusBadge(
                          request.isActive ? 'Active' : 'Inactive',
                          request.isActive ? Colors.green : Colors.grey,
                          isTablet: isTablet,
                        ),
                        _buildStatusBadge(
                          request.isDeleted ? 'Deleted' : 'Not Deleted',
                          request.isDeleted ? Colors.red : Colors.green,
                          isTablet: isTablet,
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
                          _buildStatItem(Icons.visibility_rounded, 'Views', request.totalViews.toString(), isTablet: isTablet),
                          _buildStatItem(Icons.message_rounded, 'Responses', request.totalResponses.toString(), isTablet: isTablet),
                          _buildStatItem(Icons.access_time_rounded, 'Posted', _formatTimeAgo(request.createdAt), isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 28 : 24),
                    
                    // Contact Person
                    _buildSectionTitle('Contact Person', Icons.person_rounded, primaryGreen, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildContactInfo(Icons.person_rounded, request.contactName, isTablet: isTablet),
                          const Divider(height: 16),
                          _buildContactInfo(Icons.email_rounded, request.contactEmail, isLink: true, isTablet: isTablet),
                          const Divider(height: 16),
                          _buildContactInfo(Icons.phone_rounded, request.contactPhone, isLink: true, isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Business Details
                    _buildSectionTitle('Business Details', Icons.business_rounded, primaryGreen, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.category_rounded, 'Industry', request.industry, isTablet: isTablet),
                          _buildInfoRow(Icons.person_rounded, 'Partner Type', request.partnerType.displayName, isTablet: isTablet),
                          _buildInfoRow(Icons.business_rounded, 'Business Type', request.businessType.displayName, isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Location
                    _buildSectionTitle('Location', Icons.location_on_rounded, primaryGreen, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.location_on_rounded, 'Location', request.location, isTablet: isTablet),
                          _buildInfoRow(Icons.location_city_rounded, 'City', request.city, isTablet: isTablet),
                          _buildInfoRow(Icons.map_rounded, 'State', request.state, isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Financial Details
                    _buildSectionTitle('Financial Details', Icons.attach_money_rounded, Colors.green, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.attach_money_rounded, 'Budget', request.formattedBudget, isTablet: isTablet),
                          _buildInfoRow(Icons.schedule_rounded, 'Duration', request.investmentDuration, isTablet: isTablet),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Description
                    _buildSectionTitle('Description', Icons.description_rounded, primaryGreen, isTablet: isTablet),
                    SizedBox(height: 8),
                    _buildInfoCard(
                      child: Text(
                        request.description,
                        style: TextStyle(fontSize: isTablet ? 16 : 15, height: 1.5),
                      ),
                    ),
                    
                    if (request.skillsRequired.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Skills Required', Icons.code_rounded, Colors.blue, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: request.skillsRequired.map((skill) {
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
                    
                    if (request.responsibilities.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Responsibilities', Icons.task_rounded, Colors.purple, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: request.responsibilities.map((resp) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: isTablet ? 18 : 16, color: Colors.purple),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      resp,
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
                    
                    if (request.additionalInfo != null && request.additionalInfo!.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 20),
                      _buildSectionTitle('Additional Info', Icons.info_rounded, Colors.orange, isTablet: isTablet),
                      SizedBox(height: 8),
                      _buildInfoCard(
                        child: Column(
                          children: request.additionalInfo!.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: isTablet ? 130 : 110,
                                    child: Text(
                                      '${entry.key}:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                        fontSize: isTablet ? 14 : 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value.toString(),
                                      style: TextStyle(fontSize: isTablet ? 14 : 13),
                                    ),
                                  ),
                                ],
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
                          _buildInfoRow(Icons.add_circle_rounded, 'Created', _formatDate(request.createdAt), isTablet: isTablet),
                          _buildInfoRow(Icons.update_rounded, 'Updated', _formatDate(request.updatedAt), isTablet: isTablet),
                          if (request.additionalInfo?['rejectedAt'] != null)
                            _buildInfoRow(Icons.cancel_rounded, 'Rejected', 
                                _formatDate(DateTime.parse(request.additionalInfo!['rejectedAt'])), isTablet: isTablet),
                          if (request.additionalInfo?['deactivatedAt'] != null)
                            _buildInfoRow(Icons.pause_circle_rounded, 'Deactivated', 
                                _formatDate(DateTime.parse(request.additionalInfo!['deactivatedAt'])), isTablet: isTablet),
                          if (request.additionalInfo?['restoredAt'] != null)
                            _buildInfoRow(Icons.restore_rounded, 'Restored', 
                                _formatDate(DateTime.parse(request.additionalInfo!['restoredAt'])), isTablet: isTablet),
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

  Widget _buildInfoRow(IconData icon, String label, String value, {required bool isTablet}) {
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

  Widget _buildContactInfo(IconData icon, String value, {bool isLink = false, required bool isTablet}) {
    return Row(
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
    );
  }

  String _formatDate(DateTime date) {
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