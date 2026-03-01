// lib/screens/admin_app/screens/business_management/others_job_site/others_job_site_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:bangla_hub/models/job_sites_browse_model.dart';
import 'package:bangla_hub/providers/job_sites_browse_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class AdminJobSitesScreen extends StatefulWidget {
  @override
  _AdminJobSitesScreenState createState() => _AdminJobSitesScreenState();
}

class _AdminJobSitesScreenState extends State<AdminJobSitesScreen> with SingleTickerProviderStateMixin {
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
      _initializeProvider();
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

  Future<void> _initializeProvider() async {
    setState(() {
      _isLoading = true;
    });
    
    final provider = Provider.of<JobSitesBrowseProvider>(context, listen: false);
    await provider.initialize();
    
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSiteDialog(context),
        backgroundColor: _primaryBlue,
        icon: Icon(Icons.add_rounded),
        label: Text(isSmallScreen ? 'Add' : 'Add Job Site'),
      ),
      body: Consumer<JobSitesBrowseProvider>(
        builder: (context, provider, child) {
          if (!provider.isInitialized || _isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryBlue),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            );
          }

          return NestedScrollView(
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
                                'Manage Job Sites',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 30 : (isSmallScreen ? 22 : 26),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 8),
                              Text(
                                'Add, edit, and manage external job platforms',
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
                                    ? 'Search by site name, category, features...'
                                    : 'Search sites...',
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
                                  child: Consumer<JobSitesBrowseProvider>(
                                    builder: (context, provider, child) {
                                      final count = provider.jobSites
                                          .where((site) => site.isActive && !site.isDeleted)
                                          .length;
                                      return _buildTabContent(
                                        icon: Icons.check_circle_rounded,
                                        label: isSmallScreen ? 'Active' : 'Active',
                                        count: count,
                                        color: Colors.green,
                                        isSmallScreen: isSmallScreen,
                                      );
                                    },
                                  ),
                                ),
                                Tab(
                                  child: Consumer<JobSitesBrowseProvider>(
                                    builder: (context, provider, child) {
                                      final count = provider.jobSites
                                          .where((site) => !site.isActive || site.isDeleted)
                                          .length;
                                      return _buildTabContent(
                                        icon: Icons.block_rounded,
                                        label: isSmallScreen ? 'Inactive' : 'Inactive',
                                        count: count,
                                        color: Colors.orange,
                                        isSmallScreen: isSmallScreen,
                                      );
                                    },
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 12,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.analytics_rounded, size: isSmallScreen ? 16 : 18),
                                        SizedBox(width: isSmallScreen ? 4 : 8),
                                        Text(
                                          isSmallScreen ? 'Stats' : 'Analytics',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveSites(provider, isSmallScreen, isTablet),
                _buildInactiveSites(provider, isSmallScreen, isTablet),
                _buildAnalytics(provider, isSmallScreen, isTablet),
              ],
            ),
          );
        },
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

  Widget _buildActiveSites(JobSitesBrowseProvider provider, bool isSmallScreen, bool isTablet) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: _primaryBlue));
    }

    List<JobSite> filteredSites = provider.jobSites
        .where((site) => site.isActive && !site.isDeleted)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredSites = filteredSites.where((site) {
        return site.name.toLowerCase().contains(_searchQuery) ||
               site.description.toLowerCase().contains(_searchQuery) ||
               site.category.displayName.toLowerCase().contains(_searchQuery) ||
               site.features.any((feature) => feature.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    // Sort by click count (most popular first)
    filteredSites.sort((a, b) => b.clickCount.compareTo(a.clickCount));

    if (filteredSites.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty ? 'No matching sites found' : 'No active job sites',
        _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.check_circle_rounded,
        hasSearch: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: _primaryBlue,
      child: ListView.builder(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        itemCount: filteredSites.length,
        itemBuilder: (context, index) {
          return _buildSiteCard(filteredSites[index], provider, isActive: true, isSmallScreen: isSmallScreen);
        },
      ),
    );
  }

  Widget _buildInactiveSites(JobSitesBrowseProvider provider, bool isSmallScreen, bool isTablet) {
    List<JobSite> filteredSites = provider.jobSites
        .where((site) => !site.isActive || site.isDeleted)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredSites = filteredSites.where((site) {
        return site.name.toLowerCase().contains(_searchQuery) ||
               site.description.toLowerCase().contains(_searchQuery) ||
               site.category.displayName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Sort by date (newest first)
    filteredSites.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (filteredSites.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty ? 'No matching sites found' : 'No inactive job sites',
        _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.block_rounded,
        hasSearch: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: _primaryBlue,
      child: ListView.builder(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        itemCount: filteredSites.length,
        itemBuilder: (context, index) {
          return _buildSiteCard(filteredSites[index], provider, isActive: false, isSmallScreen: isSmallScreen);
        },
      ),
    );
  }

  Widget _buildAnalytics(JobSitesBrowseProvider provider, bool isSmallScreen, bool isTablet) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: _primaryBlue));
    }

    final stats = provider.clickStats;
    final totalClicks = stats['totalClicks'] ?? 0;
    final totalSites = stats['totalSites'] ?? provider.jobSites.length;
    final trends = (provider.clickStats['monthly'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e))
        .toList() ?? [];

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: _primaryBlue,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryBlue, _darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.3),
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
                      Icon(Icons.trending_up_rounded, color: Colors.white, size: isTablet ? 28 : 24),
                      SizedBox(width: 8),
                      Text(
                        'Total Clicks',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  Text(
                    _formatNumber(totalClicks),
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 56 : (isSmallScreen ? 36 : 48),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.web_rounded, color: Colors.white.withOpacity(0.8), size: isTablet ? 18 : 16),
                      SizedBox(width: 4),
                      Text(
                        'Across ${_formatNumber(totalSites)} sites',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isTablet ? 24 : 20),

            // Category Distribution
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                      Icon(Icons.pie_chart_rounded, color: _primaryBlue, size: isTablet ? 24 : 20),
                      SizedBox(width: 8),
                      Text(
                        'By Category',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  ...JobSiteCategory.values.map((category) {
                    final sitesInCategory = provider.getSitesByCategory(category);
                    final activeSites = sitesInCategory.where((s) => s.isActive).length;
                    final categoryClicks = sitesInCategory.fold<int>(
                      0,
                      (sum, site) => sum + site.clickCount,
                    );
                    final percentage = totalClicks > 0 
                        ? (categoryClicks / totalClicks * 100).toStringAsFixed(1)
                        : '0';
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: isTablet ? 44 : 36,
                                height: isTablet ? 44 : 36,
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  category.icon,
                                  color: category.color,
                                  size: isTablet ? 24 : 20,
                                ),
                              ),
                              SizedBox(width: isTablet ? 14 : 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isTablet ? 15 : 14,
                                      ),
                                    ),
                                    Text(
                                      '$activeSites active sites',
                                      style: TextStyle(
                                        fontSize: isTablet ? 13 : 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _primaryBlue,
                                    fontSize: isTablet ? 14 : 13,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(width: isTablet ? 10 : 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 10 : 8, 
                                  vertical: isTablet ? 6 : 4
                                ),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatNumber(categoryClicks),
                                  style: TextStyle(
                                    color: category.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isTablet ? 13 : 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalClicks > 0 ? categoryClicks / totalClicks : 0,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(category.color),
                              minHeight: isTablet ? 6 : 4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            
            SizedBox(height: isTablet ? 24 : 20),

            // Top Performing Sites
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                      Icon(Icons.leaderboard_rounded, color: _primaryBlue, size: isTablet ? 24 : 20),
                      SizedBox(width: 8),
                      Text(
                        'Top Performing Sites',
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  
                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: isTablet ? 12 : 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Site',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontSize: isTablet ? 14 : 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Category',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontSize: isTablet ? 14 : 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Clicks',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              fontSize: isTablet ? 14 : 12,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  ...provider.jobSites
                      .where((site) => site.isActive && !site.isDeleted)
                      .take(10)
                      .map((site) {
                    final clicks = site.clickCount;
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: isTablet ? 14 : 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              site.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: isTablet ? 15 : 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 8 : 6, 
                                vertical: isTablet ? 4 : 2
                              ),
                              decoration: BoxDecoration(
                                color: site.category.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                site.category.displayName,
                                style: TextStyle(
                                  color: site.category.color,
                                  fontSize: isTablet ? 12 : 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 10 : 8, 
                                vertical: isTablet ? 6 : 4
                              ),
                              decoration: BoxDecoration(
                                color: clicks > 0 ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatNumber(clicks),
                                style: TextStyle(
                                  color: clicks > 0 ? Colors.green[700] : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet ? 14 : 12,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Monthly Trends (if data available)
            if (trends.isNotEmpty) ...[
              SizedBox(height: isTablet ? 24 : 20),
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                        Icon(Icons.show_chart_rounded, color: _primaryBlue, size: isTablet ? 24 : 20),
                        SizedBox(width: 8),
                        Text(
                          'Monthly Trends',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    ...trends.map((trend) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: isTablet ? 90 : 80,
                              child: Text(
                                trend['month'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                  fontSize: isTablet ? 14 : 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (trend['value'] as double?) ?? 0,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
                                  minHeight: isTablet ? 10 : 8,
                                ),
                              ),
                            ),
                            SizedBox(width: isTablet ? 14 : 12),
                            Text(
                              (trend['count'] ?? 0).toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _primaryBlue,
                                fontSize: isTablet ? 14 : 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            SizedBox(height: isTablet ? 20 : 16),
            
            // Admin Actions
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
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
              child: OutlinedButton.icon(
                onPressed: () => _showResetConfirmation(context, provider),
                icon: Icon(Icons.restore_rounded, size: isTablet ? 20 : 18),
                label: Text(
                  'Reset to Default Sites',
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: isTablet ? 16 : 12),
                  minimumSize: Size(double.infinity, isTablet ? 56 : 48),
                ),
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteCard(JobSite site, JobSitesBrowseProvider provider, {required bool isActive, required bool isSmallScreen}) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showSiteDetails(site, isSmallScreen),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Site Logo/Icon
                  Container(
                    width: isSmallScreen ? 50 : 60,
                    height: isSmallScreen ? 50 : 60,
                    decoration: BoxDecoration(
                      color: site.category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildSiteLogo(site, size: isSmallScreen ? 25 : 30),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  
                  // Site Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                site.name,
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 15 : 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!site.isActive || site.isDeleted)
                              _buildStatusChip(site, isSmallScreen: isSmallScreen),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          site.url,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: _primaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8, 
                            vertical: isSmallScreen ? 2 : 2
                          ),
                          decoration: BoxDecoration(
                            color: site.category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            site.category.displayName,
                            style: TextStyle(
                              color: site.category.color,
                              fontSize: isSmallScreen ? 9 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isSmallScreen ? 8 : 12),
              
              // Description
              Text(
                site.description,
                style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Features
              if (site.features.isNotEmpty) ...[
                SizedBox(height: isSmallScreen ? 8 : 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: site.features.take(3).map((feature) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: site.category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: site.category.color,
                          fontSize: isSmallScreen ? 10 : 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (site.features.length > 3)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '+${site.features.length - 3} more',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              
              SizedBox(height: isSmallScreen ? 8 : 12),
              
              // Stats Row
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_rounded, size: isSmallScreen ? 14 : 16, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        '${_formatNumber(site.clickCount)} clicks',
                        style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: isSmallScreen ? 14 : 16, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        _formatTimeAgo(site.updatedAt),
                        style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              
              Divider(height: isSmallScreen ? 16 : 20),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddEditSiteDialog(context, site: site),
                      icon: Icon(Icons.edit_rounded, size: isSmallScreen ? 16 : 18),
                      label: Text(
                        'Edit',
                        style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryBlue,
                        side: BorderSide(color: _primaryBlue),
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: isActive
                        ? OutlinedButton.icon(
                            onPressed: () => _toggleSiteStatus(site, provider),
                            icon: Icon(Icons.block_rounded, size: isSmallScreen ? 16 : 18),
                            label: Text(
                              'Deactivate',
                              style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: BorderSide(color: Colors.orange),
                              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _restoreSite(site, provider),
                            icon: Icon(Icons.restore_rounded, size: isSmallScreen ? 16 : 18),
                            label: Text(
                              'Restore',
                              style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: BorderSide(color: Colors.green),
                              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              
              if (!isActive && !site.isDeleted) ...[
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _permanentDelete(site, provider),
                    icon: Icon(Icons.delete_forever_rounded, size: isSmallScreen ? 16 : 18),
                    label: Text(
                      'Permanently Delete',
                      style: TextStyle(fontSize: isSmallScreen ? 11 : 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build site logo
  Widget _buildSiteLogo(JobSite site, {required double size}) {
    // If there's a logoUrl (asset path), use it
    if (site.logoUrl != null && site.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          site.logoUrl!,
          width: size * 2,
          height: size * 2,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image fails to load
            return Icon(
              site.category.icon,
              color: site.category.color,
              size: size,
            );
          },
        ),
      );
    }
    
    // If there's base64 logo, use it
    if (site.logoBase64 != null && site.logoBase64!.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(site.logoBase64!),
            width: size * 2,
            height: size * 2,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                site.category.icon,
                color: site.category.color,
                size: size,
              );
            },
          ),
        );
      } catch (e) {
        print('Error decoding base64 logo: $e');
      }
    }
    
    // Default fallback to icon
    return Icon(
      site.category.icon,
      color: site.category.color,
      size: size,
    );
  }

  Widget _buildStatusChip(JobSite site, {required bool isSmallScreen}) {
    Color color;
    String text;
    IconData icon;

    if (site.isDeleted) {
      color = Colors.red;
      text = 'Deleted';
      icon = Icons.delete_rounded;
    } else if (!site.isActive) {
      color = Colors.orange;
      text = 'Inactive';
      icon = Icons.block_rounded;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 10 : 12, color: color),
          SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isSmallScreen ? 9 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

  void _showSiteDetails(JobSite site, bool isSmallScreen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
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
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Header with Logo
                Row(
                  children: [
                    Container(
                      width: isSmallScreen ? 50 : 60,
                      height: isSmallScreen ? 50 : 60,
                      decoration: BoxDecoration(
                        color: site.category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildSiteLogo(site, size: isSmallScreen ? 25 : 30),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.name,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            site.category.displayName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: site.category.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Quick Stats
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailStatItem(Icons.visibility_rounded, 'Clicks', _formatNumber(site.clickCount), isSmallScreen: isSmallScreen),
                      _buildDetailStatItem(Icons.access_time_rounded, 'Added', _formatTimeAgo(site.createdAt), isSmallScreen: isSmallScreen),
                      _buildDetailStatItem(Icons.update_rounded, 'Updated', _formatTimeAgo(site.updatedAt), isSmallScreen: isSmallScreen),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Details
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailSection('Description', site.description, isSmallScreen: isSmallScreen),
                      _buildDetailSection('URL', site.url, isLink: true, isSmallScreen: isSmallScreen),
                      
                      if (site.features.isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Text(
                          'Features',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: site.features.map((feature) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 10 : 12, 
                                vertical: isSmallScreen ? 4 : 6
                              ),
                              decoration: BoxDecoration(
                                color: site.category.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                feature,
                                style: TextStyle(
                                  color: site.category.color,
                                  fontSize: isSmallScreen ? 12 : 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      
                      // Status Information
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Status', site.isDeleted ? 'Deleted' : site.isActive ? 'Active' : 'Inactive', isSmallScreen: isSmallScreen),
                            _buildInfoRow('Created', DateFormat('MMM d, yyyy').format(site.createdAt), isSmallScreen: isSmallScreen),
                            _buildInfoRow('Last Updated', DateFormat('MMM d, yyyy').format(site.updatedAt), isSmallScreen: isSmallScreen),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailStatItem(IconData icon, String label, String value, {required bool isSmallScreen}) {
    return Column(
      children: [
        Icon(icon, color: _primaryBlue, size: isSmallScreen ? 18 : 20),
        SizedBox(height: isSmallScreen ? 2 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, String content, {bool isLink = false, required bool isSmallScreen}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          isLink
              ? InkWell(
                  onTap: () => _launchUrl(content),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      color: _primaryBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  content,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required bool isSmallScreen}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: isSmallScreen ? 90 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: isSmallScreen ? 12 : 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditSiteDialog(BuildContext context, {JobSite? site}) async {
    final isEditing = site != null;
    final formKey = GlobalKey<FormState>();
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width >= 600;
    
    final nameController = TextEditingController(text: site?.name ?? '');
    final urlController = TextEditingController(text: site?.url ?? '');
    final descriptionController = TextEditingController(text: site?.description ?? '');
    JobSiteCategory selectedCategory = site?.category ?? JobSiteCategory.general;
    List<String> features = List.from(site?.features ?? []);
    String? logoBase64 = site?.logoBase64;
    String? logoUrl = site?.logoUrl;
    
    final featureController = TextEditingController();
    final ImagePicker _picker = ImagePicker();

    Future<void> _pickImage() async {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 200,
          maxHeight: 200,
          imageQuality: 80,
        );
        
        if (image != null) {
          final bytes = await image.readAsBytes();
          setState(() {
            logoBase64 = base64Encode(bytes);
            logoUrl = null; // Clear logoUrl if we're uploading a new image
          });
        }
      } catch (e) {
        print('Error picking image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Job Site' : 'Add Job Site'),
            content: Container(
              width: screenSize.width * (isTablet ? 0.7 : 0.9),
              constraints: BoxConstraints(
                maxHeight: screenSize.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo Upload Section
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: selectedCategory.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selectedCategory.color,
                                  width: 2,
                                ),
                              ),
                              child: _buildLogoPreview(logoBase64, logoUrl, selectedCategory, size: 50),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: Icon(Icons.image_rounded, size: 16),
                                  label: Text('Upload Logo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    textStyle: TextStyle(fontSize: 12),
                                  ),
                                ),
                                if (logoBase64 != null || logoUrl != null) ...[
                                  SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        logoBase64 = null;
                                        logoUrl = null;
                                      });
                                    },
                                    icon: Icon(Icons.close_rounded, color: Colors.red),
                                    iconSize: 20,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Site Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business_rounded, color: _primaryBlue),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter site name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      TextFormField(
                        controller: urlController,
                        decoration: InputDecoration(
                          labelText: 'URL *',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., https://www.glassdoor.com',
                          prefixIcon: Icon(Icons.link_rounded, color: _primaryBlue),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter URL';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_rounded, color: _primaryBlue),
                        ),
                        maxLines: isSmallScreen ? 2 : 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      DropdownButtonFormField<JobSiteCategory>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_rounded, color: _primaryBlue),
                        ),
                        items: JobSiteCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(category.icon, size: 18, color: category.color),
                                SizedBox(width: 8),
                                Text(category.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      // Features Section
                      Text(
                        'Features',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      
                      // Feature input row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: featureController,
                              decoration: InputDecoration(
                                hintText: 'Enter a feature',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 10 : 12, 
                                  vertical: isSmallScreen ? 6 : 8
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (featureController.text.isNotEmpty) {
                                setState(() {
                                  features.add(featureController.text);
                                  featureController.clear();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 8 : 12
                              ),
                            ),
                            child: Icon(Icons.add_rounded, size: isSmallScreen ? 18 : 20),
                          ),
                        ],
                      ),
                      
                      // Features list
                      if (features.isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Container(
                          constraints: BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: features.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 6 : 8, 
                                  vertical: isSmallScreen ? 2 : 4
                                ),
                                decoration: BoxDecoration(
                                  color: selectedCategory.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: isSmallScreen ? 14 : 16,
                                      color: selectedCategory.color,
                                    ),
                                    SizedBox(width: isSmallScreen ? 6 : 8),
                                    Expanded(
                                      child: Text(
                                        features[index],
                                        style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          features.removeAt(index);
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: isSmallScreen ? 14 : 16,
                                        color: Colors.red,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No features added yet',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final provider = Provider.of<JobSitesBrowseProvider>(context, listen: false);
                    
                    final newSite = JobSite(
                      id: site?.id,
                      name: nameController.text,
                      url: urlController.text,
                      description: descriptionController.text,
                      category: selectedCategory,
                      logoBase64: logoBase64,
                      logoUrl: logoUrl,
                      features: features,
                      isActive: site?.isActive ?? true,
                      isDeleted: site?.isDeleted ?? false,
                      visitCount: site?.visitCount ?? 0,
                      clickCount: site?.clickCount ?? 0,
                      createdAt: site?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    final success = await provider.saveJobSite(newSite);
                    
                    if (success) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Site updated successfully' : 'Site added successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper method to build logo preview
  Widget _buildLogoPreview(String? base64, String? url, JobSiteCategory category, {required double size}) {
    if (base64 != null && base64.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(base64),
            width: size * 2,
            height: size * 2,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                category.icon,
                color: category.color,
                size: size,
              );
            },
          ),
        );
      } catch (e) {
        print('Error decoding base64: $e');
      }
    }
    
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          url,
          width: size * 2,
          height: size * 2,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              category.icon,
              color: category.color,
              size: size,
            );
          },
        ),
      );
    }
    
    return Icon(
      category.icon,
      color: category.color,
      size: size,
    );
  }

  Future<void> _toggleSiteStatus(JobSite site, JobSitesBrowseProvider provider) async {
    final updatedSite = JobSite(
      id: site.id,
      name: site.name,
      url: site.url,
      description: site.description,
      category: site.category,
      logoBase64: site.logoBase64,
      logoUrl: site.logoUrl,
      features: site.features,
      isActive: false,
      isDeleted: false,
      visitCount: site.visitCount,
      clickCount: site.clickCount,
      createdAt: site.createdAt,
      updatedAt: DateTime.now(),
    );

    final success = await provider.saveJobSite(updatedSite);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${site.name} deactivated'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _restoreSite(JobSite site, JobSitesBrowseProvider provider) async {
    final updatedSite = JobSite(
      id: site.id,
      name: site.name,
      url: site.url,
      description: site.description,
      category: site.category,
      logoBase64: site.logoBase64,
      logoUrl: site.logoUrl,
      features: site.features,
      isActive: true,
      isDeleted: false,
      visitCount: site.visitCount,
      clickCount: site.clickCount,
      createdAt: site.createdAt,
      updatedAt: DateTime.now(),
    );

    final success = await provider.saveJobSite(updatedSite);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${site.name} restored'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _permanentDelete(JobSite site, JobSitesBrowseProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanent Delete'),
        content: Text('Are you sure you want to permanently delete "${site.name}"? This action cannot be undone.'),
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

    if (confirm == true) {
      final success = await provider.permanentDeleteJobSite(site.id!);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${site.name} permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showResetConfirmation(BuildContext context, JobSitesBrowseProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset to Default'),
        content: Text('This will reset all job sites to the default list. Any custom sites will be lost. Continue?'),
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
            child: Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.resetToDefault();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset to default sites'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30}mo ago';
    } else if (difference.inDays > 0) {
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