// lib/screens/admin/entrepreneurship/admin_entrepreneurship_dashboard.dart

import 'package:bangla_hub/models/entrepreneurship_models.dart';
import 'package:bangla_hub/providers/entrepreneurship_provider.dart';
import 'package:bangla_hub/screens/admin_app/screens/business_management/admin_job_postings/admin_job_postings_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/business_management/business_partner_requests/business_partner_requests_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/business_management/business_promotions/business_promotions_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/business_management/networking_partners/networking_partners_screen.dart';
import 'package:bangla_hub/screens/admin_app/screens/business_management/others_job_site/others_job_site_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';



class AdminEntrepreneurshipDashboard extends StatefulWidget {
  @override
  _AdminEntrepreneurshipDashboardState createState() => _AdminEntrepreneurshipDashboardState();
}

class _AdminEntrepreneurshipDashboardState extends State<AdminEntrepreneurshipDashboard> with SingleTickerProviderStateMixin {
  final Color _primaryGreen = const Color(0xFF006A4E);
  final Color _darkGreen = const Color(0xFF004D38);
  final Color _lightGreen = const Color(0xFFE8F5E9);

  bool _isRefreshing = false;
  DateTime _lastRefreshTime = DateTime.now();
  
  late TabController _tabController;

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
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final provider = Provider.of<EntrepreneurshipProvider>(context, listen: false);
      
      await Future.wait([
        provider.loadBusinessPartners(adminView: true),
        provider.loadJobPostings(adminView: true, includeExpired: true),
        provider.loadBusinessPromotions(adminView: true),
        provider.loadPartnerRequests(adminView: true),
      ]);
      
      setState(() {
        _lastRefreshTime = DateTime.now();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Navigation methods for pending items
  void _showJobDetails(JobPosting job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminJobDetailsSheet(
        job: job,
        type: 'pending',
        onStatusChanged: () => _loadData(),
        primaryGreen: _primaryGreen,
      ),
    );
  }

  void _showRequestDetails(BusinessPartnerRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminRequestDetailsSheet(
        request: request,
        type: 'pending',
        onStatusChanged: () => _loadData(),
        primaryGreen: _primaryGreen,
      ),
    );
  }

  void _showPromotionDetails(SmallBusinessPromotion promotion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminPromotionDetailsSheet(
        promotion: promotion,
        type: 'pending',
        onStatusChanged: () => _loadData(),
        primaryGreen: _primaryGreen,
      ),
    );
  }

  void _showPartnerDetails(NetworkingBusinessPartner partner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminPartnerDetailsSheet(
        partner: partner,
        type: 'pending',
        onStatusChanged: () => _loadData(),
        primaryGreen: _primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGreen,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entrepreneurship',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 25),
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
                tabs: const [
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
        onPressed: _isRefreshing ? null : _loadData,
        backgroundColor: _primaryGreen,
        child: _isRefreshing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.refresh_rounded),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Consumer<EntrepreneurshipProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: _loadData,
          color: _primaryGreen,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Last refreshed
              if (_lastRefreshTime != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.update_rounded, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Last updated: ${_formatTimeAgo(_lastRefreshTime!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              
              _buildStatsSection(provider),
              const SizedBox(height: 24),
              
              _buildSectionHeader('Business Management'),
              _buildMenuCard(
                icon: Icons.store_rounded,
                title: 'Networking Business Partners',
                subtitle: 'Manage business partner listings',
                route: AdminNetworkingPartnersScreen(),
                color: Colors.blue,
                pendingCount: provider.businessPartners
                    .where((p) => !p.isVerified && !p.isDeleted && p.isActive)
                    .length,
              ),
              const SizedBox(height: 12),
              
              _buildMenuCard(
                icon: Icons.work_rounded,
                title: 'Job Postings',
                subtitle: 'Manage job postings from businesses',
                route: AdminJobPostingsScreen(),
                color: Colors.green,
                pendingCount: provider.jobPostings
                    .where((j) => !j.isVerified && !j.isDeleted && j.isActive)
                    .length,
              ),
              const SizedBox(height: 12),
              
              _buildMenuCard(
                icon: Icons.storefront_rounded,
                title: 'Business Promotions',
                subtitle: 'Manage business promotions',
                route: AdminBusinessPromotionsScreen(),
                color: Colors.purple,
                pendingCount: provider.businessPromotions
                    .where((p) => !p.isVerified && !p.isDeleted && p.isActive)
                    .length,
              ),
              const SizedBox(height: 12),
              
              _buildMenuCard(
                icon: Icons.people_rounded,
                title: 'Partner Requests',
                subtitle: 'Manage business partner requests',
                route: AdminBusinessPartnerRequestsScreen(),
                color: Colors.orange,
                pendingCount: provider.partnerRequests
                    .where((r) => !r.isVerified && !r.isDeleted && r.isActive)
                    .length,
              ),
              const SizedBox(height: 12),
              
              _buildMenuCard(
                icon: Icons.public_rounded,
                title: 'External Job Sites',
                subtitle: 'Manage external job platforms',
                route: AdminJobSitesScreen(),
                color: Colors.teal,
              ),
              
              const SizedBox(height: 20),
              
              // System Status
              _buildSystemStatus(),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingReviewsTab() {
    return Consumer<EntrepreneurshipProvider>(
      builder: (context, provider, child) {
        final pendingItems = _getPendingItems(provider);
        
        if (pendingItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 80, color: Colors.green[300]),
                const SizedBox(height: 16),
                Text(
                  'All caught up!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.green[700]),
                ),
                const SizedBox(height: 8),
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
          color: _primaryGreen,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
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

  Widget _buildPendingItemCard(dynamic item) {
    String type;
    Color color;
    IconData icon;
    String title;
    String subtitle;
    VoidCallback onTap;

    if (item is NetworkingBusinessPartner) {
      type = 'Business Partner';
      color = Colors.blue;
      icon = Icons.store_rounded;
      title = item.businessName;
      subtitle = 'Requested by: ${item.ownerName}';
      onTap = () => _showPartnerDetails(item);
    } else if (item is JobPosting) {
      type = 'Job Posting';
      color = Colors.green;
      icon = Icons.work_rounded;
      title = item.jobTitle;
      subtitle = '${item.companyName} • ${item.location}';
      onTap = () => _showJobDetails(item);
    } else if (item is SmallBusinessPromotion) {
      type = 'Business Promotion';
      color = Colors.purple;
      icon = Icons.storefront_rounded;
      title = item.businessName;
      subtitle = 'Posted by: ${item.ownerName}';
      onTap = () => _showPromotionDetails(item);
    } else if (item is BusinessPartnerRequest) {
      type = 'Partner Request';
      color = Colors.orange;
      icon = Icons.people_rounded;
      title = item.title;
      subtitle = 'Partner Type: ${item.partnerType.displayName}';
      onTap = () => _showRequestDetails(item);
    } else {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                        const SizedBox(width: 8),
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
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildStatsSection(EntrepreneurshipProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: _primaryGreen, size: 24),
              const SizedBox(width: 8),
              Text(
                'Overview',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isTablet ? 4 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                icon: Icons.store_rounded,
                value: provider.businessPartners.length.toString(),
                label: 'Total Partners',
                color: Colors.blue,
                pending: provider.businessPartners
                    .where((p) => !p.isVerified && !p.isDeleted && p.isActive)
                    .length,
              ),
              _buildStatCard(
                icon: Icons.work_rounded,
                value: provider.jobPostings.length.toString(),
                label: 'Total Jobs',
                color: Colors.green,
                pending: provider.jobPostings
                    .where((j) => !j.isVerified && !j.isDeleted && j.isActive)
                    .length,
              ),
              _buildStatCard(
                icon: Icons.storefront_rounded,
                value: provider.businessPromotions.length.toString(),
                label: 'Promotions',
                color: Colors.purple,
                pending: provider.businessPromotions
                    .where((p) => !p.isVerified && !p.isDeleted && p.isActive)
                    .length,
              ),
              _buildStatCard(
                icon: Icons.people_rounded,
                value: provider.partnerRequests.length.toString(),
                label: 'Requests',
                color: Colors.orange,
                pending: provider.partnerRequests
                    .where((r) => !r.isVerified && !r.isDeleted && r.isActive)
                    .length,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          
          // Engagement Stats
          Row(
            children: [
              Expanded(
                child: _buildEngagementStat(
                  icon: Icons.favorite_rounded,
                  value: _formatNumber(provider.businessPartners.fold<int>(0, (sum, p) => sum + p.totalLikes)),
                  label: 'Total Likes',
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    int pending = 0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return Container(
      padding: const EdgeInsets.all(8),
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
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      pending.toString(),
                      style: const TextStyle(
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
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
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

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_rounded, color: _primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'System Status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 14),
          const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkGreen,
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
          padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 16),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pendingCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
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

  List<dynamic> _getPendingItems(EntrepreneurshipProvider provider) {
    List<dynamic> pending = [];
    
    pending.addAll(provider.businessPartners
        .where((p) => !p.isVerified && !p.isDeleted && p.isActive)
        .toList());
    
    pending.addAll(provider.jobPostings
        .where((j) => !j.isVerified && !j.isDeleted && j.isActive)
        .toList());
    
    pending.addAll(provider.businessPromotions
        .where((p) => !p.isVerified && !p.isDeleted && p.isActive)
        .toList());
    
    pending.addAll(provider.partnerRequests
        .where((r) => !r.isVerified && !r.isDeleted && r.isActive)
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